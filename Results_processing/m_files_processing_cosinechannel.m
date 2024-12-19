%% init
clearvars;
addpath('utils/','radio');
sim_folder = 'Sim_1/';
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

avg_tp_real_rate_vanilla  =zeros(n_dir,1);
avg_tp_real_rate_optimal  =zeros(n_dir,1);

violated_constraints_count = zeros(n_dir,1);
resolved_violations_count  = zeros(n_dir,1);

avg_violation_vanilla = zeros(n_dir,1);
max_violation_vanilla = 0;

avg_violation_optimal = zeros(n_dir,1);
max_violation_optimal = 0;

wb = waitbar(0);

for fldr = 1:numel(dir_name_list)
    %enter solution folders and get all the solved .mfiles
    disp(['Processing ' dir_name_list{fldr}]);
    waitbar(fldr/numel(dir_name_list),wb,dir_name_list{fldr});
    solutions = dir(['solved_instances/' sim_folder dir_name_list{fldr} '/solutions/' model_name '*.m']);
    
    if numel(solutions) < 30
        disp([dir_name_list{fldr} ' has ' num2str(30-numel(solutions)) ' unsolved instances']);
    end
    solved_count(fldr) = numel(solutions);
    
    distance_samples_count_covered = 0;
    distance_samples_count_uncovered = 0;
    
    %for each solution...
    for sol=1:numel(solutions)
        %run the solution
        run([solutions(sol).folder '/' solutions(sol).name]);
        avg_obj(fldr) = avg_obj(fldr) + obj;
        switch model_name
            case 'fakeris_maxavgrate'
                %load needed variables from the curresponding .mat file
                data_name = split(solutions(sol).name, '_'); %split the string
                data_name = data_name{end}; %get the run
                data_name = data_name(1:end-2); %truncate .m to get the .mat data name
                load(['solved_instances/' sim_folder dir_name_list{fldr} '/instances/' data_name],...
                    'donor_price', 'ris_price','n_tp','n_cs', 'cs_tp_distance_matrix',...
                    'cs_cs_distance_matrix', 'cs_cs_angles', 'cs_tp_angles', 'max_angle_span',...
                    'R_out_min');
                
                
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
                avg_donors(fldr) = avg_donors(fldr) + n_donors;
                avg_ris(fldr) = avg_ris(fldr) + n_ris;
                
                avg_aided_percent(fldr) = avg_aided_percent(fldr)+sum(s(:,:,end),[1 2]);
                
                %compute cost by multiplying number of ris and donors by price
                avg_cost(fldr) = avg_cost(fldr) +...
                    donor_price*n_donors + ris_price*n_ris;
                
                
                avg_tp_rate(fldr) = avg_tp_rate(fldr) + mean(R);
                avg_tot_rate(fldr) = avg_tot_rate(fldr) + obj;
                
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
                        avg_ris_min_dist(fldr) = avg_ris_min_dist(fldr) +...
                            min([...
                            cs_tp_distance_matrix(cov_donor, t)...
                            cs_tp_distance_matrix(cov_ris, t)...
                            ]);
                        avg_ris_distance(fldr) = avg_ris_distance(fldr)+ cs_tp_distance_matrix(cov_ris, t);
                        %disp(cs_tp_distance_matrix(cov_ris, t));
                        avg_covered_don_distance(fldr) = avg_covered_don_distance(fldr)+cs_tp_distance_matrix(cov_donor, t);
                        %increase sample count
                        distance_samples_count_covered = distance_samples_count_covered + 1;
                    elseif sum(s(t,:,:) ,[2 3]) > 0 %if tp is covered by a donor (with no min rout can be not covered)
                        avg_uncovered_don_dist(fldr) = avg_uncovered_don_dist(fldr)+cs_tp_distance_matrix(cov_donor, t);
                        distance_samples_count_uncovered = distance_samples_count_uncovered+1;
                    end
                end
                
                %avg tau ris
                avg_tau_ris(fldr) = mean(tau_ris(tau_ris > 0), 'all');
                
                
                % for each src
                % compute phi_t phi_r at the RIS
                % apply cosine power reduction
                % find actual mcs
                % compute final rates
                
                % compute the non-ideal rates
                %%
                vanilla_real_rates = zeros(n_tp,1)-1; %negative values will discriminate those tps covered by the fake ris
                for tp=1:n_tp
                    for don =1:n_cs-1
                        for ris=1:n_cs-1
                            if don==ris || ~s(tp,don,ris)
                                continue
                            end
                            %get angles
                            phi_inc = abs(cs_cs_angles(ris, don)-delta(ris));
                            phi_ref = abs(cs_tp_angles(ris, tp)-delta(ris));
                            
                            %get real_rates
                            vanilla_real_rates(tp) = src_rate(...
                                cs_tp_distance_matrix(don,tp),...
                                cs_cs_distance_matrix(don,ris),...
                                cs_tp_distance_matrix(ris,tp),...
                                phi_inc, phi_ref)...
                                .*tau_ris(tp,don,ris);
                            
                        end
                    end
                end
                vanilla_real_rates(vanilla_real_rates < 0) = R(vanilla_real_rates < 0);
                avg_tp_real_rate_vanilla(fldr) = avg_tp_real_rate_vanilla(fldr) + mean(vanilla_real_rates);
                
                %%
                %for all ris, compute the orientation movement freedom and
                %optmize it
                optimal_real_rates = vanilla_real_rates;
                optimized_delta = delta;
                
                for ris = 1:(n_cs-1)
                    if ~y_ris(ris)
                        continue;
                    end
                    touchy_tp = [];
                    clock_freedom = 360;
                    counterclock_freedom = 360;
                    for tp=1:n_tp
                        if sum(s(tp,:,ris),2)
                            
                            %find the serving donor
                            don = find(s(tp,:,ris));
                            
                            %update the clockwise and counterclockwise freedom
                            %right
                            clock_freedom = min([ clock_freedom...
                                delta(ris) + max_angle_span - max([cs_tp_angles(ris,tp) cs_cs_angles(ris,don)])]);
                            
                            counterclock_freedom = min([counterclock_freedom...
                                min([cs_tp_angles(ris,tp) cs_cs_angles(ris,don)]) - (delta(ris) - max_angle_span) ...
                                ]);
                            
                            % then if the tp is not satisfied, also add it
                            % to the touchy tps
                            if vanilla_real_rates(tp) < R_out_min
                                touchy_tp = [touchy_tp tp];
                            end
                        end
                    end
                    
                    %count the violations
                    violated_constraints_count(fldr) = violated_constraints_count(fldr) + numel(touchy_tp);
                    
                    %build the movements
                    clk_movement = -linspace(0, clock_freedom);
                    cnt_movement = linspace(0,counterclock_freedom);
                    
                    
                    %optimize
                    ris_tilt_optimization;
                    
                    %apply orient. offset
                    optimized_delta(ris) = optimized_delta(ris) + delta_offset;
                    
%                     if fldr==2
%                         disp("stop");
%                         disp(delta_offset);
%                     end
                    
                    %if the ris had any unsatisfied tp, add the number of
                    %satisfied tps after optimization to the satisfied
                    %count
                    if numel(touchy_tp) > 0
                        resolved_violations_count(fldr) = resolved_violations_count(fldr) + satisfied_tps;
                    end
                    
                    % recompute the involved tp rates if delta was
                    % optimized
                    if delta_offset ~= 0
                        for i=1:length(cov_t)
                            
                            tp = cov_t(i);
                            don = cov_d(i);
                            
                            phi_inc = abs(cs_cs_angles(ris, don)-(delta(ris)+delta_offset));
                            phi_ref = abs(cs_tp_angles(ris, tp)-(delta(ris)+delta_offset));
                            optimal_real_rates(tp) = src_rate(...
                                cs_tp_distance_matrix(don,tp),...
                                cs_cs_distance_matrix(don,ris),...
                                cs_tp_distance_matrix(ris,tp),...
                                phi_inc, phi_ref)...
                                .*tau_ris(tp,don,ris);
                            
                            
                        end
                    end
                    
                end
                
                avg_tp_real_rate_optimal(fldr) = avg_tp_real_rate_optimal(fldr) + mean(optimal_real_rates);
                
                % other statistics
                avg_violation_vanilla(fldr) = avg_violation_vanilla(fldr) +...
                    (R_out_min - mean(vanilla_real_rates(vanilla_real_rates < R_out_min)));
                max_violation_vanilla = max([ max_violation_vanilla, max(R_out_min - vanilla_real_rates(:))/R_out_min]);
                
                avg_violation_optimal(fldr) = avg_violation_optimal(fldr) +...
                    (R_out_min - mean(optimal_real_rates(optimal_real_rates < R_out_min)));
                max_violation_optimal = max([ max_violation_optimal, max(R_out_min - optimal_real_rates(:))/R_out_min]);
                
            case 'noris_maxavgrate'
                %load needed variables from the curresponding .mat file
                data_name = split(solutions(sol).name, '_'); %split the string
                data_name = data_name{end}; %get the run
                data_name = data_name(1:end-2); %truncate .m to get the .mat data name
                load(['solved_instances/' sim_folder dir_name_list{fldr} '/instances/' data_name],...
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
                avg_donors(fldr) = avg_donors(fldr) + n_donors;
                
                %compute cost by multiplying number of ris and donors by price
                avg_cost(fldr) = avg_cost(fldr) +...
                    donor_price*n_donors;
                
                
                avg_tp_rate(fldr) = avg_tp_rate(fldr) + mean(R);
                avg_tot_rate(fldr) = avg_tot_rate(fldr) + obj;
                
                
                for t=1:n_tp
                    if sum(x_don(t,:)) >0
                        cov_donor=...
                            ind2sub(size(squeeze(x_don(t,:))),find(squeeze(x_don(t,:))));
                        avg_uncovered_don_dist(fldr) = avg_uncovered_don_dist(fldr)+cs_tp_distance_matrix(cov_donor, t);
                        distance_samples_count_uncovered = distance_samples_count_uncovered+1;
                    end
                end
        end
        
        
        
    end
    %finish computing averages
    avg_donors(fldr) = avg_donors(fldr)/numel(solutions);
    avg_ris(fldr) = avg_ris(fldr)/numel(solutions);
    avg_cost(fldr) = avg_cost(fldr)/numel(solutions);
    avg_tp_rate(fldr) = avg_tp_rate(fldr)/numel(solutions);
    avg_tot_rate(fldr) = avg_tot_rate(fldr)/numel(solutions);
    
    avg_tp_real_rate_vanilla(fldr) = avg_tp_real_rate_vanilla(fldr)/numel(solutions);
    avg_tp_real_rate_optimal(fldr) = avg_tp_real_rate_optimal(fldr)/numel(solutions);
    
    avg_violation_vanilla(fldr) = avg_violation_vanilla(fldr)/numel(solutions);
    avg_violation_optimal(fldr) = avg_violation_optimal(fldr)/numel(solutions);
    
    avg_ris_min_dist(fldr) = avg_ris_min_dist(fldr)/distance_samples_count_covered;
    avg_ris_distance(fldr)=avg_ris_distance(fldr)/distance_samples_count_covered;
    avg_uncovered_don_dist(fldr)= avg_uncovered_don_dist(fldr)/distance_samples_count_uncovered;
    avg_covered_don_distance(fldr) = avg_covered_don_distance(fldr)/distance_samples_count_covered;
    
    avg_obj(fldr) = avg_obj(fldr)/numel(solutions);
    
    if numel(solutions)>0
        avg_aided_percent(fldr) = (n_tp - avg_aided_percent(fldr)/numel(solutions))/n_tp;
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

%%

%%
% 
% plot(str2num(char(ticks_labels)), avg_tp_rate, 'DisplayName', 'Ideal Rate');
% hold on;
% grid on;
% plot(str2num(char(ticks_labels)), avg_tp_real_rate_optimal, 'DisplayName','Real opt. rate');
% plot(str2num(char(ticks_labels)), avg_tp_real_rate_vanilla, 'DisplayName','Real rate');
% xlabel('Min. Rate [mbps]');
% ylabel('Avg UE Rate [mbps]');
% yyaxis right;
% aviol_vanilla = avg_violation_vanilla./[0:20:200]';
% aviol_optimal = avg_violation_optimal./[0:20:200]';
% plot(str2num(char(ticks_labels)), aviol_vanilla, 'DisplayName','Rel. violation - non-opt');
% plot(str2num(char(ticks_labels)), aviol_optimal, 'DisplayName','Rel. violation - opt');
% ylim([0 0.1]);
% legend();
% ylabel('Relative min.rate violation');
% 





