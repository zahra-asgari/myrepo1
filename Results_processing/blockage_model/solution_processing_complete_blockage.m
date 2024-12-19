%% init
%%FUNZIONA PER CAMPAGNA DEMAND MA SI ROMPE PER CAMPAGNA BUDGET, BISOGNA ADATTARE!!
clear;
addpath('utils/','cache/','scenarios/');
bar = 0;
%sim_folder = 'budget/';
sim_folder = 'remote_campaigns/blockagecampaign_peak_demand_sbz_journal_UL_NCR_100/';
%sim_folder = 'solved_instances/demand_campaign_peak/';
% common_string = 'complete_fixedDonor_blockageModel_';
comparenetworks=1;
model_id = {%'complete_fixedDonor_blockageModel_sum_mean';
            %'complete_fixedDonor_blockageModel_sd_sum_mean';
            %'complete_fixedDonor_blockageModel_fair_mean';
            %'complete_fixedDonor_blockageModel_sum_mean_for_peak';
            %'peak_complete_fixedDonor_blockageModel_fair_mean';
            'peak_complete_fixedDonor_blockageModel_sum_mean';
    };
for mod=1:numel(model_id)
    % model_name = [common_string model_id{mod}];
    disp(['Processing model ' model_id{mod}]);
    scenario_struct = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel();
    folder_names_root = 'hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel';
    %% open results folder and list files curresponding to the model
    directories = dir([sim_folder folder_names_root '*']);
    n_dir = numel(directories);
    peak_check = (contains(model_id{mod},'peak')) && not(contains(model_id{mod},'for_peak'));
    %nat sort forlder such that the are sorted in increasing parameter
    %variations
    dir_name_list = {directories.name};
    dir_name_list = natsort(dir_name_list, '\d+\.?\d*');


    %% execute some data processing for each folder, over all the runs in the folder

    avg_iab         = zeros(n_dir,1); % # of installed IAB nodes
    avg_ris         = zeros(n_dir,1); % # of installed RIS
    avg_ncr         = zeros(n_dir,1); % # of installed NCR
    avg_cost        = zeros(n_dir,1); % spent budget portion
    avg_dl_tp_rate  = zeros(n_dir,1); % avg downlink bitrate given to each TP to cover the minimum demand
    avg_ul_tp_rate  = zeros(n_dir,1); % avg uplink bitrate given to each TP to cover the minimum demand
    avg_dl_tp_full  = zeros(n_dir,1); % how much bitrate can a TP obtain if given all the remaining BS downlink timeslots
    avg_ul_tp_full  = zeros(n_dir,1); % how much bitrate can a TP obtain if given all the remaining BS uplink timeslots
    avg_dl_tp_min   = zeros(n_dir,1); %TP which has the lowest downlink bit rate
    avg_ul_tp_min   = zeros(n_dir,1); %TP which has the lowest uplink bit rate
    avg_acc_dist    = zeros(n_dir,1); % avg access link distance to see if model tries to shorten link: only direct count 1, 2-coverage counts 2
    avg_ang_div     = zeros(n_dir,1); % avg angular diversity for the links using the real rises
    avg_dir_users   = zeros(n_dir,1); % how many don't use any smart device
    avg_ris_users   = zeros(n_dir,1); % how many use ris
    avg_ncr_users   = zeros(n_dir,1); % how many use ncr
    avg_don_time    = zeros(n_dir,1); %how much the donor is used
    avg_iab_time    = zeros(n_dir,1); % how much installed iab nodes are used
    avg_ris_time    = zeros(n_dir,1); % how much installed ris are used
    avg_ncr_time    = zeros(n_dir,1); % how much installed ncr are used
    avg_solver_time = zeros(n_dir,1); % number of ms used by the solver to solve the problems
    avg_dl_ris_contrib = zeros(n_dir,1); %how much the presence of RIS impacts the overall downlink rate (for the users who use them)
    avg_dl_ncr_contrib = zeros(n_dir,1); %how much the presence of NCR impacts the overall downlink rate (for the users who use them)
    avg_ul_ris_contrib = zeros(n_dir,1); %how much the presence of RIS impacts the overall uplink rate (for the users who use them)
    avg_ul_ncr_contrib = zeros(n_dir,1); %how much the presence of NCR impacts the overall uplink rate (for the users who use them)
    avg_hop_number  = zeros(n_dir,1); % avg number of hop per user to reach the donor
    avg_donor_tps   = zeros(n_dir,1); % tps connected directly to the donor
    avg_node_tps   = zeros(n_dir,1); % avg tps connected to the IAB Nodes in the cell
    avg_node_degree = zeros(n_dir,1); % how many children IAB nodes a IAB node has
    avg_don_degree  = zeros(n_dir,1); %how many children the donor has
    avg_bh_length   = zeros(n_dir,1); % avg length of backhaul links in meters
    %bottleneck analysis structure
    bn.avg_accdon.DL   = zeros(n_dir,1);
    bn.avg_don.DL      = zeros(n_dir,1);
    bn.avg_acciab.DL   = zeros(n_dir,1);
    bn.avg_pathiab.DL  = zeros(n_dir,1);
    bn.avg_ris.DL      = zeros(n_dir,1);
    bn.avg_ncr.DL      = zeros(n_dir,1);
    bn.avg_accdon.UL   = zeros(n_dir,1);
    bn.avg_don.UL      = zeros(n_dir,1);
    bn.avg_acciab.UL   = zeros(n_dir,1);
    bn.avg_pathiab.UL  = zeros(n_dir,1);
    bn.avg_ris.UL      = zeros(n_dir,1);
    bn.avg_ncr.UL      = zeros(n_dir,1);
    peak_rate_sum   = NaN(n_dir,100); %matrix to associate each instance to the peak rate sum

    solved_count    = zeros(n_dir,1); % how many solved instances for scenario, useful for mean calculation, under half shadow the plot


    %it would be interesting to add how likely it is on average to use the
    %direct rate and the reflected rate (sum of probabilities), and the probability of the 16 states
    %(this could be done in preprocessing but in post-processing I could do it only on the 15 activated links)
    max_g = 0;
    mean_max_rate = 0;
    if bar
        wb = waitbar(0);
    end
     for d = 1:numel(dir_name_list)
   % for d = 101:101
        %enter solution folders and get all the solved .mfiles
        %    disp(['Processing ' dir_name_list{d}]);
        disp(['Current demand is ' num2str(scenario_struct.sim.R_dir_min(d)) ' mbps']);
        if bar
           waitbar(d/numel(dir_name_list),wb,[num2str(round(d/numel(dir_name_list)*100,1)) '%']);
        end
        solutions = dir([ sim_folder dir_name_list{d} '/solutions/' model_id{mod} '*.m']);

        if numel(solutions) < 100
            %    disp([dir_name_list{d} ' has ' num2str(100-numel(solutions)) ' unsolved instances']);
            if numel(solutions) == 0

                continue;

            end
        end
        solved_count(d) = numel(solutions);
        

        %for each solution...
        ris_instance = zeros(solved_count(d),1);
        ncr_instance = zeros(solved_count(d),1);
        for sol=1:numel(solutions)
            %disp(['Currently processing instance ' num2str(sol) ', budget ' num2str((d -1)*0.2)]); %i'v multiplied by 0.2 since it's the step between different budgets
            %run the solution
            run([solutions(sol).folder '/' solutions(sol).name]);

            %disp(['The overall traffic is ' num2str(allgs)]);


            %load needed variables from the curresponding .mat file
            data_name = split(solutions(sol).name, '_'); %split the string
            data_name = data_name{end}; %get the run
            data_name = data_name(4:end-2); %truncate .m and 'run' to get the .mat data name

            site_cache_id = DataHash([DataHash(scenario_struct.site) num2str(data_name)]); % hash is salted with rng_seed, since the site data is generated randomly
            radio_cache_id = DataHash([DataHash(scenario_struct.radio) site_cache_id]);
            site_cache_path = ['cache/' site_cache_id '.mat'];
            %site_cache_path = ['cache/instances before sbz probabilities correction/' site_cache_id '.mat'];
            radio_cache_path = ['cache/' radio_cache_id '.mat'];
            %radio_cache_path = ['cache/instances before sbz probabilities correction/' radio_cache_id '.mat'];
            if isfile(site_cache_path)
                load(site_cache_path,...
                    'cs_tp_distance_matrix','cs_cs_distance_matrix','smallest_angles','n_cs','n_tp','scenario');

            else
                disp("Site cache not found!!")
               	continue;

            end
            if isfile(radio_cache_path)
                load(radio_cache_path,...
                    'bh_rates','avg_rates','sd_rates','state_rates','state_probs','sd_better_mask');
                time_ratio.DL.ris = sum(state_probs.DL.*sd_better_mask.DL.ris,4);
                time_ratio.UL.ris = sum(state_probs.UL.*sd_better_mask.UL.ris,4); 
                time_ratio.DL.ncr = sum(state_probs.DL.*sd_better_mask.DL.ncr,4);
                time_ratio.UL.ncr = sum(state_probs.UL.*sd_better_mask.UL.ncr,4);

            else
                disp("Site cache not found!!")
                continue;

            end
            alpha = scenario_struct.sim.alpha;
            
                    if ~peak_check
                        allgdls = sum(nonzeros(g_dl));
                        if sum(g_dl,'all') > max_g
                            max_g = sum(g_dl,'all');
                            disp([[solutions(sol).name] ': ' num2str(max_g) ' Mbps']);
                        end
                        if (mean(nonzeros(g_dl))) > mean_max_rate
                            mean_max_rate = mean(nonzeros(g_dl));
                            disp(['New mean max rate is ' num2str(mean_max_rate)])
                        end
                    end

                    temp_acc_dist = 0;
                    temp_ang_div = 0;
                    
                    [ue,bs,sd,sdt] = ind2sub(size(x),find(x)); %find all SDs involved in an access connection x                   
                    % disp([ue,bs,sd,sdt])
                    sd_counter = zeros(n_cs,1);
                    sd_useless = [];
                    for ttt = 1:n_tp
                        if sdt(ttt) == 1 && sd(ttt) ~= 1
                            if all([time_ratio.DL.ris(ue(ttt),bs(ttt),sd(ttt)) time_ratio.UL.ris(ue(ttt),bs(ttt),sd(ttt))]==0)
                                sd_counter(sd(ttt)) = sd_counter(sd(ttt)) +1;
                            end
                        elseif sdt(ttt) == 2
                            if all([time_ratio.DL.ncr(ue(ttt),bs(ttt),sd(ttt)) time_ratio.UL.ncr(ue(ttt),bs(ttt),sd(ttt))]==0)
                                sd_counter(sd(ttt)) = sd_counter(sd(ttt)) +1;
                            end
                        end
                    end
                    for sdb=1:n_cs
                        if sd_counter(sdb)
                            a = find(sd == sdb);
                            if numel(a) == sd_counter(sdb)
                                % disp(['useless SD ' num2str(sdb)])
                                sd_useless = [sd_useless; sdb];
                            end
                        end
                    end
                    [tx_dl,rx_dl] = find(f_dl>1);
                    ris_idx = setdiff(unique(sd(sdt==1)),[1; sd_useless]);
                    ncr_idx = setdiff(unique(sd(sdt==2)),sd_useless);
                    iab_idx = unique([tx_dl rx_dl]);
                    if isrow(iab_idx)
                        iab_idx = iab_idx';
                    end
                    if sol==50
                        disp('');
                    end
                    tp_count=sum(iab_idx == bs',2);
                    temp_ris = numel(ris_idx); %all RIS (bar the fake one) that are actually used
                    temp_ncr = numel(ncr_idx); %all NCR that are actually used
                    temp_iab = numel(setdiff(iab_idx,n_cs)); %find all the IAB nodes with traffic flowing into them.
                    %Since now we have also uplink, the donor must be removed from the set
                    %When the budget is high, the solver buys iab nodes indiscriminately but then it doesn't use them
                    temp_ris_users = 0;
                    temp_ncr_users = 0;
                    temp_dir_users = 0;

                    temp_bh_length = 0;
                    bh_link_count = 0;

                    avg_cost(d) = avg_cost(d) + temp_iab*scenario.sim.iab_price + temp_ris*scenario.sim.ris_price + temp_ncr*scenario.sim.af_price;
                    avg_solver_time(d) = avg_solver_time(d) + time;
                    all_bh_links = z(iab_idx,iab_idx) + z(iab_idx,iab_idx)';
                    degree = sum(all_bh_links,2); %count only the links that go towards actually used nodes
                    if not(isempty(degree)) %at least one IAB Node bought
                        avg_node_degree(d) = avg_node_degree(d) + sum(degree(1:end-1))/temp_iab;
                        avg_don_degree(d) = avg_don_degree(d) + degree(end);
                    end
                    if not(isempty(tp_count))
                        avg_node_degree(d) = avg_node_degree(d) + sum(tp_count(1:end-1))/temp_iab;
                        avg_don_degree(d) = avg_don_degree(d) + tp_count(end);
                        avg_donor_tps(d) = avg_donor_tps(d) + tp_count(end);
                        avg_node_tps(d) = avg_node_tps(d) + + sum(tp_count(1:end-1))/temp_iab;
                    end
                    iab_occupation_time_dl = zeros(n_cs,1);
                    iab_occupation_time_ul = zeros(n_cs,1);
                    ris_occupation_time_dl = zeros(n_cs,1);
                    ris_occupation_time_ul = zeros(n_cs,1);
                    ncr_occupation_time_dl = zeros(n_cs,1);
                    ncr_occupation_time_ul = zeros(n_cs,1);
                    ris_dl_contribute = zeros(n_tp,1);
                    ncr_dl_contribute = zeros(n_tp,1);
                    ris_ul_contribute = zeros(n_tp,1);
                    ncr_ul_contribute = zeros(n_tp,1);
                    path = cell(n_tp,6); %cell structure for recreating the backwards path from each TP to the Donor. It is needed to find the bottleneck in the network and
                    %calculate how much additional
                    %cell structure: 1 - hops; 2 - peak DL; 3 - peak UL; 
                    % 4 - type of SD; 5 - bn DL; 6 - bn UL.
                    %througput can be given to the TP

                    for t=1:n_tp

                        [~, iab, sd, type] = ind2sub(size(x(t,:,:,:)), find(x(t,:,:,:)));
                        path{t,1} = [path{t,1} iab];
                        path = find_parent(t,path,z,n_cs);
                        path{t,4} = type;
                        path{t,5} = 'N/A';
                        path{t,6} = 'N/A';

                    end
                    if peak_check
                        min_acc_traff_dl = alpha*scenario_struct.sim.R_dir_min(d);
                        min_acc_traff_ul = (1-alpha)*scenario_struct.sim.R_dir_min(d);
                        
                    else
                        min_acc_traff_dl = min(g_dl(g_dl>1));
                        min_acc_traff_ul = min(g_ul(g_ul>1));
                        
                    end
                    avg_dl_tp_min(d) = avg_dl_tp_min(d) + min_acc_traff_dl;
                    avg_ul_tp_min(d) = avg_ul_tp_min(d) + min_acc_traff_ul;

                    for c=1:n_cs

                        for c2=1:n_cs
                            bh_counter = sum(cellfun(@(m)ismember(c2,m),path(:,1)));
                            if f_dl(c,c2)>1
                				bh_link_count = bh_link_count +1;
                                temp_bh_length = temp_bh_length + cs_cs_distance_matrix(c,c2);
                                if peak_check
                                    iab_occupation_time_dl([c c2]) = iab_occupation_time_dl([c c2]) + ...
                                    calc_occ(bh_rates(c,c2),bh_counter,alpha*scenario_struct.sim.R_dir_min(d));
                                    iab_occupation_time_ul([c c2]) = iab_occupation_time_ul([c c2]) + ...
                                    calc_occ(bh_rates(c2,c),bh_counter,(1-alpha)*scenario_struct.sim.R_dir_min(d));
                                else
                                iab_occupation_time_dl([c c2]) = iab_occupation_time_dl([c c2]) + ...
                                    calc_occ(bh_rates(c,c2),bh_counter,alpha*scenario_struct.sim.R_dir_min(d),comparenetworks,f_dl(c,c2));
                                iab_occupation_time_ul([c c2]) = iab_occupation_time_ul([c c2]) + ...
                                    calc_occ(bh_rates(c2,c),bh_counter,(1-alpha)*scenario_struct.sim.R_dir_min(d),comparenetworks,f_ul(c2,c));
                                end
                            end
                            for t=1:n_tp

                                if x(t,c,c2,path{t,4})==1
                                    if path{t,4} == 1
                                        if peak_check
                                        iab_occupation_time_dl(c) = iab_occupation_time_dl(c) + calc_occ(avg_rates.DL.ris(t,c,c2),1,...
                                            alpha*scenario_struct.sim.R_dir_min(d));
                                        iab_occupation_time_ul(c) = iab_occupation_time_ul(c) + calc_occ(avg_rates.UL.ris(t,c,c2),1,...
                                            (1-alpha)*scenario_struct.sim.R_dir_min(d));
                                        else
                                            iab_occupation_time_dl(c) = iab_occupation_time_dl(c) + calc_occ(avg_rates.DL.ris(t,c,c2),1,...
                                            alpha*scenario_struct.sim.R_dir_min(d),comparenetworks,g_dl(t,c,c2,path{t,4}));
                                        iab_occupation_time_ul(c) = iab_occupation_time_ul(c) + calc_occ(avg_rates.UL.ris(t,c,c2),1,...
                                            (1-alpha)*scenario_struct.sim.R_dir_min(d),comparenetworks,g_ul(t,c,c2,path{t,4}));
                                        end
                                    elseif path{t,4} == 2
                                        if peak_check
                                            iab_occupation_time_dl(c) = iab_occupation_time_dl(c) + calc_occ(avg_rates.DL.ncr(t,c,c2),1,...
                                                alpha*scenario_struct.sim.R_dir_min(d));
                                            iab_occupation_time_ul(c) = iab_occupation_time_ul(c) + calc_occ(avg_rates.UL.ncr(t,c,c2),1,...
                                                (1-alpha)*scenario_struct.sim.R_dir_min(d));
                                        else
                                            iab_occupation_time_dl(c) = iab_occupation_time_dl(c) + calc_occ(avg_rates.DL.ncr(t,c,c2),1,...
                                                alpha*scenario_struct.sim.R_dir_min(d),comparenetworks,g_dl(t,c,c2,path{t,4}));
                                            iab_occupation_time_ul(c) = iab_occupation_time_ul(c) + calc_occ(avg_rates.UL.ncr(t,c,c2),1,...
                                                (1-alpha)*scenario_struct.sim.R_dir_min(d),comparenetworks,g_ul(t,c,c2,path{t,4}));
                                        end
                                    else
                                        error("unexpected SD index!");
                                    end
                                    if peak_check
                                        avg_dl_tp_rate(d) = avg_dl_tp_rate(d) + alpha*scenario_struct.sim.R_dir_min(d);
                                        avg_ul_tp_rate(d) = avg_ul_tp_rate(d) + (1-alpha)*scenario_struct.sim.R_dir_min(d);
                                    else
                                        avg_dl_tp_rate(d) = avg_dl_tp_rate(d) + g_dl(t,c,c2,path{t,4});
                                        avg_ul_tp_rate(d) = avg_ul_tp_rate(d) + g_ul(t,c,c2,path{t,4});
                                    end
                                    if all(c2~=[1; sd_useless])
                                        if path{t,4} == 1
                                            if peak_check
                                                ris_occupation_time_dl(c2) = ris_occupation_time_dl(c2) + calc_occ(sd_rates.DL.ris(t,c,c2),1,...
                                                    alpha*scenario_struct.sim.R_dir_min(d));
                                                ris_occupation_time_ul(c2) = ris_occupation_time_ul(c2) + calc_occ(sd_rates.UL.ris(t,c,c2),1,...
                                                    (1-alpha)*scenario_struct.sim.R_dir_min(d));
                                            else
                                                ris_occupation_time_dl(c2) = ris_occupation_time_dl(c2) + calc_occ(sd_rates.DL.ris(t,c,c2),1,...
                                                    alpha*scenario_struct.sim.R_dir_min(d),comparenetworks,g_dl(t,c,c2,path{t,4}));
                                                ris_occupation_time_ul(c2) = ris_occupation_time_ul(c2) + calc_occ(sd_rates.UL.ris(t,c,c2),1,...
                                                    (1-alpha)*scenario_struct.sim.R_dir_min(d),comparenetworks,g_ul(t,c,c2,path{t,4}));
                                            end
                                            if avg_rates.DL.ris(t,c,1) > 0
                                                ris_dl_contribute(t) = (avg_rates.DL.ris(t,c,c2) - avg_rates.DL.ris(t,c,1))/avg_rates.DL.ris(t,c,1);
                                            end
                                            if avg_rates.UL.ris(t,c,1) > 0
                                                ris_ul_contribute(t) = (avg_rates.UL.ris(t,c,c2) - avg_rates.UL.ris(t,c,1))/avg_rates.UL.ris(t,c,1);
                                            end
                                            temp_ris_users = temp_ris_users + 1;
                                        elseif path{t,4} == 2
                                            if peak_check
                                                ncr_occupation_time_dl(c2) = ncr_occupation_time_dl(c2) + calc_occ(sd_rates.DL.ncr(t,c,c2),1,...
                                                    alpha*scenario_struct.sim.R_dir_min(d));
                                                ncr_occupation_time_ul(c2) = ncr_occupation_time_ul(c2) + calc_occ(sd_rates.UL.ncr(t,c,c2),1,...
                                                    (1-alpha)*scenario_struct.sim.R_dir_min(d));
                                            else
                                                ncr_occupation_time_dl(c2) = ncr_occupation_time_dl(c2) + calc_occ(sd_rates.DL.ncr(t,c,c2),1,...
                                                    alpha*scenario_struct.sim.R_dir_min(d),comparenetworks,g_dl(t,c,c2,path{t,4}));
                                                ncr_occupation_time_ul(c2) = ncr_occupation_time_ul(c2) + calc_occ(sd_rates.UL.ncr(t,c,c2),1,...
                                                    (1-alpha)*scenario_struct.sim.R_dir_min(d),comparenetworks,g_ul(t,c,c2,path{t,4}));
                                            end
                                            if avg_rates.DL.ris(t,c,1) > 0
                                                ncr_dl_contribute(t) = (avg_rates.DL.ncr(t,c,c2) - avg_rates.DL.ris(t,c,1))/avg_rates.DL.ris(t,c,1);
                                            end
                                            if avg_rates.UL.ris(t,c,1) > 0
                                                ncr_ul_contribute(t) = (avg_rates.UL.ncr(t,c,c2) - avg_rates.UL.ris(t,c,1))/avg_rates.UL.ris(t,c,1);
                                            end
                                            temp_ncr_users = temp_ncr_users + 1;
                                        end

                                        %disp(['The RIS contribute for user ' num2str(t) ' is +' num2str(ris_contribute(t)*100) '%']);

                                        temp_acc_dist = temp_acc_dist + cs_tp_distance_matrix(c,t) + cs_tp_distance_matrix(c2,t);
                                        temp_ang_div = temp_ang_div + smallest_angles(t,c,c2);

                                    else
                                        temp_dir_users = temp_dir_users + 1;
                                        temp_acc_dist = temp_acc_dist + cs_tp_distance_matrix(c,t);

                                    end

                                end

                            end


                        end

                    end
                    
                    ris_occupation_time_dl = min(ris_occupation_time_dl,alpha); %limit to alpha the occupation rate
                    ncr_occupation_time_dl = min(ncr_occupation_time_dl,alpha);
                    ris_occupation_time_ul = min(ris_occupation_time_ul,1-alpha);
                    ncr_occupation_time_ul = min(ncr_occupation_time_ul,1-alpha);

                    avg_ris(d) = avg_ris(d) + temp_ris;
                    avg_iab(d) = avg_iab(d) + temp_iab;
                    avg_ncr(d) = avg_ncr(d) + temp_ncr;
                    avg_bh_length(d) = avg_bh_length(d) + temp_bh_length/bh_link_count;

                    avg_acc_dist(d) = avg_acc_dist(d) + temp_acc_dist/(temp_ris_users*2 + temp_ncr_users*2 + temp_dir_users);
                    if (temp_ris_users + temp_ncr_users~=0)
                        avg_ang_div(d) = avg_ang_div(d) + temp_ang_div/(temp_ris_users + temp_ncr_users);
                        avg_ris_users(d) = avg_ris_users(d) + temp_ris_users;
                        avg_ncr_users(d) = avg_ncr_users(d) + temp_ncr_users;
                        if temp_ris_users > 0
                            ris_instance(sol) = 1;
                            avg_dl_ris_contrib(d) = avg_dl_ris_contrib(d) + sum(ris_dl_contribute)/temp_ris_users;
                            avg_ul_ris_contrib(d) = avg_ul_ris_contrib(d) + sum(ris_ul_contribute)/temp_ris_users;
                        end
                        if temp_ncr_users > 0
                            ncr_instance(sol) = 1;
                            avg_dl_ncr_contrib(d) = avg_dl_ncr_contrib(d) + sum(ncr_dl_contribute)/temp_ncr_users;
                            avg_ul_ncr_contrib(d) = avg_ul_ncr_contrib(d) + sum(ncr_ul_contribute)/temp_ncr_users;
                        end
                    end
                    avg_dir_users(d) = avg_dir_users(d) + temp_dir_users;
                    if temp_iab~=0
                        avg_iab_time(d) = avg_iab_time(d) + (sum([iab_occupation_time_dl(2:end-1);iab_occupation_time_ul(2:end-1)]))/temp_iab;
                    end
                    avg_don_time(d) = avg_don_time(d) + iab_occupation_time_dl(end) + iab_occupation_time_ul(end);
                    if temp_ris~=0
                        avg_ris_time(d) = avg_ris_time(d) + (sum([ris_occupation_time_dl(2:end-1);ris_occupation_time_ul(2:end-1)]))/temp_ris;
                    end
                    if temp_ncr~=0
                        avg_ncr_time(d) = avg_ncr_time(d) + (sum([ncr_occupation_time_dl(2:end-1);ncr_occupation_time_ul(2:end-1)]))/temp_ncr;
                    end

                    iab_free_time_dl = alpha - iab_occupation_time_dl;
                    iab_free_time_ul = 1 - alpha - iab_occupation_time_ul;
                    ris_free_time_dl = alpha - ris_occupation_time_dl;
                    ris_free_time_ul = 1 - alpha - ris_occupation_time_ul;
                    ncr_free_time_dl = alpha - ncr_occupation_time_dl;
                    ncr_free_time_ul = 1 - alpha - ncr_occupation_time_ul;
                    %disp(iab_free_time)

                    for t=1:n_tp

                        [~, iab, sd, sdt] = ind2sub(size(x(t,:,:,:)), find(x(t,:,:,:)));
                        avg_hop_number(d) = avg_hop_number(d) + numel(path{t,1});
                        if peak_check || (~peak_check && comparenetworks)
                            acc_traff_dl = alpha*scenario_struct.sim.R_dir_min(d);
                            acc_traff_ul = (1-alpha)*scenario_struct.sim.R_dir_min(d);

                        else
                            acc_traff_dl = g_dl(t,iab,sd,sdt);
                            acc_traff_ul = g_ul(t,iab,sd,sdt);

                        end
                        if numel(path{t,1})==1
                            if all(sd~=[1; sd_useless])
                                switch sdt
                                    case 1
                                        [path{t,2},bn_dl] = min([iab_free_time_dl(iab)*avg_rates.DL.ris(t,iab,sd), sd_rates.DL.ris(t,iab,sd)*time_ratio.DL.ris(t,iab,sd) - acc_traff_dl]); %DL
                                        [path{t,3},bn_ul] = min([iab_free_time_ul(iab)*avg_rates.UL.ris(t,iab,sd), sd_rates.UL.ris(t,iab,sd)*time_ratio.UL.ris(t,iab,sd) - acc_traff_ul]); %UL
                                        path{t,5} = bn_eval(bn_dl,["Access Donor TDM";"RIS TDM"]);
                                        path{t,6} = bn_eval(bn_ul,["Access Donor TDM";"RIS TDM"]);
                                    case 2
                                        [path{t,2},bn_dl] = min([iab_free_time_dl(iab)*avg_rates.DL.ncr(t,iab,sd), sd_rates.DL.ncr(t,iab,sd)*time_ratio.DL.ncr(t,iab,sd) - acc_traff_dl]); %DL
                                        [path{t,3},bn_ul] = min([iab_free_time_ul(iab)*avg_rates.UL.ncr(t,iab,sd), sd_rates.UL.ncr(t,iab,sd)*time_ratio.UL.ncr(t,iab,sd) - acc_traff_ul]); %UL
                                        path{t,5} = bn_eval(bn_dl,["Access Donor TDM";"NCR TDM"]);
                                        path{t,6} = bn_eval(bn_ul,["Access Donor TDM";"NCR TDM"]);
                                end

                            else
                                path{t,2} = iab_free_time_dl(iab)*avg_rates.DL.ris(t,iab,1);
                                path{t,3} = iab_free_time_ul(iab)*avg_rates.UL.ris(t,iab,1);
                                path{t,5} = "Access Donor TDM";
                                path{t,6} = "Access Donor TDM";
                            end
                        else
                            for seq=1:numel(path{t,1})
                                current = path{t,1}(seq);
                                if seq == 1
                                    next = path{t,1}(seq +1);
                                    switch sdt
                                        case 1
                                            access_sum_dl = (iab_free_time_dl(current)*bh_rates(next,current)*avg_rates.DL.ris(t,iab,sd))/(bh_rates(next,current)+avg_rates.DL.ris(t,iab,sd));
                                            access_sum_ul = (iab_free_time_ul(current)*bh_rates(current,next)*avg_rates.UL.ris(t,iab,sd))/(bh_rates(current,next)+avg_rates.UL.ris(t,iab,sd));
                                        case 2
                                            access_sum_dl = (iab_free_time_dl(current)*bh_rates(next,current)*avg_rates.DL.ncr(t,iab,sd))/(bh_rates(next,current)+avg_rates.DL.ncr(t,iab,sd));
                                            access_sum_ul = (iab_free_time_ul(current)*bh_rates(current,next)*avg_rates.UL.ncr(t,iab,sd))/(bh_rates(current,next)+avg_rates.UL.ncr(t,iab,sd));
                                    end
                                    if all(sd~=[1; sd_useless])
                                        if comparenetworks
                                            switch sdt
                                                case 1
                                                    [limit_acc_dl,bn_dl] = min([access_sum_dl, sd_rates.DL.ris(t,iab,sd)*time_ratio.DL.ris(t,iab,sd) - acc_traff_dl]);
                                                    [limit_acc_ul,bn_ul] = min([access_sum_ul, sd_rates.UL.ris(t,iab,sd)*time_ratio.UL.ris(t,iab,sd) - acc_traff_ul]);
                                                    path{t,5} = bn_eval(bn_dl,["Access IAB TDM";"RIS TDM"]);
                                                    path{t,6} = bn_eval(bn_ul,["Access IAB TDM";"RIS TDM"]);
                                                case 2
                                                    [limit_acc_dl,bn_dl] = min([access_sum_dl, sd_rates.DL.ncr(t,iab,sd)*time_ratio.DL.ncr(t,iab,sd) - acc_traff_dl]);
                                                    [limit_acc_ul,bn_ul] = min([access_sum_ul, sd_rates.UL.ncr(t,iab,sd)*time_ratio.UL.ncr(t,iab,sd) - acc_traff_ul]);
                                                    path{t,5} = bn_eval(bn_dl,["Access IAB TDM";"NCR TDM"]);
                                                    path{t,6} = bn_eval(bn_ul,["Access IAB TDM";"NCR TDM"]);
                                            end
                                        else
                                            switch sdt
                                                case 1
                                                    [limit_acc_dl,bn_dl] = min([access_sum_dl, sd_rates.DL.ris(t,iab,sd)*time_ratio.DL.ris(t,iab,sd) - alpha*scenario_struct.sim.R_dir_min(d)]);
                                                    [limit_acc_ul,bn_ul] = min([access_sum_ul, sd_rates.UL.ris(t,iab,sd)*time_ratio.UL.ris(t,iab,sd) - (1-alpha)*scenario_struct.sim.R_dir_min(d)]);
                                                    path{t,5} = bn_eval(bn_dl,["Access IAB TDM";"RIS TDM"]);
                                                    path{t,6} = bn_eval(bn_ul,["Access IAB TDM";"RIS TDM"]);
                                                case 2
                                                    [limit_acc_dl,bn_dl] = min([access_sum_dl, sd_rates.DL.ncr(t,iab,sd)*time_ratio.DL.ncr(t,iab,sd) - alpha*scenario_struct.sim.R_dir_min(d)]);
                                                    [limit_acc_ul,bn_ul] = min([access_sum_ul, sd_rates.UL.ncr(t,iab,sd)*time_ratio.UL.ncr(t,iab,sd) - (1-alpha)*scenario_struct.sim.R_dir_min(d)]);
                                                    path{t,5} = bn_eval(bn_dl,["Access IAB TDM";"NCR TDM"]);
                                                    path{t,6} = bn_eval(bn_ul,["Access IAB TDM";"NCR TDM"]);
                                            end
                                        end
                                    else
                                        limit_acc_dl = access_sum_dl;
                                        limit_acc_ul = access_sum_ul;
                                        path{t,5} = "Access IAB TDM";
                                        path{t,6} = "Access IAB TDM";
                                    end

                                    path{t,2} = limit_acc_dl;
                                    path{t,3} = limit_acc_ul;
                                    % disp(path(t,:));

                                elseif seq == numel(path{t,1})
                                    previous = path{t,1}(seq -1);
                                    [path{t,2},bn_dl] = min([path{t,2}, iab_free_time_dl(current)*bh_rates(current,previous)]);
                                    [path{t,3},bn_ul] = min([path{t,3}, iab_free_time_ul(current)*bh_rates(previous,current)]);
                                    path{t,5} = bn_eval(bn_dl,[path{t,5};"Donor TDM"]);
                                    path{t,6} = bn_eval(bn_ul,[path{t,6};"Donor TDM"]);
                                else
                                    next = path{t,1}(seq +1);
                                    previous = path{t,1}(seq -1);
                                    limit_bh_dl = (iab_free_time_dl(current)*bh_rates(current,previous)*bh_rates(next,current))/(bh_rates(current,previous)+bh_rates(next,current));
                                    limit_bh_ul = (iab_free_time_ul(current)*bh_rates(previous,current)*bh_rates(current,next))/(bh_rates(previous,current)+bh_rates(current,next));

                                    [path{t,2},bn_dl] = min([path{t,2} limit_bh_dl]);
                                    [path{t,3},bn_ul] = min([path{t,3} limit_bh_ul]);
                                    path{t,5} = bn_eval(bn_dl,[path{t,5};"Path IAB TDM"]);
                                    path{t,6} = bn_eval(bn_ul,[path{t,6};"Path IAB TDM"]);

                                end
                            end
                        end
                    end

                    for t=1:n_tp

                        avg_dl_tp_full(d) = avg_dl_tp_full(d) + path{t,2};
                        avg_ul_tp_full(d) = avg_ul_tp_full(d) + path{t,3};

                    end
                    bn.avg_accdon.DL(d)   = bn.avg_accdon.DL(d) + sum([path{:,5}] == "Access Donor TDM");
                    bn.avg_accdon.UL(d)   = bn.avg_accdon.UL(d) + sum([path{:,6}] == "Access Donor TDM");
                    bn.avg_don.DL(d)      = bn.avg_don.DL(d) + sum([path{:,5}] == "Donor TDM");
                    bn.avg_don.UL(d)      = bn.avg_don.UL(d) + sum([path{:,6}] == "Donor TDM");
                    bn.avg_acciab.DL(d)   = bn.avg_acciab.DL(d) + sum([path{:,5}] == "Access IAB TDM");
                    bn.avg_acciab.UL(d)   = bn.avg_acciab.UL(d) + sum([path{:,6}] == "Access IAB TDM");
                    bn.avg_pathiab.DL(d)  = bn.avg_pathiab.DL(d) + sum([path{:,5}] == "Path IAB TDM");
                    bn.avg_pathiab.UL(d)  = bn.avg_pathiab.UL(d) + sum([path{:,6}] == "Path IAB TDM");
                    bn.avg_ris.DL(d)      = bn.avg_ris.DL(d) + sum([path{:,5}] == "RIS TDM");
                    bn.avg_ris.UL(d)      = bn.avg_ris.UL(d) + sum([path{:,6}] == "RIS TDM");
                    bn.avg_ncr.DL(d)      = bn.avg_ncr.DL(d) + sum([path{:,5}] == "NCR TDM");
                    bn.avg_ncr.UL(d)      = bn.avg_ncr.UL(d) + sum([path{:,6}] == "NCR TDM");
		    peak_rate_sum(d,str2double(data_name))   = sum(cellfun(@sum,path(:,2)));


        end
        %finish computing averages

        avg_ris(d) = avg_ris(d)/numel(solutions);
        avg_ncr(d) = avg_ncr(d)/numel(solutions);
        avg_iab(d) = avg_iab(d)/numel(solutions);
        avg_cost(d) = avg_cost(d)/numel(solutions);
        avg_dl_tp_full(d) = avg_dl_tp_full(d)/(numel(solutions)*n_tp);
        avg_ul_tp_full(d) = avg_ul_tp_full(d)/(numel(solutions)*n_tp);
        avg_dl_tp_rate(d) = avg_dl_tp_rate(d)/(numel(solutions)*n_tp);
        avg_ul_tp_rate(d) = avg_ul_tp_rate(d)/(numel(solutions)*n_tp);
        avg_dl_tp_min(d) = avg_dl_tp_min(d)/numel(solutions);
        avg_ul_tp_min(d) = avg_ul_tp_min(d)/numel(solutions);
        avg_acc_dist(d) = avg_acc_dist(d)/numel(solutions);
        avg_ang_div(d) = avg_ang_div(d)/sum(any([ris_instance ncr_instance],2));
        avg_dl_ris_contrib(d) = avg_dl_ris_contrib(d)/sum(ris_instance);
        avg_ul_ris_contrib(d) = avg_ul_ris_contrib(d)/sum(ris_instance);
        avg_dl_ncr_contrib(d) = avg_dl_ncr_contrib(d)/sum(ncr_instance);
        avg_ul_ncr_contrib(d) = avg_ul_ncr_contrib(d)/sum(ncr_instance);
        avg_ris_users(d)= avg_ris_users(d)/numel(solutions);
        avg_ncr_users(d)= avg_ncr_users(d)/numel(solutions);
        avg_dir_users(d) = avg_dir_users(d)/numel(solutions);
        avg_iab_time(d) = avg_iab_time(d)/numel(solutions);
        avg_don_time(d) = avg_don_time(d)/numel(solutions);
        avg_ris_time(d) = avg_ris_time(d)/sum(ris_instance);
        avg_ncr_time(d) = avg_ncr_time(d)/sum(ncr_instance);   
        avg_solver_time(d) = avg_solver_time(d)/numel(solutions);
        avg_hop_number(d) = avg_hop_number(d)/(numel(solutions)*n_tp);
        avg_don_degree(d) = avg_don_degree(d)/numel(solutions);
        avg_donor_tps(d) = avg_donor_tps(d)/numel(solutions);
        avg_node_tps(d) = avg_node_tps(d)/numel(solutions);
        avg_node_degree(d) = avg_node_degree(d)/numel(solutions); 
        avg_bh_length(d) = avg_bh_length(d)/numel(solutions);
        bn.avg_acciab.DL(d)    = bn.avg_acciab.DL(d)/numel(solutions);
        bn.avg_accdon.DL(d)    = bn.avg_accdon.DL(d)/numel(solutions);
        bn.avg_pathiab.DL(d)   = bn.avg_pathiab.DL(d)/numel(solutions);
        bn.avg_don.DL(d)       = bn.avg_don.DL(d)/numel(solutions);
        bn.avg_ris.DL(d)       = bn.avg_ris.DL(d)/numel(solutions);
        bn.avg_ncr.DL(d)       = bn.avg_ncr.DL(d)/numel(solutions);
        bn.avg_acciab.UL(d)    = bn.avg_acciab.UL(d)/numel(solutions);
        bn.avg_accdon.UL(d)    = bn.avg_accdon.UL(d)/numel(solutions);
        bn.avg_pathiab.UL(d)   = bn.avg_pathiab.UL(d)/numel(solutions);
        bn.avg_don.UL(d)       = bn.avg_don.UL(d)/numel(solutions);
        bn.avg_ris.UL(d)       = bn.avg_ris.UL(d)/numel(solutions);
        bn.avg_ncr.UL(d)       = bn.avg_ncr.UL(d)/numel(solutions);
    end
    if bar
        waitbar(1,wb,'Saving...');
        pause(1)
    end

    %get the x ticks by splitting the folder names and getting the varying
    %parameter

    ticks_labels = split([directories.name], '_');
    ticks_labels = ticks_labels(7:7:end);
    ticks_labels = natsort(cellfun(@(ticks)ticks(:,14:end), ticks_labels, 'uni', false));
    %% save results
    if ~exist(['Mat_files_solutions/' sim_folder 'mat_results/'], 'dir')

        mkdir(['Mat_files_solutions/' sim_folder 'mat_results/']);

    end

 

    save(['Mat_files_solutions/' sim_folder ['mat_results/results_' model_id{mod}]], 'avg_ris', 'avg_iab', 'avg_ncr','avg_cost',...
        'avg_dl_tp_full', 'avg_ul_tp_full','avg_dl_tp_rate','avg_ul_tp_rate','avg_dl_tp_min','avg_ul_tp_min','avg_acc_dist', 'avg_ang_div','solved_count', 'ticks_labels',...
        'avg_ris_users', 'avg_dir_users', 'avg_ncr_users','avg_iab_time', 'avg_ris_time', 'avg_ncr_time','avg_don_time','avg_solver_time','avg_dl_ris_contrib','avg_ul_ris_contrib',...
        'avg_dl_ncr_contrib','avg_ul_ncr_contrib','avg_hop_number','avg_donor_tps','avg_node_tps','avg_don_degree','avg_node_degree','avg_bh_length','bn','peak_rate_sum');
    if bar
         waitbar(1,wb,'Done');
         pause(1)
    
         close(wb)
    end
    %  clearvars -except model_id sim_folder common_string comparenetworks
end


function path = find_parent(tp, path, z,n_cs)

current_parent = path{tp,1}(end);
if current_parent==n_cs
    %do nothing
else

    [next_parent, ~] = ind2sub(size(z(:,current_parent)), find(z(:,current_parent)));
    path{tp,1}=[path{tp,1} next_parent];
    path = find_parent(tp,path,z,n_cs);
end


end

function current_occ = calc_occ(rate,bh_counter,min,compare,traffic)
if nargin == 3
    compare = 1;
end
current_occ = 0;
if compare

    if not(isinf(rate))
        current_occ = current_occ + bh_counter*min/rate;
    end

else

    if not(isinf(rate))
        current_occ = current_occ + traffic/rate;
    end

end

end

function resp = bn_eval(opt,labels)

resp = labels(opt);

end
