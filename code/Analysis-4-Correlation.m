%%%%%%%%%%%%%%%%%%%%%%%%%  -----------    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Brain-Behavior correlations
%%%%%%%%%%%%%%%%%%%%%%%%%  -----------    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
clc;
close all;
datapath = 'xxx';
behavioral_file = 'Brain-Behavior.csv';
T_behav = readtable(fullfile(datapath, behavioral_file), 'TreatAsMissing', 'NULL');
control_vars_names = {'AgeM', 'SexN'};
network_vars_names = {'Eg'};
T_net = T_behav(:, network_vars_names);
control_matrix_all = T_behav{:, control_vars_names};
idx_all = T_behav.GroupIdx; % 1= ASD-LL; 2= ASD-HL
all_behav_vars_names = T_behav.Properties.VariableNames;

interest_behav_names = {'ABC'};
interest_brain_names = T_net.Properties.VariableNames;
groups_info = {
    {1, 'ASD-LL',  [0.8, 0.8, 0.2]}, ...
    {2, 'ASD-HL', [0.95, 0.5, 0.5]}
    };
all_color = [0 0 0]; % Black, used for plotting the overall regression line

for i = 1:length(interest_behav_names)
    current_behav_name = interest_behav_names{i};
    current_behav_var = T_behav.(current_behav_name);
    
    for j = 1:length(interest_brain_names)
        current_brain_name = interest_brain_names{j};
        current_brain_var = T_net.(current_brain_name);
        % figure('Color', 'w', 'Name', sprintf('Partial Corr: %s vs %s', current_behav_name, current_brain_name));
        screen_size = get(groot, 'ScreenSize');
        screen_width = screen_size(3);
        screen_height = screen_size(4);
        fig_width = screen_width;
        fig_height = screen_height / 3;
        fig_left = 1;
        fig_bottom = (screen_height - fig_height) / 2;
        figure('Color', 'w', ...
            'Name', sprintf('Partial Corr: %s vs %s', current_behav_name, current_brain_name), ...
            'Position', [fig_left, fig_bottom, fig_width, fig_height]);
        
        % =========================================================
        % 1. plot the subplot for each group (2)
        % =========================================================
        for k = 1:length(groups_info)
            subplot(1, 3, k);
            ax = gca;
            hold on;
            
            group_idx_val = groups_info{k}{1};
            group_name = groups_info{k}{2};
            group_color = groups_info{k}{3};
            
            group_logical_idx = idx_all == group_idx_val;
            
            behav_group = current_behav_var(group_logical_idx);
            brain_group = current_brain_var(group_logical_idx);
            controls_group = control_matrix_all(group_logical_idx, :);
            
            data_group = [behav_group, brain_group, controls_group];
            complete_cases_group = ~any(isnan(data_group), 2);
            
            behav_clean_group = behav_group(complete_cases_group);
            brain_clean_group = brain_group(complete_cases_group);
            controls_clean_group = controls_group(complete_cases_group, :);
            
            fprintf('  Group: %s (n=%d)\n', group_name, length(behav_clean_group));
            [r, p] = partialcorr(behav_clean_group, brain_clean_group, controls_clean_group, 'Rows', 'complete');
            tbl_behav = table(controls_clean_group(:,1), controls_clean_group(:,2), behav_clean_group, 'VariableNames', {'C1', 'C2', 'Behav'});
            formula_behav = 'Behav ~ C1 + C2';
            lm_behav = fitlm(tbl_behav, formula_behav);
            res_behav = lm_behav.Residuals.Raw;
            tbl_brain = table(controls_clean_group(:,1), controls_clean_group(:,2), brain_clean_group, 'VariableNames', {'C1', 'C2', 'brain'});
            formula_brain = 'brain ~ C1 + C2';
            lm_brain = fitlm(tbl_brain, formula_brain);
            res_brain = lm_brain.Residuals.Raw;
            % plot parameters
            scatter(res_behav, res_brain, 80, 'filled', 'MarkerFaceColor', group_color, 'MarkerFaceAlpha', 0.8);
            mdl_res = fitlm(res_behav, res_brain);
            h_ci = plot(mdl_res);
            set(h_ci(1), 'Marker', 'none');
            set(h_ci(2), 'Color', group_color, 'LineWidth', 3);
            set(h_ci(3), 'Color', group_color, 'LineStyle', '--', 'LineWidth', 1.5);
            set(h_ci(4), 'Color', group_color, 'LineStyle', '--', 'LineWidth', 1.5);
            legend('off');
  
            if p < 0.05
                annotation_str = sprintf('\\textbf{$\\textit{r}$ = %.3f}\n\\textbf{$\\textit{p}$ = %.3f}', r, p);
                fontColor = [0.7, 0, 0];
            else
                annotation_str = sprintf('$\\textit{r}$ = %.3f\n$\\textit{p}$ = %.3f', r, p);
                
                fontColor = 'black';
            end
            
            text(ax, 0.05, 0.95, annotation_str, ...
                'VerticalAlignment', 'top', ...
                'FontSize', 12, ...
                'FontWeight', 'normal', ...
                'Color', fontColor, ...
                'Interpreter', 'latex', ...
                'Units', 'normalized');
            
            title(sprintf('%s', group_name));
            xlabel(sprintf('%s', strrep(current_behav_name, '_', ' ')), 'FontSize', 16,'Fontweight','Bold');
            ylabel(sprintf('%s', strrep(current_brain_name, '_', ' ')), 'FontSize', 16,'Fontweight','Bold');
            
            fprintf('  Partial correlation: r = %.4f, p = %.4f\n', r, p);
            
            hold off;
            box on;
            ax.LineWidth = 2;
            ax.FontSize = 14;
        end
        
        % =========================================================
        % 2. Plot the subplot for all ASD subjects combined (the 3rd subplot)
        % =========================================================
        subplot(1, 3, 3);
        ax = gca;
        hold on;
        
        data_all = [current_behav_var, current_brain_var, control_matrix_all];
        complete_cases_all = ~any(isnan(data_all), 2);
        behav_all_clean = current_behav_var(complete_cases_all);
        brain_all_clean = current_brain_var(complete_cases_all);
        controls_all_clean = control_matrix_all(complete_cases_all, :);
        
        [r_all, p_all] = partialcorr(behav_all_clean, brain_all_clean, controls_all_clean, 'Rows', 'complete');
        tbl_behav_all = table(controls_all_clean(:,1), controls_all_clean(:,2), behav_all_clean, 'VariableNames', {'C1', 'C2', 'Behav'});
        formula_behav = 'Behav ~ C1 + C2';
        lm_behav_all = fitlm(tbl_behav_all, formula_behav);
        res_behav_all = lm_behav_all.Residuals.Raw;
        tbl_brain_all = table(controls_all_clean(:,1), controls_all_clean(:,2), brain_all_clean, 'VariableNames', {'C1', 'C2', 'brain'});
        formula_brain = 'brain ~ C1 + C2';
        
        lm_brain_all = fitlm(tbl_brain_all, formula_brain);
        res_brain_all = lm_brain_all.Residuals.Raw;
        
        scatter_colors = zeros(length(res_behav_all), 3);
        complete_idx_all = idx_all(complete_cases_all);
        unique_idx = unique(complete_idx_all);
        for k_idx = 1:length(unique_idx)
            current_idx = unique_idx(k_idx);
            group_info_cell = groups_info{current_idx};
            scatter_colors(complete_idx_all == current_idx, :) = repmat(group_info_cell{3}, sum(complete_idx_all == current_idx), 1);
        end
        scatter(res_behav_all, res_brain_all, 80, scatter_colors, 'filled', 'MarkerFaceAlpha', 0.8);
        
        mdl_res_all = fitlm(res_behav_all, res_brain_all);
        h_ci_all = plot(mdl_res_all, 'Color', all_color);
        set(h_ci_all(1), 'Marker', 'none');
        set(h_ci_all(2), 'Color', all_color, 'LineWidth',3);
        set(h_ci_all(3), 'Color', all_color, 'LineStyle', '--', 'LineWidth', 1.5);
        set(h_ci_all(4), 'Color', all_color, 'LineStyle', '--', 'LineWidth', 1.5);
        
        if p_all < 0.05
            annotation_str = sprintf('\\textbf{$\\textit{r}$ = %.3f}\n\\textbf{$\\textit{p}$ = %.3f}', r_all, p_all);
            fontColor = [0.7, 0, 0];
        else
            annotation_str = sprintf('$\\textit{r}$ = %.3f\n$\\textit{p}$ = %.3f', r_all, p_all);
            fontColor = 'black';
        end
        
        text(ax, 0.05, 0.95, annotation_str, ...
            'VerticalAlignment', 'top', ...
            'FontSize', 12, ...
            'FontWeight', 'normal', ...
            'Color', fontColor, ...
            'Interpreter', 'latex', ...
            'Units', 'normalized');
        
        title('ASD Combined');
        xlabel(sprintf('%s', strrep(current_behav_name, '_', ' ')), 'FontSize', 16,'Fontweight','Bold');
        ylabel(sprintf('%s', strrep(current_brain_name, '_', ' ')), 'FontSize', 16,'Fontweight','Bold');
        fprintf('  ASD combined: r = %.4f, p = %.4f\n', r_all, p_all);
    end
    
    hold off;
    box on;
    legend('off');
    ax.LineWidth = 2;
    ax.FontSize = 14;
end