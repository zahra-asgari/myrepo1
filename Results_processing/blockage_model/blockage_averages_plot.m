clearvars;
addpath('utils');
sim_folder = 'Mat_files_solutions/';
sim_id = 'budget';

export_style = 'Polimi-ppt';
%export_style = 'ieee_large_lines';

mat_files = dir([sim_folder sim_id '/mat_results/*.mat']);

monitor_corners = get(0,'MonitorPositions');

monitor_corners = monitormanager(monitor_corners);

avg_installed_devices = figure();
avg_installed_devices.Position(1:2) = [monitor_corners(1) monitor_corners(4) - avg_installed_devices.Position(4)/2];
%movegui([monitor_corners(1) monitor_corners(4)]);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:4), 'ieee')
title('Mean installed devices');
end

avg_used_budget_fig = figure();
avg_used_budget_fig.Position(1:2) = [(monitor_corners(3) + monitor_corners(1))/2 - avg_used_budget_fig.Position(3)/2 monitor_corners(4) - avg_used_budget_fig.Position(4)/2];
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:4), 'ieee')
title('Mean Cost');
end

avg_tp_rate_fig = figure();
avg_tp_rate_fig.Position(1:2) = [monitor_corners(3) - avg_tp_rate_fig.Position(3)/2 monitor_corners(4) - avg_tp_rate_fig.Position(4)/2];
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:4), 'ieee')
title('Mean and Maximum available rates');
end


avg_old_metrics_fig = figure();
avg_old_metrics_fig.Position(1:2) = [monitor_corners(1) monitor_corners(2)];
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:4), 'ieee')
title('Mean Access Distance and Angular Separation');
end

avg_users_fig = figure();
avg_users_fig.Position(1:2) = [(monitor_corners(3) + monitor_corners(1))/2 - avg_users_fig.Position(3)/2 monitor_corners(2)];
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:4), 'ieee')
title('Average type of users');
end

avg_occupation_fig = figure();
avg_occupation_fig.Position(1:2) = [monitor_corners(3) - avg_occupation_fig.Position(3)/2 monitor_corners(2)];
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:4), 'ieee')
title('Average device occupation time');
end

%line_options = {''; '--'; ':'};
%color_options= {'k'; 'k'; 'k'};
color_options = distinguishable_colors(numel(mat_files));

display_names = {'max throughput'; 'avg throughput'};

for mf = 1:numel(mat_files)
    %load the file
    load([mat_files(mf).folder '/' mat_files(mf).name]);
    
    %installed devices plot
    figure(avg_installed_devices);
    plot(str2num(char(ticks_labels)), avg_iab, 'Color', color_options(mf,:), 'LineStyle', '-', 'DisplayName', [display_names{mf} ' - IAB Nodes']);
    plot(str2num(char(ticks_labels)), avg_ris, 'Color', color_options(mf,:), 'LineStyle', ':', 'DisplayName', [display_names{mf} ' - RIS']);   
    sdf(export_style);
    if (min(solved_count)<=10)
        xlim([str2double(ticks_labels{find(solved_count>0 & solved_count<=10, 1, 'last')}),str2double(ticks_labels{end})])
    else
        xlim auto
    end
    ylim auto

    
    %cost plot
    figure(avg_used_budget_fig);
    plot(str2num(char(ticks_labels)), avg_cost, 'Color', color_options(mf,:), 'LineStyle', '-', 'DisplayName', display_names{mf});
    sdf(export_style);
    if (min(solved_count)<=10)
        xlim([str2double(ticks_labels{find(solved_count>0 & solved_count<=10, 1, 'last')}),str2double(ticks_labels{end})])
    else
        xlim auto
    end
    ylim auto
    
    
    %tp throughput plot
    figure(avg_tp_rate_fig);
    plot(str2num(char(ticks_labels)), avg_tp_rate, 'Color', color_options(mf,:), 'LineStyle', '-', 'DisplayName', [display_names{mf} ' - long-term']);
    plot(str2num(char(ticks_labels)), avg_tp_full + avg_tp_rate, 'Color', color_options(mf,:), 'LineStyle', ':', 'DisplayName', [display_names{mf} ' - instantaneous']);
    sdf(export_style);
    if (min(solved_count)<=10)
        xlim([str2double(ticks_labels{find(solved_count>0 & solved_count<=10, 1, 'last')}),str2double(ticks_labels{end})])
    else
        xlim auto
    end
    ylim auto
    

    %distance and angle plot
    figure(avg_old_metrics_fig);
    plot(str2num(char(ticks_labels)), avg_acc_dist, 'Color', color_options(mf,:), 'LineStyle', '-', 'DisplayName', [display_names{mf} ' - access link length']);
    plot(str2num(char(ticks_labels)), avg_ang_div, 'Color', color_options(mf,:), 'LineStyle', ':', 'DisplayName', [display_names{mf} ' - angular separation (for RIS users)']);
    sdf(export_style);
    if (min(solved_count)<=10)
        xlim([str2double(ticks_labels{find(solved_count>0 & solved_count<=10, 1, 'last')}),str2double(ticks_labels{end})])
    else
        xlim auto
    end
    ylim auto
    
    %users plot
    figure(avg_users_fig);
    plot(str2num(char(ticks_labels)), avg_dir_users, 'Color', color_options(mf,:), 'LineStyle', '-', 'DisplayName', [display_names{mf} ' - Direct link users']);
    plot(str2num(char(ticks_labels)), avg_ris_users, 'Color', color_options(mf,:), 'LineStyle', ':', 'DisplayName', [display_names{mf} ' - SRC users']);
    sdf(export_style);
    if (min(solved_count)<=10)
        xlim([str2double(ticks_labels{find(solved_count>0 & solved_count<=10, 1, 'last')}),str2double(ticks_labels{end})])
    else
        xlim auto
    end
    ylim auto
    
    %occupation plot
    figure(avg_occupation_fig);
    plot(str2num(char(ticks_labels)), avg_don_time, 'Color', color_options(mf,:), 'LineStyle', '-', 'DisplayName', [display_names{mf} ' - Donor Occupation']);
    plot(str2num(char(ticks_labels)), avg_iab_time, 'Color', color_options(mf,:), 'LineStyle', ':', 'DisplayName', [display_names{mf} ' - IAB Node occupation']);
    plot(str2num(char(ticks_labels)), avg_ris_time, 'Color', color_options(mf,:), 'LineStyle', '-.', 'DisplayName', [display_names{mf} ' - RIS occupation']);
    sdf(export_style);
    if (min(solved_count)<=10)
        xlim([str2double(ticks_labels{find(solved_count>0 & solved_count<=10, 1, 'last')}),str2double(ticks_labels{end})])
    else
        xlim auto
    end
    ylim auto
    
    
    
    
end

closeplots;

function closeplots
    answer = questdlg('Close all figures?','Plot Control', 'OK','Cancel','OK');
    switch answer
        case 'OK'
            close all;
        case 'Cancel'
            %do nothing

    end
end

function [pos] = monitormanager(pos)
    answer = questdlg('Do you have multiple monitors?','Multiple Monitor Check', 'Yes','No','Yes');
    switch answer
        case 'Yes'
            close(gcf);
            pos = monitorposition(pos);
        case 'No'
            %do nothing

    end
end

function [pos] = monitorposition(pos)
    %answer = questdlg(['Where is the monitor you want to show the plots with respect to the main monitor?'],'Monitor Position Check', 'Top','Bottom','Left','Right');
    list = {'Top','Bottom','Left','Right'};
    [index,tf] = listdlg('PromptString', 'Plot monitor position:', 'ListString',list,'SelectionMode','single','ListSize',[160 80]);
    if tf
        switch index 
            case 1
                pos(2) = pos(4)/2;
            case 2
                pos(4) = pos(4)/2;
            case 3
                pos(3) = pos(3)/2;
            case 4
                pos(1) = pos(3)/2;
        end
    else
        uiwait(msgbox("No option selected!",'Error','Error'));
        monitormanager(pos);
    end
    
end
