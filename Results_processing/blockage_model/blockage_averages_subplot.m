clear all;
addpath('utils');
sim_folder = 'Mat_files_solutions/';
sim_id = 'buildings_test';
test_folder = '';
%test_folder = 'free_space_all/';
%test_folder = 'free_space_vs_urban/';
export_style = 'Polimi-ppt';
%export_style = 'ieee_large_lines';

mat_files = dir([sim_folder sim_id '/mat_results/' test_folder '*.mat']);
num_files = numel(mat_files);
figure_handle = figure('units','normalized','outerposition',[0 0 1 1]);

avg_installed_iab_fig = subplot(4,5,1);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Mean installed IAB Nodes');
xlabel('Budget');
end

avg_installed_ris_fig = subplot(4,5,2);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Mean installed RIS');
xlabel('Budget');
end

avg_used_budget_fig = subplot(4,5,3);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Mean Cost');
xlabel('Budget');
end

avg_tp_rate_lt_fig = subplot(4,5,4);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Avg rates, Mbps');
xlabel('Budget');
end

avg_tp_rate_inst_fig = subplot(4,5,5);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Peak rates, Mbps');
xlabel('Budget');
end

avg_tp_rate_min_fig = subplot(4,5,6);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Minimum rates, Mbps');
xlabel('Budget');
end

avg_link_length_fig = subplot(4,5,7);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Mean Access Distance, m');
xlabel('Budget');
end

avg_ang_sep_fig = subplot(4,5,8);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Mean Angular Separation, degrees');
xlabel('Budget');
end

avg_dir_users_fig = subplot(4,5,9);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Average direct users');
xlabel('Budget');
end

avg_ris_users_fig = subplot(4,5,10);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Average RIS users');
xlabel('Budget');
end

avg_donor_occupation_fig = subplot(4,5,11);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Average IAB Donor busy ratio');
xlabel('Budget');
end

avg_iab_occupation_fig = subplot(4,5,12);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Average IAB Node busy ratio');
xlabel('Budget');
end

avg_ris_occupation_fig = subplot(4,5,13);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Average RIS busy ratio');
xlabel('Budget');
end

avg_time_solving_fig = subplot(4,5,14);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Average solving time, s');
xlabel('Budget');
end

avg_users_per_ris_fig = subplot(4,5,15);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Avg users per RIS');
xlabel('Budget');
end

avg_hop_number_fig = subplot(4,5,16);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Avg number of hops per user');
xlabel('Budget');
end

avg_donor_tps_fig = subplot(4,5,17);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Avg users attached to Donor');
xlabel('Budget');
end

avg_bh_len_fig = subplot(4,5,18);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Avg Backhaul link length');
xlabel('Budget');
end

avg_donor_degree_fig = subplot(4,5,19);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Avg Donor outgoing links');
xlabel('Budget');
end

avg_node_degree_fig = subplot(4,5,20);
hold on;
grid on;
legend('Location', 'best'); 
if ~strcmp(export_style(1:num_files), 'ieee')
title('Avg IAB Node outgoing links');
xlabel('Budget');
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
    
    plot(avg_installed_iab_fig,str2num(char(ticks_labels)), avg_iab, 'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_installed_iab_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_installed_iab_fig,'auto')
    end
    ylim(avg_installed_iab_fig,[0 inf])
    
    %installed RIS plot
    
    plot(avg_installed_ris_fig,str2num(char(ticks_labels)), avg_ris, 'DisplayName', display_names{mf});   
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_installed_ris_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_installed_ris_fig,'auto')
    end
    ylim(avg_installed_ris_fig,[0 inf])

    
    %cost plot
    plot(avg_used_budget_fig,str2num(char(ticks_labels)), avg_cost,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_used_budget_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_used_budget_fig,'auto')
    end
    ylim(avg_used_budget_fig,[0 inf])
    
    
    %tp mean rates plot
    plot(avg_tp_rate_lt_fig,str2num(char(ticks_labels)), avg_tp_rate,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_tp_rate_lt_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_tp_rate_lt_fig,'auto')
    end
    ylim(avg_tp_rate_lt_fig,[0 inf])
    
        %tp max available rates plot
    plot(avg_tp_rate_inst_fig,str2num(char(ticks_labels)), avg_tp_full + avg_tp_min,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_tp_rate_inst_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_tp_rate_inst_fig,'auto')
    end
    ylim(avg_tp_rate_inst_fig,[0 inf])
    
        %tp min rates plot
    plot(avg_tp_rate_min_fig,str2num(char(ticks_labels)), avg_tp_min,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_tp_rate_min_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_tp_rate_min_fig,'auto')
    end
    ylim(avg_tp_rate_min_fig,[0 inf])
    

    %distance plot
    plot(avg_link_length_fig,str2num(char(ticks_labels)), avg_acc_dist,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_link_length_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_link_length_fig,'auto')
    end
    ylim(avg_link_length_fig,[0 inf])
    
    %angle plot
    plot(avg_ang_sep_fig,str2num(char(ticks_labels)), avg_ang_div,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_ang_sep_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_ang_sep_fig,'auto')
    end
    ylim(avg_ang_sep_fig,[0 inf])
    
    %direct users plot
    plot(avg_dir_users_fig, str2num(char(ticks_labels)), avg_dir_users,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_dir_users_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_dir_users_fig,'auto')
    end
    ylim(avg_dir_users_fig,[0 inf])
    
    %RIS users plot
    plot(avg_ris_users_fig, str2num(char(ticks_labels)), avg_ris_users,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_ris_users_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_ris_users_fig,'auto')
    end
    ylim(avg_ris_users_fig,[0 inf])
    
    %donor occupation plot
    plot(avg_donor_occupation_fig,str2num(char(ticks_labels)), avg_don_time,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_donor_occupation_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_donor_occupation_fig,'auto')
    end
    ylim(avg_donor_occupation_fig,[0 inf])
    
    %iab occupation plot
    plot(avg_iab_occupation_fig,str2num(char(ticks_labels)), avg_iab_time,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_iab_occupation_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_iab_occupation_fig,'auto')
    end
    ylim(avg_iab_occupation_fig,[0 inf])
    
    %ris occupation plot
    plot(avg_ris_occupation_fig,str2num(char(ticks_labels)), avg_ris_time,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_ris_occupation_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_ris_occupation_fig,'auto')
    end
    ylim(avg_ris_occupation_fig,[0 inf])
    
    %solving time plot
     plot(avg_time_solving_fig,str2num(char(ticks_labels)), avg_solver_time/1e3,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_time_solving_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_time_solving_fig,'auto')
    end
    ylim(avg_time_solving_fig,[0 inf])
    
    %users per ris plot
     plot(avg_users_per_ris_fig,str2num(char(ticks_labels)), avg_ris_users./avg_ris,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_users_per_ris_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_users_per_ris_fig,'auto')
    end
    ylim(avg_users_per_ris_fig,[0 inf])
    
    %hop number plot
     plot(avg_hop_number_fig,str2num(char(ticks_labels)), avg_hop_number,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_hop_number_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_hop_number_fig,'auto')
    end
    ylim(avg_hop_number_fig,[0 inf])
    
    %donor tps plot
     plot(avg_donor_tps_fig,str2num(char(ticks_labels)), avg_donor_tps,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_donor_tps_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_donor_tps_fig,'auto')
    end
    ylim(avg_donor_tps_fig,[0 inf])
    
    %bh length plot
     plot(avg_bh_len_fig,str2num(char(ticks_labels)), avg_bh_length,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_bh_len_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_bh_len_fig,'auto')
    end
    ylim(avg_bh_len_fig,[0 inf])
    
    % donor degree
     plot(avg_donor_degree_fig,str2num(char(ticks_labels)), avg_don_degree,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_donor_degree_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_donor_degree_fig,'auto')
    end
    ylim(avg_donor_degree_fig,[0 inf])
    
    %IAB node degree
     plot(avg_node_degree_fig,str2num(char(ticks_labels)), avg_node_degree,  'DisplayName', display_names{mf});
    %sdf(export_style); 
    if (min(solved_count)<=56)
        xlim(avg_node_degree_fig,[str2double(ticks_labels{find(solved_count>56,1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(avg_node_degree_fig,'auto')
    end
    ylim(avg_node_degree_fig,[0 inf])
    
    
end
