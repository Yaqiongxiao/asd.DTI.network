%%%%%%%%%%%%%%%%%%%%%%%%%  -----------    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ANOVA for Modular Interaction
%%%%%%%%%%%%%%%%%%%%%%%%%  -----------    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
clc;
close all;
basePath =  'xxx\Gretna-Network\ModularInteraction';
group1Path = fullfile(basePath, 'Group1-ASD-LL');
group2Path = fullfile(basePath, 'Group2-ASD-HL');
group3Path = fullfile(basePath, 'Group3-TD');
cova_path = 'xxx\cova_3group_LL-HL-TD.mat';
group1_data = load(fullfile(group1Path, 'ModularInteraction.mat'));
group2_data = load(fullfile(group2Path, 'ModularInteraction.mat'));
group3_data = load(fullfile(group3Path, 'ModularInteraction.mat'));
load(cova_path);
varNames = fieldnames(group1_data);
num_g1 = length(group1_data.(varNames{1}));
num_g2 = length(group2_data.(varNames{1}));
num_g3 = length(group3_data.(varNames{1}));

valid_idx_g1 = logical(valid_idx(1:num_g1));
valid_idx_g2 = logical(valid_idx(num_g1+1 : num_g1+num_g2));
valid_idx_g3 = logical(valid_idx(num_g1+num_g2+1 : end));

age = cova(:, 1);
sex = cova(:, 2);

results = table('Size', [length(varNames), 5], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'Variable', 'F_ANOVA', 'p_ANOVA', 'F_ANCOVA', 'p_ANCOVA'});

group_plot_names = {'ASD-LL', 'ASD-HL', 'TD'};
asd_LL_color = [0.8, 0.8, 0.2];
asd_HL_color = [0.8, 0.2, 0.2];
td_color =[0.2, 0.5, 0.8];
plot_colors = {asd_LL_color, asd_HL_color, td_color};

simple_field_names = cellfun(@(x) strrep(x, 'Module', ''), varNames, 'UniformOutput', false);
simple_field_names = cellfun(@(x) strrep(x, '01', 'LH'), simple_field_names, 'UniformOutput', false);
simple_field_names = cellfun(@(x) strrep(x, '02', 'RH'), simple_field_names, 'UniformOutput', false);
simple_field_names = cellfun(@(x) strrep(x, 'SumEdgeNum', 'EdgeNum'), simple_field_names, 'UniformOutput', false);
formatted_names = cellfun(@(x) strrep(x, '_', '-'), simple_field_names, 'UniformOutput', false);


for varIdx = 1:length(varNames)
    varName = varNames{varIdx};
    
    group1Data = group1_data.(varName);
    group2Data = group2_data.(varName);
    group3Data = group3_data.(varName);
    % threshod = 3
    group1Data_filtered = squeeze(group1Data(valid_idx_g1, : , 1));
    group2Data_filtered = squeeze(group2Data(valid_idx_g2, : , 1));
    group3Data_filtered = squeeze(group3Data(valid_idx_g3, : , 1));
    
    if isvector(group1Data_filtered) && isvector(group2Data_filtered) && isvector(group3Data_filtered)
        
        allData = [group1Data_filtered; group2Data_filtered; group3Data_filtered];
        groupLabels = [ones(size(group1Data_filtered)); 2*ones(size(group2Data_filtered)); 3*ones(size(group3Data_filtered))];
        
        [p_anova, tbl_anova, stats] = anova1(allData, groupLabels, 'off');
        F_stat_anova = tbl_anova{2, 5};
        p_value_anova = tbl_anova{2, 6};
        
        results.Variable(varIdx) = string(varName);
        results.F_ANOVA(varIdx) = F_stat_anova;
        results.p_ANOVA(varIdx) = p_value_anova;
        
        try
            [~, tbl_ancova, ~] = anovan(allData, {groupLabels, age, sex}, 'model', 'main', 'continuous', [2 3], 'varnames', {'Group', 'Age', 'Sex'}, 'display', 'off');
            F_stat_ancova = tbl_ancova{2, 6};
            p_value_ancova = tbl_ancova{2, 7};
        catch
            F_stat_ancova = NaN;
            p_value_ancova = NaN;
        end
        results.F_ANCOVA(varIdx) = F_stat_ancova;
        results.p_ANCOVA(varIdx) = p_value_ancova;
        
        % violin plot
        figure('Name', sprintf('Violin Plot: %s', varName), 'Color', 'w');
        hold on;
        
        all_data = [group1Data_filtered; group2Data_filtered; group3Data_filtered];
        group_labels = [repmat(group_plot_names(1), numel(group1Data_filtered), 1);
            repmat(group_plot_names(2), numel(group2Data_filtered), 1);
            repmat(group_plot_names(3), numel(group3Data_filtered), 1)];
        
        violin_colors = [asd_LL_color; asd_HL_color; td_color];
        vs = violinplot(all_data, group_labels, ...
            'GroupOrder', group_plot_names, ...
            'ViolinColor', violin_colors, ...
            'ViolinAlpha', 0.4, ...
            'ShowData', true, ...
            'ShowMean', true, ...
            'EdgeColor', [0.1 0.1 0.1], ...
            'BoxColor', [0.1 0.1 0.1]);
        new_marker_size = 50;
        new_mean_linewidth = 1.5;
        
        for i = 1:length(vs)
            
            vs(i).ScatterPlot.SizeData = new_marker_size;
            vs(i).MeanPlot.LineWidth = new_mean_linewidth;
        end
        
        df1 = tbl_anova{2, 3};
        df2 = tbl_anova{3, 3};
        if p_value_anova < 0.001
            p_str = '< 0.001';
        else
            p_str = sprintf('%.3f', p_value_anova);
        end
        
        fontWeight = 'normal';
        if p_value_anova < 0.05
            fontWeight = 'bold';
        end
        
        text_str = sprintf('$$F(%d, %d) = %.2f, p = %s$$', df1, df2, F_stat_anova, p_str);
        
        y_lims = ylim;
        y_range = y_lims(2) - y_lims(1);
        text_y_pos = y_lims(2) + 0.05 * y_range;
        text(2, text_y_pos, text_str, 'FontSize', 12, 'HorizontalAlignment', 'center', 'Interpreter', 'latex', 'FontWeight', fontWeight);
        ylim([y_lims(1), text_y_pos + 0.05 * y_range]);
        ylabel(formatted_names{varIdx}, 'Interpreter', 'none','FontSize', 16, 'FontName', 'Arial','Fontweight','Bold');
        set(gca, 'LineWidth', 1.5, 'FontName', 'Arial', 'FontSize', 14);
        grid off;
        box off;
        hold off;
        
    end
end
