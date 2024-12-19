clearvars;
addpath('utils');
sim_folder = 'Mat_files_solutions/';
sim_id = 'new';

export_style = 'Polimi-ppt';
%export_style = 'ieee_large_lines';

mat_files = dir([sim_folder sim_id '/mat_results/*.mat']);
avg_installed_devices = figure();
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:4), 'ieee')
title('Mean installed devices');
end

color_options = distinguishable_colors(numel(mat_files));

display_names = {'max throughput'; 'avg throughput'};


for mf = 1:numel(mat_files)
    %load the file
    load([mat_files(mf).folder '/' mat_files(mf).name]);
    step = (str2double(ticks_labels{2}) - str2double(ticks_labels{1}))/2;
    no_sol = [((find(solved_count == 0, 1) - 1)/2 - step) ((find(solved_count == 0, 1, 'last') - 1)/2 + step)];

    few_sol = [((find(solved_count>0 & solved_count<=10',1) - 1)/2 - step) ((find(solved_count>0 & solved_count<=10, 1, 'last') - 1)/2 + step)];
    
    %installed devices plot
    figure(avg_installed_devices);
    plot(str2num(char(ticks_labels)), avg_iab, 'Color', color_options(mf,:), 'LineStyle', '-', 'DisplayName', [display_names{mf} ' - IAB Nodes']);
    plot(str2num(char(ticks_labels)), avg_ris, 'Color', color_options(mf,:), 'LineStyle', ':', 'DisplayName', [display_names{mf} ' - RIS']);
    
    area(no_sol, repmat(max(max(avg_iab),max(avg_ris)),[1 2]), 'FaceColor','k', 'FaceAlpha', 0.3, 'EdgeAlpha', 0, 'HandleVisibility', 'off');
    area(few_sol, repmat(max(max(avg_iab),max(avg_ris)),[1 2]), 'FaceColor',color_options(mf,:), 'FaceAlpha', 0.3, 'EdgeAlpha', 0, 'HandleVisibility', 'off');

            
           
    sdf(export_style);
    xlim([0 str2double(ticks_labels{end})])
    ylim auto
    
end