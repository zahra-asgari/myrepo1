clear all;
addpath('utils');
sim_folder = 'Mat_files_solutions/';
sim_id = 'highD_small';

export_style = 'Polimi-ppt';
%export_style = 'ieee_large_lines';

mat_files = dir([sim_folder sim_id '/bh_analysis/*.mat']);
num_files = numel(mat_files);

figure_handle = figure('units','normalized','outerposition',[0 0 1 1]);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Mean Backhaul Distance');
end

%line_options = {''; '--'; ':'};
%color_options= {'k'; 'k'; 'k'};
%color_options = distinguishable_colors(numel(mat_files));

%display_names = {'maxminMCS'; 'maxminrate';'sumMCS';'sumrate'};
%display_names = {'maxminMCS'; 'minmaxt';'sumairtime';'sumall';'sumextra';'sumfree';'sumMCS'};
display_names = cell(num_files,1);
for mf = 1:numel(mat_files)
    display_names{mf} = mat_files(mf).name;
    display_names{mf} = split(display_names{mf},'_');
    display_names{mf} = display_names{mf}{2};
    display_names{mf} = display_names{mf}(1:end-4);
    %load the file
    load([mat_files(mf).folder '/' mat_files(mf).name]);
    
    %installed IAB Nodes plot
    
    %distance plot
    figure(figure_handle);
    plot(str2num(char(ticks_labels)), avg_bh_length,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=10)
        xlim([str2double(ticks_labels{find(solved_count>min(solved_count),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim('auto')
    end
    ylim('auto')

    
end
