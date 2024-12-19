%% init
clearvars;
addpath('utils/');
sim_folder = 'STEP2_iab_ris_sr_ul_s1budget6_s1minlen_sembudgetspan_of05/';
%sim_folder = 'SR_a200x200_20cs_30tp_5mcs_1e4el_D60_maxR_minRout/';
%sim_folder = 'small_5mcs_1e5el_rout0-1e6_maxr_50runs/';
model_name = 'RISSRmaxAngDivMinLenUL_FixedBs';
%model_name = 'singleris_max_rate_zeroreconf';
%model_name = 'noris_maxavgrate';
%folder_names_root = 'small_minRout';
%folder_names_root = 'SR_a400x300_52cs_5mcs_1e4el_D60_maxR_100mbps_CS';
folder_names_root = 'tesipaolo';
%% open results folder and list files curresponding to the model
%files = dir(['solved_instances/5mcs_small/' folder_names_root '_50r/solutions/' model_name '*.m']);
directories = dir(['solved_instances/' sim_folder folder_names_root '*']);
n_dir = numel(directories);

%nat sort forlder such that the are sorted in increasing parameter
%variations
dir_name_list = {directories.name};
dir_name_list = natsort(dir_name_list);


%% execute some data processing for each folder, over all the runs in the folder

avg_donors      = zeros(n_dir,1);
avg_ris         = zeros(n_dir,1);
avg_cost        = zeros(n_dir,1);
avg_ang_sep     = zeros(n_dir,1);
avg_linlen    = zeros(n_dir,1);
avg_iab= zeros(n_dir,1);
solved_count    = zeros(n_dir,1);
avg_obj         = zeros(n_dir,1);
avg_ris_distance= zeros(n_dir,1);
avg_covered_don_distance= zeros(n_dir,1);
avg_uncovered_don_dist= zeros(n_dir,1);
avg_aided_percent =zeros(n_dir,1);
avg_tau_ris       =zeros(n_dir, 1);

avg_rel = zeros(n_dir,1);

wb = waitbar(0);

for d = 1:numel(dir_name_list)
    %enter solution folders and get all the solved .mfiles
    disp(['Processing ' dir_name_list{d}]);
    waitbar(d/numel(dir_name_list),wb,dir_name_list{d});
    solutions = dir(['solved_instances/' sim_folder dir_name_list{d} '/solutions/' model_name '*.m']);
    
    
    if numel(solutions) < 20
        disp([dir_name_list{d} ' has ' num2str(20-numel(solutions)) ' unsolved instances']);
    end
    solved_count(d) = numel(solutions);
    
    distance_samples_count_covered = 0;
    distance_samples_count_uncovered = 0;
    
    %for each solution...
    for sol=1:numel(solutions)
        %run the solution
        run([solutions(sol).folder '/' solutions(sol).name]);
        %run .mat for angles and length
        data_name = split(solutions(sol).name, '_'); %split the string
        data_name = data_name{end}; %get the run
        data_name = data_name(1:end-2); %truncate .m to get the .mat data name
        load(['solved_instances/' sim_folder dir_name_list{d} '/instances/' data_name],...
            'n_tp', 'n_cs' ,'cs_tp_distance_matrix',...
            'cs_cs_distance_matrix', 'smallest_angles','cs_tp_distance_matrix','OF_weight',...
            'rel_price','iab_price');
        
        avg_donors(d) = avg_donors(d) + sum(y_don);
        avg_iab(d)    = avg_iab(d) + sum(y_iab);       
        avg_ris(d)         = avg_ris(d) + sum(y_ris);
        
                if OF_weight == 0
                    avg_linlen(d)    = avg_linlen(d) + mean(avg_lin_len);
                    temp_angle = 0;
                    for t=1:n_tp
                        for c=1:n_cs
                            for r=1:n_cs
                                if c==r
                                    continue;
                                end
                                if x(t,c,r)==1
                                    temp_angle = temp_angle + smallest_angles(t,c,r);
                                end
                            end
                        end
                    end
                    temp_angle = temp_angle/n_tp;
                    avg_ang_sep(d)     = avg_ang_sep(d) + temp_angle;
                elseif OF_weight == 1
                    avg_ang_sep(d)     = avg_ang_sep(d) + mean(min_angle);
                    temp_len = 0;
                    for t=1:n_tp
                        for c=1:n_cs
                            for r=1:n_cs
                                if c==r
                                    continue;
                                end
                                %if x(t,c,r)==1
                                if x_ris(t,c,r) || x_sr(t,c,r) == 1
                                    temp_len = temp_len + 0.5*(...
                                        cs_tp_distance_matrix(c,t)+cs_tp_distance_matrix(r,t));
                                end
                            end
                        end
                    end
                    temp_len = temp_len/n_tp;
                    avg_linlen(d)     = avg_linlen(d) + temp_len;
                else
                    avg_ang_sep(d)     = avg_ang_sep(d) + mean(min_angle);
                    avg_linlen(d)    = avg_linlen(d) + mean(avg_lin_len);
                    disp( mean(avg_lin_len));
                end
    end
    %finish computing averages
    avg_donors(d) = avg_donors(d)/numel(solutions);
    avg_ris(d) = avg_ris(d)/numel(solutions);
    %avg_cost(d) = avg_cost(d)/numel(solutions);
    
    avg_ang_sep(d) = avg_ang_sep(d)/numel(solutions);
    avg_linlen(d) = avg_linlen(d)/numel(solutions);
    
    avg_iab(d) = avg_iab(d)/numel(solutions);
    avg_ris_distance(d)=avg_ris_distance(d)/distance_samples_count_covered;
    avg_uncovered_don_dist(d)= avg_uncovered_don_dist(d)/distance_samples_count_uncovered;
    avg_covered_don_distance(d) = avg_covered_don_distance(d)/distance_samples_count_covered;
    
    avg_obj(d) = avg_obj(d)/numel(solutions);
   
    clear('x')
end

%get the x ticks by splitting the folder names and getting the varying
%parameter
% ticks_labels = split([directories.name], '_');
% ticks_labels = ticks_labels(9:9:end);
% ticks_labels = natsort(cellfun(@(ticks)ticks(:,3:end), ticks_labels, 'uni', false));
% switch sim_folder
%     case 'Sim_1/'
%         ticks_labels = split([directories.name], '_');
%         ticks_labels = ticks_labels(9:9:end);
%         ticks_labels = natsort(cellfun(@(ticks)ticks(:,8:end), ticks_labels, 'uni', false));
%     case 'Sim_2/'
%         ticks_labels = split([directories.name], '_');
%         ticks_labels = ticks_labels(10:10:end);
%         ticks_labels = natsort(cellfun(@(ticks)ticks(:,7:end), ticks_labels, 'uni', false));
%     case 'Sim_3/'
%         ticks_labels = split([directories.name], '_');
%         ticks_labels = ticks_labels(9:9:end);
%         ticks_labels = natsort(cellfun(@(ticks)ticks(:,3:end), ticks_labels, 'uni', false));
%     case 'Sim_4/'
%         ticks_labels = split([directories.name], '_');
%         ticks_labels = ticks_labels(9:9:end);
%         ticks_labels = natsort(cellfun(@(ticks)ticks(:,5:end), ticks_labels, 'uni', false));
%     case 'Sim_5/'
%         ticks_labels = split([directories.name], '_');
%         ticks_labels = ticks_labels(9:9:end);
%         ticks_labels = natsort(cellfun(@(ticks)ticks(:,5:end), ticks_labels, 'uni', false));
% end

%ticks_labels = split([directories.name], '_');
ticks_labels = {directories.name};
%ticks_labels = ticks_labels(9:9:end);
ticks_labels = natsort(cellfun(@(ticks)ticks(:,10:end), ticks_labels, 'uni', false));
ticks_labels = natsort(cellfun(@(ticks)extractBefore(ticks,'_'), ticks_labels, 'uni', false));

%% save results
mkdir(['mat_results/' sim_folder ]);
save(['mat_results/' sim_folder 'results'], 'ticks_labels',...
    'avg_donors',...
    'avg_iab',...
    'avg_ris',...
    'avg_ang_sep',...
    'avg_linlen');...
    
% %%
% %ticks = {'0', '1','10','50','100','200','500','700'};
% %ticks = {'0', '1','2','3','4','5','6','7','8','9','10'};
%
%
% % ticks_labels = split([directories.name], '_');
% % ticks_labels = ticks_labels(8:8:end);
% % ticks_labels = natsort(cellfun(@(ticks)ticks(:,7:end), ticks_labels, 'uni', false));
%
% f1=figure();
% plot(str2num(char(ticks_labels)), avg_ris);
% grid on;
% hold on;
% xlabel('Mbps');
% ylabel('#RIS');
% %yyaxis right;
% %plot(str2num(char(ticks_labels)),solved_count);
% %ylabel('Solved instances');
% title('Average number of RIS - 2500 elements');
% % xticks(1:numel(avg_ris));
% % xticklabels(ticks_labels);
% sdf('Polimi-ppt');
%
% %% avg tp rate
% f2=figure();
% plot(str2num(char(ticks_labels)), avg_tp_rate);
% grid on;
% hold on;
% xlabel('Mbps');
% ylabel('Mbps');
% %yyaxis right;
% %plot(str2num(char(ticks_labels)),solved_count);
% %ylabel('Solved instances');
% title('Average TP rate');
%
% sdf('Polimi-ppt');
%
% %% avg tot rate
% f3=figure();
% plot(str2num(char(ticks_labels)), avg_tot_rate);
% grid on;
% hold on;
% xlabel('Mbps');
% ylabel('Mbps');
% %yyaxis right;
% %plot(str2num(char(ticks_labels)),solved_count);
% %ylabel('Solved instances');
% title('Average system rate');
%
% sdf('Polimi-ppt');
%
% %% avg cost
% f4=figure();
% plot(str2num(char(ticks_labels)), avg_cost);
% grid on;
% hold on;
% xlabel('Mbps');
% ylabel('Deployment Price');
% %yyaxis right;
% %plot(str2num(char(ticks_labels)),solved_count);
% %ylabel('Solved instances');
% title('Average delpoyment cost');
% sdf('Polimi-ppt');