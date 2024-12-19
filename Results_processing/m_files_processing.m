%% init
clearvars;
addpath('utils/');
sim_folder = 'Sim_4/';
%sim_folder = 'SR_a200x200_20cs_30tp_5mcs_1e4el_D60_maxR_minRout/';
%sim_folder = 'small_5mcs_1e5el_rout0-1e6_maxr_50runs/';
model_name = 'fakeris_maxavgrate';
%model_name = 'singleris_max_rate_zeroreconf';
%model_name = 'noris_maxavgrate';
%folder_names_root = 'small_minRout';
%folder_names_root = 'SR_a400x300_52cs_5mcs_1e4el_D60_maxR_100mbps_CS';
folder_names_root = 'SR_a400x300_52cs_32tp_5mcs_1e4el_D60_maxR_minRout';
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
avg_tp_rate     = zeros(n_dir,1);
avg_tot_rate    = zeros(n_dir,1);
avg_ris_min_dist= zeros(n_dir,1);
solved_count    = zeros(n_dir,1);
avg_obj         = zeros(n_dir,1);
avg_ris_distance= zeros(n_dir,1);
avg_covered_don_distance= zeros(n_dir,1);
avg_uncovered_don_dist= zeros(n_dir,1);
avg_aided_percent =zeros(n_dir,1);
avg_tau_ris       =zeros(n_dir, 1);

wb = waitbar(0);

for d = 1:numel(dir_name_list)
    %enter solution folders and get all the solved .mfiles
    disp(['Processing ' dir_name_list{d}]);
    waitbar(d/numel(dir_name_list),wb,dir_name_list{d});
    solutions = dir(['solved_instances/' sim_folder dir_name_list{d} '/solutions/' model_name '*.m']);
    
    if numel(solutions) < 30
        disp([dir_name_list{d} ' has ' num2str(30-numel(solutions)) ' unsolved instances']);
    end
    solved_count(d) = numel(solutions);
    
    distance_samples_count_covered = 0;
    distance_samples_count_uncovered = 0;
    
    %for each solution...
    for sol=1:numel(solutions)
        %run the solution
        run([solutions(sol).folder '/' solutions(sol).name]);
        avg_obj(d) = avg_obj(d) + obj;
        switch model_name
            case 'fakeris_maxavgrate'
                %load needed variables from the curresponding .mat file
                data_name = split(solutions(sol).name, '_'); %split the string
                data_name = data_name{end}; %get the run
                data_name = data_name(1:end-2); %truncate .m to get the .mat data name
                load(['solved_instances/' sim_folder dir_name_list{d} '/instances/' data_name],...
                    'donor_price', 'ris_price','n_tp', 'cs_tp_distance_matrix',...
                    'cs_cs_distance_matrix');
                
                
                %preprocessing
                %count ris as installed only if they partake in a positive flow
                if sum( y_don ~= (squeeze(sum(tau_ris, [1 3])) > 0)' ) > 0
                    disp(['Preprocessing has eliminated ' num2str(sum( y_don ~= (squeeze(sum(tau_ris, [1 3])) > 0)' )) ' nonactive donors']);
                    y_don = y_don & (squeeze(sum(tau_ris, [1 3])) > 0)';
                end
                if sum( y_ris ~= (squeeze(sum(tau_ris, [1 2])) > 0) ) > 0
                    disp(['Preprocessing has eliminated ' num2str(sum( y_ris ~= (squeeze(sum(tau_ris, [1 2])) > 0) )) ' nonactive RIS']);
                    y_ris = y_ris & (squeeze(sum(tau_ris, [1 2])) > 0);
                end
                if sum(xor(tau_ris,s), 'all') > 0
                    disp(['Preprocessing has eliminated ' num2str(sum(xor(tau_ris,s), 'all')) ' nonactive s variables']);
                    s = tau_ris & s;
                end
                %eliminate fakeris from y variables
                y_ris = y_ris(1:end-1);
                y_don = y_don(1:end-1);
                
                n_donors = sum(y_don);
                n_ris = sum(y_ris);
                avg_donors(d) = avg_donors(d) + n_donors;
                avg_ris(d) = avg_ris(d) + n_ris;
                
                avg_aided_percent(d) = avg_aided_percent(d)+sum(s(:,:,end),[1 2]);
                
                %compute cost by multiplying number of ris and donors by price
                avg_cost(d) = avg_cost(d) +...
                    donor_price*n_donors + ris_price*n_ris;
                
                
                avg_tp_rate(d) = avg_tp_rate(d) + mean(R);
                avg_tot_rate(d) = avg_tot_rate(d) + obj;
                
                %average of minimum ris distance
                for t=1:n_tp
                    if sum(s(t,:,:),'all') == 0 %tp not covered
                        %disp('fuckall');
                        continue
                    end
                    [cov_donor, cov_ris] =...
                        ind2sub(size(squeeze(s(t,:,:))),find(squeeze(s(t,:,:))));
                    if cov_ris ~= size(s,3) %if the covering ris is not fake
                        %the distance is the minimum between ris-t and ris-donor
                        avg_ris_min_dist(d) = avg_ris_min_dist(d) +...
                            min([...
                            cs_tp_distance_matrix(cov_donor, t)...
                            cs_tp_distance_matrix(cov_ris, t)...
                            ]);
                        avg_ris_distance(d) = avg_ris_distance(d)+ cs_tp_distance_matrix(cov_ris, t);
                        %disp(cs_tp_distance_matrix(cov_ris, t));
                        avg_covered_don_distance(d) = avg_covered_don_distance(d)+cs_tp_distance_matrix(cov_donor, t);
                        %increase sample count
                        distance_samples_count_covered = distance_samples_count_covered + 1;
                    elseif sum(s(t,:,:) ,[2 3]) > 0 %if tp is covered by a donor (with no min rout can be not covered)
                        avg_uncovered_don_dist(d) = avg_uncovered_don_dist(d)+cs_tp_distance_matrix(cov_donor, t);
                        distance_samples_count_uncovered = distance_samples_count_uncovered+1;
                    end
                end
                
                
                %avg tau ris
                avg_tau_ris(d) = mean(tau_ris(tau_ris > 0), 'all');
                
            case 'noris_maxavgrate'
                %load needed variables from the curresponding .mat file
                data_name = split(solutions(sol).name, '_'); %split the string
                data_name = data_name{end}; %get the run
                data_name = data_name(1:end-2); %truncate .m to get the .mat data name
                load(['solved_instances/' sim_folder dir_name_list{d} '/instances/' data_name],...
                    'donor_price', 'ris_price','n_tp', 'cs_tp_distance_matrix',...
                    'cs_cs_distance_matrix');
                
                
                %preprocessing
                
                if sum( xor(y_don, sum(tau_don,1)') ) > 0
                    disp(['Preprocessing has eliminated ' num2str(sum( xor(y_don, sum(tau_don,1)') )) ' nonactive donors']);
                    y_don = y_don & sum(tau_don,1)';
                end
                if sum(xor(tau_don,x_don), 'all') > 0
                    disp(['Preprocessing has eliminated ' num2str( sum(xor(tau_don,x_don), 'all') ) ' nonactive X_don variables']);
                    x_don = tau_don & x_don;
                end
                %eliminate fakeris from y variables
                y_don = y_don(1:end-1);
                
                n_donors = sum(y_don);
                avg_donors(d) = avg_donors(d) + n_donors;
                
                %compute cost by multiplying number of ris and donors by price
                avg_cost(d) = avg_cost(d) +...
                    donor_price*n_donors;
                
                
                avg_tp_rate(d) = avg_tp_rate(d) + mean(R);
                avg_tot_rate(d) = avg_tot_rate(d) + obj;
                
                for t=1:n_tp
                    if sum(x_don(t,:)) >0
                        cov_donor=...
                            ind2sub(size(squeeze(x_don(t,:))),find(squeeze(x_don(t,:))));
                        avg_uncovered_don_dist(d) = avg_uncovered_don_dist(d)+cs_tp_distance_matrix(cov_donor, t);
                        distance_samples_count_uncovered = distance_samples_count_uncovered+1;
                    end
                end
        end
        
        
    end
    %finish computing averages
    avg_donors(d) = avg_donors(d)/numel(solutions);
    avg_ris(d) = avg_ris(d)/numel(solutions);
    avg_cost(d) = avg_cost(d)/numel(solutions);
    avg_tp_rate(d) = avg_tp_rate(d)/numel(solutions);
    avg_tot_rate(d) = avg_tot_rate(d)/numel(solutions);
    
    avg_ris_min_dist(d) = avg_ris_min_dist(d)/distance_samples_count_covered;
    avg_ris_distance(d)=avg_ris_distance(d)/distance_samples_count_covered;
    avg_uncovered_don_dist(d)= avg_uncovered_don_dist(d)/distance_samples_count_uncovered;
    avg_covered_don_distance(d) = avg_covered_don_distance(d)/distance_samples_count_covered;
    
    avg_obj(d) = avg_obj(d)/numel(solutions);
    
    if numel(solutions)>0
        avg_aided_percent(d) = (n_tp - avg_aided_percent(d)/numel(solutions))/n_tp;
    end
    
    clear('s', 'tau_ris');
end

%get the x ticks by splitting the folder names and getting the varying
%parameter
% ticks_labels = split([directories.name], '_');
% ticks_labels = ticks_labels(9:9:end);
% ticks_labels = natsort(cellfun(@(ticks)ticks(:,3:end), ticks_labels, 'uni', false));
switch sim_folder
    case 'Sim_1/'
        ticks_labels = split([directories.name], '_');
        ticks_labels = ticks_labels(9:9:end);
        ticks_labels = natsort(cellfun(@(ticks)ticks(:,8:end), ticks_labels, 'uni', false));
    case 'Sim_2/'
        ticks_labels = split([directories.name], '_');
        ticks_labels = ticks_labels(10:10:end);
        ticks_labels = natsort(cellfun(@(ticks)ticks(:,7:end), ticks_labels, 'uni', false));
    case 'Sim_3/'
        ticks_labels = split([directories.name], '_');
        ticks_labels = ticks_labels(9:9:end);
        ticks_labels = natsort(cellfun(@(ticks)ticks(:,3:end), ticks_labels, 'uni', false));
    case 'Sim_4/'
        ticks_labels = split([directories.name], '_');
        ticks_labels = ticks_labels(9:9:end);
        ticks_labels = natsort(cellfun(@(ticks)ticks(:,5:end), ticks_labels, 'uni', false));
    case 'Sim_5/'
        ticks_labels = split([directories.name], '_');
        ticks_labels = ticks_labels(9:9:end);
        ticks_labels = natsort(cellfun(@(ticks)ticks(:,5:end), ticks_labels, 'uni', false));
end

%% save results
mkdir([sim_folder 'mat_results/']);
save([sim_folder 'mat_results/results'], 'avg_donors', 'avg_ris', 'avg_cost',...
    'avg_tp_rate','avg_tot_rate','avg_ris_min_dist', 'ticks_labels',...
    'avg_ris_distance', 'avg_covered_don_distance', 'avg_uncovered_don_dist',...
    'avg_aided_percent', 'avg_tau_ris', 'solved_count');

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