clearvars;
addpath('utils');
sim_folder = 'Mat_files_solutions/';
sim_id = 'Sim_2';

export_style = 'Polimi-ppt';

%export_style = 'ieee_large_lines';

mat_files = dir([sim_folder sim_id '/*.mat']);
avg_tp_rate_fig = figure();
hold on;
grid on;
%sdf(export_style);
legend();
if ~strcmp(export_style(1:4), 'ieee')
title('Mean TP Rate');
end

avg_used_budget_fig = figure();
hold on;
grid on;
sdf(export_style);
legend();
if ~strcmp(export_style(1:4), 'ieee')
title('Mean Cost');
end

avg_net_element_fig = figure();
hold on;
grid on;
sdf(export_style);
legend();
if ~strcmp(export_style(1:4), 'ieee')
title('Number of donors and RIS');
end


avg_min_dist_fig = figure();
hold on;
grid on;
sdf(export_style);
legend();
if ~strcmp(export_style(1:4), 'ieee')
title('Mean Min Distance');
end

avg_aided_fig = figure();
hold on;
grid on;
sdf(export_style);
legend();
if ~strcmp(export_style(1:4), 'ieee')
title('Average Assisted Links');
end

line_options = {''; '--'; ':'};
color_options= {'k'; 'k'; 'k'};

display_names = {'No Ris'; '50x50cm RIS'; '150x150cm RIS'};

for mf = 1:numel(mat_files)
    %load the file
    load([mat_files(mf).folder '/' mat_files(mf).name]);
    if strcmp(sim_id, 'Sim_4')
        ticks_labels = ticks_labels(1:9);
    end
    
    %tp rate plot
    figure(avg_tp_rate_fig);
    plot(str2num(char(ticks_labels)), avg_tp_rate, [color_options{mf} line_options{mf}], 'DisplayName', display_names{mf});
    xlim auto
    ylim auto

    
    %norm. cost plot
    figure(avg_used_budget_fig);
    plot(str2num(char(ticks_labels)), avg_cost./(32/3), [color_options{mf} line_options{mf}], 'DisplayName', display_names{mf});
    xlim auto
    ylim auto
    
    
    %net elements plot
    figure(avg_net_element_fig);
    plot(str2num(char(ticks_labels)), avg_donors, ['r' line_options{mf}], 'DisplayName', [display_names{mf} ' - Donors']);
    plot(str2num(char(ticks_labels)), avg_ris, ['b' line_options{mf}], 'DisplayName', [display_names{mf} ' - RIS']);
    xlim auto
    ylim auto
    
    
%     if ~strcmp(mat_files(mf).name, '1_noris.mat')
%     yyaxis right;
%     plot(str2num(char(ticks_labels)), avg_aided_percent, line_options{mf}, 'HandleVisibility','off');
%     yyaxis left
%     end

    %distance plot
    figure(avg_min_dist_fig);
    if ~strcmp(mat_files(mf).name, '1_noris.mat')
        plot(str2num(char(ticks_labels)), avg_covered_don_distance, ['r' line_options{mf}], 'DisplayName', [display_names{mf} ' Aided Donors Dist.']);
        plot(str2num(char(ticks_labels)), avg_ris_distance, ['b' line_options{mf}], 'DisplayName', [display_names{mf} ' Dist.']);
    end
    plot(str2num(char(ticks_labels)), avg_uncovered_don_dist, ['k' line_options{mf}], 'DisplayName', [display_names{mf} ' Unaided Donors Dist.']);
    xlim auto
    ylim auto
    
    %assisted links plot
    if ~strcmp(mat_files(mf).name, '1_noris.mat')
        figure(avg_aided_fig);
        plot(str2num(char(ticks_labels)), avg_aided_percent,[color_options{mf} line_options{mf}], 'DisplayName', display_names{mf});
        xlim auto;
        ylim([0 1]);
    end
    
    
end

