clear all;
addpath('utils');
sim_folder = 'Mat_files_solutions/';
sim_id = 'buildings_test';
test_folder = '';
%test_folder = 'free_space_all/';
%test_folder = 'free_space_vs_urban/';
export_style = 'ieee';
%export_style = 'ieee_large_lines';

mat_files = dir([sim_folder sim_id '/mat_results/' test_folder '*.mat']);
num_files = numel(mat_files);
figure('units','normalized','outerposition',[0 0 1 1]);

avg_installed_devices_fig = gca;
hold on;
grid on;
axis square;
box on;
legend('Location', 'best');
if strcmp(export_style, 'ieee')
    ylabel('Mean installed radio devices');
    xlabel('Budget');
end

figure('units','normalized','outerposition',[0 0 1 1]);

avg_tp_rates_fig = gca;
hold on;
grid on;
axis square;
box on;
legend('Location', 'best');
if strcmp(export_style, 'ieee')
    ylabel('Avg rates, Mbps');
    xlabel('Budget');
end
figure('units','normalized','outerposition',[0 0 1 1]);

% avg_users_per_ris_fig = gca;
% hold on;
% grid on;
% axis square;
% box on;
% legend('Location', 'best');
% if strcmp(export_style, 'ieee')
%     ylabel('Avg users per RIS');
%     xlabel('Budget');
% end
% figure('units','normalized','outerposition',[0 0 1 1]);

avg_multihop_fig = gca;
hold on;
grid on;
axis square;
box on;
legend('Location', 'best');
if strcmp(export_style, 'ieee')
    ylabel('Avg number of hops');
    xlabel('Budget');
end
figure('units','normalized','outerposition',[0 0 1 1]);

avg_donor_degree_fig = gca;
hold on;
grid on;
axis square;
box on;
legend('Location', 'best');
if strcmp(export_style, 'ieee')
    ylabel('Avg Donor degree');
    xlabel('Budget');
end

color_options = [0 0.4470 0.7410;0.9290 0.6940 0.1250];

marker_options = {'none','diamond'};

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
    
    %installed devices plot
    
    plot(avg_installed_devices_fig,str2num(char(ticks_labels)), avg_iab, 'DisplayName', ['IAB Nodes - ' display_names{mf}],'Color',color_options(mf,:),'LineStyle','-','Marker',marker_options{mf},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_installed_devices_fig,str2num(char(ticks_labels)), avg_ris, 'DisplayName', ['RIS - ' display_names{mf}],'Color',color_options(mf,:),'LineStyle','--','Marker',marker_options{mf},'MarkerIndices',1:5:length(ticks_labels));
    
    sdf(1,export_style);
    xlim(avg_installed_devices_fig,[6,20])
    ylim(avg_installed_devices_fig,[0,16])
    
    
    %tp rates plot
    plot(avg_tp_rates_fig,str2num(char(ticks_labels)), avg_tp_rate,  'DisplayName', ['Mean rates - ' display_names{mf}],'Color',color_options(mf,:),'LineStyle','-','Marker',marker_options{mf},'MarkerIndices',1:5:length(ticks_labels));
    plot(avg_tp_rates_fig,str2num(char(ticks_labels)), avg_tp_full + avg_tp_min,  'DisplayName', ['Peak rates - ' display_names{mf}],'Color',color_options(mf,:),'LineStyle','--','Marker',marker_options{mf},'MarkerIndices',1:5:length(ticks_labels));
    
    sdf(2,export_style);
    xlim(avg_tp_rates_fig,[6,20])
    ylim(avg_tp_rates_fig,[100,700])
    
    
%     %users per ris plot
%     plot(avg_users_per_ris_fig,str2num(char(ticks_labels)), avg_ris_users./avg_ris,  'DisplayName', display_names{mf},'Color',color_options(mf,:));
%     sdf(export_style);
%     xlim(avg_users_per_ris_fig,[6,20])
%     ylim(avg_users_per_ris_fig,[0 inf])
    
        %multi-hop plot
    plot(avg_multihop_fig,str2num(char(ticks_labels)), avg_hop_number,  'DisplayName', display_names{mf},'Color',color_options(mf,:),'Marker',marker_options{mf},'MarkerIndices',1:5:length(ticks_labels));
    sdf(3,export_style);
    xlim(avg_multihop_fig,[6,20])
    ylim(avg_multihop_fig,[2,5.6])
    
        %donor degree plot
    plot(avg_donor_degree_fig,str2num(char(ticks_labels)), avg_don_degree,  'DisplayName', display_names{mf},'Color',color_options(mf,:),'Marker',marker_options{mf},'MarkerIndices',1:5:length(ticks_labels));
    sdf(4,export_style);
    xlim(avg_donor_degree_fig,[6,20])
    ylim(avg_donor_degree_fig,[2,4.1])
    
    
    
    
end
