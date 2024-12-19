clear all;
addpath('utils');
sim_folder = 'Mat_files_solutions/';
sim_id = 'journal100_vs_report20';
tot_inst = [20;20;20;20];
test_folder = '';
%test_folder = 'free_space_all/';
%test_folder = 'free_space_vs_urban/';
export_style = 'ieee';
%export_style = 'ieee_large_lines';
plot_lim = 0.5; %percentage of solved instances
mat_files = dir([sim_folder sim_id '/mat_results/' test_folder '*.mat']);
num_files = numel(mat_files);
% figure_handle = figure('units','normalized','outerposition',[0 0 1 1]);
figure
avg_installed_dev_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('Mean installed devices');
xlabel('Budget');
end
figure
avg_used_budget_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('Mean Cost');
xlabel('Budget');
end
figure
avg_dl_tp_rates_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('DL TP rates, Mbps');
xlabel('Budget');
end
figure
avg_ul_tp_rates_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('UL TP rates, Mbps');
xlabel('Budget');
end
figure
avg_link_length_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('Mean link distance, m');
xlabel('Budget');
end
figure
avg_ang_sep_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('Mean Angular Separation, degrees');
xlabel('Budget');
end
figure
avg_users_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('Users by connection type');
xlabel('Budget');
end
figure
avg_device_occupation_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('Device busy ratio');
xlabel('Budget');
end
figure
avg_dl_sd_contrib_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('DL extra rate given by SD, ratio');
xlabel('Budget');
end
figure
avg_ul_sd_contrib_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('UL extra rate given by SD, ratio');
xlabel('Budget');
end
figure
avg_hop_number_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('Avg number of hops per user');
xlabel('Budget');
end
figure
avg_donor_tps_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('Avg users attached to Donor');
xlabel('Budget');
end
figure
avg_node_degree_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('Avg IAB Donor/Node outgoing links');
xlabel('Budget');
end
figure
avg_time_solving_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('Average solving time, s');
xlabel('Budget');
end
figure
avg_solved_inst_fig = gca;
hold on;
grid on;
legend('Location', 'best'); 
if strcmp(export_style(1:num_files), 'ieee')
title('Average solved instances, s');
xlabel('Budget');
end

line_options = {'-'; '--'; ':';'-.'};
color_options = [0 0.4470 0.7410;
     0.8500 0.3250 0.0980;]; %two colors, add transparency to mean rate to relate the colors
% color_options = [0 0.4470 0.7410;
%     0.8500 0.3250 0.0980;
%     0.9290 0.6940 0.1250;
%     0.4940 0.1840 0.5560;
%     ];
%color_options = distinguishable_colors(numel(mat_files));
marker_options = {'diamond','none'};
display_names = cell(num_files,1);
for mf = 1:numel(mat_files)
    display_names{mf} = mat_files(mf).name;
    display_names{mf} = split(display_names{mf},'.');
    display_names{mf} = display_names{mf}{1};
    switch display_names{mf}
        case 'reportSum'
            display_names{mf} = 'MTF1';
        case 'reportPeakSum'
            display_names{mf} = 'PTF1';
        case 'reportSumRefl'
            display_names{mf} = 'MTF2';
        case 'reportPeakSumRefl'
            display_names{mf} = 'PTF2';
    end
    %load the file
    load([mat_files(mf).folder '/' mat_files(mf).name]);
    
    %installed IAB Nodes plot
    
    plot(avg_installed_dev_fig,str2num(char(ticks_labels)), avg_iab, 'DisplayName', [display_names{mf} ' - IAB Nodes'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_installed_dev_fig,str2num(char(ticks_labels)), avg_ris, 'DisplayName', [display_names{mf} ' - RIS'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{2},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_installed_dev_fig,str2num(char(ticks_labels)), avg_ncr, 'DisplayName', [display_names{mf} ' - NCR'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{3},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_installed_dev_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_installed_dev_fig,'auto')
    end
    ylim(avg_installed_dev_fig,[0 inf])
    
    %cost plot
    plot(avg_used_budget_fig,str2num(char(ticks_labels)), avg_cost,  'DisplayName', display_names{mf},'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_used_budget_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_used_budget_fig,'auto')
    end
    ylim(avg_used_budget_fig,[0 inf])
    
    
    %tp dl mean rates plot
    plot(avg_dl_tp_rates_fig,str2num(char(ticks_labels)), avg_dl_tp_rate,  'DisplayName', [display_names{mf} ' - mean'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_dl_tp_rates_fig,str2num(char(ticks_labels)), avg_dl_tp_full + avg_dl_tp_min,  'DisplayName', [display_names{mf} ' - peak'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{2},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_dl_tp_rates_fig,str2num(char(ticks_labels)), avg_dl_tp_min,  'DisplayName', [display_names{mf} ' - min'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{3},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_dl_tp_rates_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_dl_tp_rates_fig,'auto')
    end
    ylim(avg_dl_tp_rates_fig,[0 inf])

    %tp ul mean rates plot
    plot(avg_ul_tp_rates_fig,str2num(char(ticks_labels)), avg_ul_tp_rate,  'DisplayName', [display_names{mf} ' - mean'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_ul_tp_rates_fig,str2num(char(ticks_labels)), avg_ul_tp_full + avg_ul_tp_min,  'DisplayName', [display_names{mf} ' - peak'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{2},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_ul_tp_rates_fig,str2num(char(ticks_labels)), avg_ul_tp_min,  'DisplayName', [display_names{mf} ' - min'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{3},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_ul_tp_rates_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_ul_tp_rates_fig,'auto')
    end
    ylim(avg_ul_tp_rates_fig,[0 inf])


    %distance plot
    plot(avg_link_length_fig,str2num(char(ticks_labels)), avg_acc_dist,  'DisplayName', [display_names{mf} ' - ACC'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_link_length_fig,str2num(char(ticks_labels)), avg_bh_length,  'DisplayName', [display_names{mf} ' - BH'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{2},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_link_length_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_link_length_fig,'auto')
    end
    ylim(avg_link_length_fig,[0 inf])
    
    %angle plot
    plot(avg_ang_sep_fig,str2num(char(ticks_labels)), avg_ang_div,  'DisplayName', display_names{mf},'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_ang_sep_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_ang_sep_fig,'auto')
    end
    ylim(avg_ang_sep_fig,[0 inf])
    
    % users plot
    plot(avg_users_fig, str2num(char(ticks_labels)), avg_dir_users,  'DisplayName', [display_names{mf} ' - DIR'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_users_fig, str2num(char(ticks_labels)), avg_ris_users,  'DisplayName', [display_names{mf} ' - RIS'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{2},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_users_fig, str2num(char(ticks_labels)), avg_ncr_users,  'DisplayName', [display_names{mf} ' - NCR'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{3},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_users_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_users_fig,'auto')
    end
    ylim(avg_users_fig,[0 inf])
    
    
    %device occupation plot
    plot(avg_device_occupation_fig,str2num(char(ticks_labels)), avg_don_time,  'DisplayName', [display_names{mf} ' - DON'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_device_occupation_fig,str2num(char(ticks_labels)), avg_iab_time,  'DisplayName', [display_names{mf} ' - IAB'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{2},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_device_occupation_fig,str2num(char(ticks_labels)), avg_ris_time,  'DisplayName', [display_names{mf} ' - RIS'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{3},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_device_occupation_fig,str2num(char(ticks_labels)), avg_ncr_time,  'DisplayName', [display_names{mf} ' - NCR'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{4},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_device_occupation_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_device_occupation_fig,'auto')
    end
    ylim(avg_device_occupation_fig,[0 inf])

    
    %dl sd contribution plot
     plot(avg_dl_sd_contrib_fig,str2num(char(ticks_labels)), avg_dl_ris_contrib,  'DisplayName', [display_names{mf} ' - RIS'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     plot(avg_dl_sd_contrib_fig,str2num(char(ticks_labels)), avg_dl_ncr_contrib,  'DisplayName', [display_names{mf} ' - NCR'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{2},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_dl_sd_contrib_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_dl_sd_contrib_fig,'auto')
    end
    ylim(avg_dl_sd_contrib_fig,[0 inf])

        %ul sd contribution plot
     plot(avg_ul_sd_contrib_fig,str2num(char(ticks_labels)), avg_ul_ris_contrib,  'DisplayName', [display_names{mf} ' - RIS'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     plot(avg_ul_sd_contrib_fig,str2num(char(ticks_labels)), avg_ul_ncr_contrib,  'DisplayName', [display_names{mf} ' - NCR'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{2},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_ul_sd_contrib_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_ul_sd_contrib_fig,'auto')
    end
    ylim(avg_ul_sd_contrib_fig,[0 inf])
    
    %hop number plot
     plot(avg_hop_number_fig,str2num(char(ticks_labels)), avg_hop_number,  'DisplayName', display_names{mf},'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_hop_number_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_hop_number_fig,'auto')
    end
    ylim(avg_hop_number_fig,[0 inf])
    
    %donor tps plot
     plot(avg_donor_tps_fig,str2num(char(ticks_labels)), avg_donor_tps,  'DisplayName', display_names{mf},'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_donor_tps_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_donor_tps_fig,'auto')
    end
    ylim(avg_donor_tps_fig,[0 inf])
    
    % node degree
    plot(avg_node_degree_fig,str2num(char(ticks_labels)), avg_don_degree,  'DisplayName', [display_names{mf} ' - DON'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     plot(avg_node_degree_fig,str2num(char(ticks_labels)), avg_node_degree,  'DisplayName', [display_names{mf} ' - IAB'],'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{2},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_node_degree_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_node_degree_fig,'auto')
    end
    ylim(avg_node_degree_fig,[0 inf])


    %solving time plot
     plot(avg_time_solving_fig,str2num(char(ticks_labels)), avg_solver_time/1e3,  'DisplayName', display_names{mf},'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_time_solving_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_time_solving_fig,'auto')
    end
    ylim(avg_time_solving_fig,[0 inf])

     %solved instances plot
     plot(avg_solved_inst_fig,str2num(char(ticks_labels)), solved_count,  'DisplayName', display_names{mf},'Color',color_options(ceil(mf/2),:),'LineStyle',line_options{1},'Marker',marker_options{mod(mf,2)+1},'MarkerIndices',1:5:length(ticks_labels));
     
    if (min(solved_count)<=plot_lim*tot_inst(mf))
        xlim(avg_time_solving_fig,[str2double(ticks_labels{find(solved_count>plot_lim*tot_inst(mf),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_time_solving_fig,'auto')
    end
    ylim(avg_time_solving_fig,[0 inf])
    
    
end
figHandles = findobj('Type', 'figure');
for i=1:numel(figHandles)
    sdf(figHandles(i),export_style);
end
