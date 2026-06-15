%%%%%%%%%%%%%%%%%%%%%%%%%  -----------    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ANOVA for global metrics
%%%%%%%%%%%%%%%%%%%%%%%%%  -----------    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
clc;
close all;
basePath =  'xxx\Gretna-Network\NetworkEfficiency';
% basePath =  'xxx\Gretna-Network\SmallWorld';
group1Path = fullfile(basePath, 'Group1-ASD-LL');
group2Path = fullfile(basePath, 'Group2-ASD-HL'); 
group3Path = fullfile(basePath, 'Group3-TD');
load( 'xxx\cova_LL-HL-TD.mat'); 
% this mat includes ‘cova’ and ‘valid_idx’
group1Files = dir(fullfile(group1Path, '*.mat'));
group2Files = dir(fullfile(group2Path, '*.mat'));
group3Files = dir(fullfile(group3Path, '*.mat'));
fileName = group1Files(1).name;
dataGroup1 = load(fullfile(group1Path, fileName));
dataGroup2 = load(fullfile(group2Path, fileName));
dataGroup3 = load(fullfile(group3Path, fileName));
varNames = fieldnames(dataGroup1);
temp_var = varNames{1};
num_g1 = size(dataGroup1.(temp_var), 1);
num_g2 = size(dataGroup2.(temp_var), 1);
num_g3 = size(dataGroup3.(temp_var), 1);

valid_idx_for_g1 = logical(valid_idx(1:num_g1));
valid_idx_for_g2 = logical(valid_idx(num_g1+1 : num_g1+num_g2));
valid_idx_for_g3 = logical(valid_idx(num_g1+num_g2+1 : end));

cova = cova(logical(valid_idx), :);
allsub = [];

results = table('Size', [length(varNames), 3], ...
    'VariableTypes', {'string', 'double', 'double'}, ...
    'VariableNames', {'Variable', 'F_stat', 'ANOVA_p'});

asd_LL_color = [0.8, 0.8, 0.2];
asd_HL_color =[0.8, 0.2, 0.2];
td_color =[0.2, 0.5, 0.8];
group_plot_names = {'ASD-LL', 'ASD-HL', 'TD'};

for varIdx = 1:length(varNames)
    varName = varNames{varIdx};
    group1Data = dataGroup1.(varName);
    group2Data = dataGroup2.(varName);
    group3Data = dataGroup3.(varName);
    
    group1Data_filtered = group1Data(valid_idx_for_g1, : , :);
    group2Data_filtered = group2Data(valid_idx_for_g2, : , :);
    group3Data_filtered = group3Data(valid_idx_for_g3, : , :);
    
    % ===== Process data based on variable dimensions =====
    % Check if the variable is 2D (e.g., Subjects x 1)
    if ndims(group1Data_filtered) == 2 && size(group1Data_filtered, 2) == 1
        allData = [group1Data_filtered; group2Data_filtered; group3Data_filtered];
        groupLabels = [ones(size(group1Data_filtered)); 2*ones(size(group2Data_filtered)); 3*ones(size(group3Data_filtered))];
        [p, tbl, ~] = anova1(allData, groupLabels, 'off');
        
        F_stat = tbl{2, 5};
        p_value = tbl{2, 6};
        df1 = tbl{2, 3};
        df2 = tbl{3, 3};
        
        results.Variable(varIdx) = string(varName);
        results.F_stat(varIdx) = F_stat;
        results.ANOVA_p(varIdx) = p_value;
        
        % violin plot
        figure('Name', sprintf('Violin Plot: %s', varName), 'Color', 'w');
        hold on;
        all_data_v = [group1Data_filtered; group2Data_filtered; group3Data_filtered];
        group_labels_v = [repmat(group_plot_names(1), numel(group1Data_filtered), 1);
                        repmat(group_plot_names(2), numel(group2Data_filtered), 1);
                        repmat(group_plot_names(3), numel(group3Data_filtered), 1)];
        violin_colors = [asd_LL_color; asd_HL_color; td_color];
        vs = violinplot(all_data_v, group_labels_v, ...
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
        if p_value < 0.001
            p_str_v = '< 0.001';
        else
            p_str_v = sprintf('%.3f', p_value);
        end
        
        fontWeight = 'normal';
        if p_value < 0.05
            fontWeight = 'bold';
        end
        
        text_str_v = sprintf('AUC: $$F(%d, %d) = %.2f, p = %s$$', df1, df2, F_stat, p_str_v);
        y_lims = ylim;
        y_range = y_lims(2) - y_lims(1);
        text_y_pos = y_lims(2) + 0.05 * y_range; 
        text(2, text_y_pos, text_str_v, 'FontSize', 12, 'HorizontalAlignment', 'center', 'Interpreter', 'latex', 'FontWeight', fontWeight);
        ylim([y_lims(1), text_y_pos + 0.05 * y_range]);
        ylabel(varName, 'Interpreter', 'none','FontSize', 16, 'FontName', 'Arial','Fontweight','Bold');
        ax_v = gca;
        ax_v.TickLabelInterpreter = 'none';
        set(ax_v, 'LineWidth', 1.5, 'FontName', 'Arial', 'FontSize', 14);
        grid off;
        box off;
        hold off;

        % If the variable is 3D data (subjects x 1 x thresholds) 
    elseif ndims(group1Data_filtered) == 3 && size(group1Data_filtered, 2) == 1
        % skip
        results.Variable(varIdx) = string(varName);
        results.F_stat(varIdx) = NaN;
        results.ANOVA_p(varIdx) = NaN;
        figure;
        hold on;
        
        thresholds = 3:1:10; % fiber numbers
        meanG1 = squeeze(mean(group1Data_filtered, 1, 'omitnan'));
        stdG1 = squeeze(std(group1Data_filtered, 0, 1, 'omitnan'));
        
        meanG2 = squeeze(mean(group2Data_filtered, 1, 'omitnan'));
        stdG2 = squeeze(std(group2Data_filtered, 0, 1, 'omitnan'));
        
        meanG3 = squeeze(mean(group3Data_filtered, 1, 'omitnan'));
        stdG3 = squeeze(std(group3Data_filtered, 0, 1, 'omitnan'));
        
        errorbar(thresholds, meanG1, stdG1, ':^', 'Color', asd_LL_color, 'LineWidth', 2.5, 'MarkerSize', 8,'DisplayName', 'ASD-LL'); 
        errorbar(thresholds, meanG2, stdG2, '--s', 'Color', asd_HL_color, 'LineWidth', 2.5, 'MarkerSize', 8, 'DisplayName', 'ASD-HL');
        errorbar(thresholds, meanG3, stdG3, '-o', 'Color', td_color, 'LineWidth', 2.5, 'MarkerSize', 8, 'DisplayName', 'TD'); 
        
        ax = gca;
        ax.FontSize = 14;
        ax.FontName = 'Arial';
        ax.LineWidth = 1.5;
        xlabel('Thresholds', 'FontSize', 16, 'FontName', 'Arial','Fontweight','Bold');
        ylabel(varName, 'Interpreter', 'none', 'FontSize', 16, 'FontName', 'Arial','Fontweight','Bold');
        legend('show');
        legend('boxoff');
        grid off;
        box off;
        hold off;
        
    else
        disp(['Warning: Skipping variable ''', varName, ''' due to unsupported dimension.']);
    end
end

disp(' ');
disp(results);
