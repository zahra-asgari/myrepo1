%% init
clear;
addpath('utils/','cache/','scenarios/');
%sim_folder = 'budget/';
%sim_folder = 'remote_campaigns/blockagecampaign_small_highD/';
sim_folder = 'solved_instances/avg_100/';
common_string = 'iab_ris_fixedDonor_fakeRis_blockageModel_';
dontcomparenetworks=0;
model_id = {%'maxminMCS';
            %'minmaxt';
            %'sumairtime';
            %'sumall';
            %'sumfree';
            %'sumMCS';
            %'sumextra';
            %'sumlen';
            %'minmaxlen';
            %'sumfreeMCS';
            %'sumfreeabs';
            'sumrate';
            %'maxminrate';
            % 'sumrateforextra';
};
for mod=1:numel(model_id)
    model_name = [common_string model_id{mod}];
    disp(['Processing model ' model_name]);
    scenario_struct = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel();
    folder_names_root = 'hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel';
    %% open results folder and list files curresponding to the model
    directories = dir([sim_folder folder_names_root '*']);
    n_dir = numel(directories);

    %nat sort forlder such that the are sorted in increasing parameter
    %variations
    dir_name_list = {directories.name};
    dir_name_list = natsort(dir_name_list, '\d+\.?\d*');


    %% execute some data processing for each folder, over all the runs in the folder

    avg_iab         = zeros(n_dir,1); % # of installed IAB nodes
    avg_ris         = zeros(n_dir,1); % # of installed RIS
    avg_cost        = zeros(n_dir,1); % spent budget portion
    avg_tp_rate     = zeros(n_dir,1); % avg bitrate given to each TP to cover the minimum demand (100 for direct, 50 for ris)
    avg_tp_full     = zeros(n_dir,1); % how much bitrate can a TP obtain if given all the remaining BS timeslots
    avg_tp_min      = zeros(n_dir,1); %TP which has the lowest bit rate
    avg_acc_dist    = zeros(n_dir,1); % avg access link distance to see if model tries to shorten link: only direct count 1, 2-coverage counts 2
    avg_ang_div     = zeros(n_dir,1); % avg angular diversity for the links using the real rises
    avg_dir_users   = zeros(n_dir,1); % how many don't use ris
    avg_ris_users   = zeros(n_dir,1); % how many use ris
    avg_don_time    = zeros(n_dir,1); %how much the donor is used
    avg_iab_time    = zeros(n_dir,1); % how much installed iab nodes are used
    avg_ris_time    = zeros(n_dir,1); % how much installed ris are used
    avg_solver_time = zeros(n_dir,1); % number of ms used by the solver to solve the problems
    avg_ris_contrib = zeros(n_dir,1); %how much the presence of RIS impacts the overall rate (for the users who use them)
    avg_hop_number  = zeros(n_dir,1); % avg number of hop per user to reach the donor
    avg_donor_tps   = zeros(n_dir,1); % tps connected directly to the donor
    avg_node_degree = zeros(n_dir,1); % how many children IAB nodes a IAB node has
    avg_don_degree  = zeros(n_dir,1); %how many children the donor has
    avg_bh_length   = zeros(n_dir,1);
    solved_count    = zeros(n_dir,1); % how many solved instances for scenario, useful for mean calculation, under half shadow the plot


    %it would be interesting to add how likely it is on average to use the
    %direct rate and the reflected rate (sum of probabilities), and the probability of the 16 states
    %(this could be done in preprocessing but in post-processing I could do it only on the 15 activated links)
    max_g = 0;
    mean_max_rate = 0;

  %  wb = waitbar(0);

    for d = 31:numel(dir_name_list)
   % for d = 35:35
        %enter solution folders and get all the solved .mfiles
    %    disp(['Processing ' dir_name_list{d}]);
    %    waitbar(d/numel(dir_name_list),wb,[num2str(round(d/numel(dir_name_list)*100,1)) '%']);
        solutions = dir([ sim_folder dir_name_list{d} '/solutions/' model_name '*.m']);

        if numel(solutions) < 20
        %    disp([dir_name_list{d} ' has ' num2str(20-numel(solutions)) ' unsolved instances']);
            if numel(solutions) == 0

                continue;

            end
        end
        solved_count(d) = numel(solutions);


        %for each solution...
        for sol=1:numel(solutions)
            disp(['Currently processing instance ' num2str(sol) ', budget ' num2str((d -1)*0.2)]);
            %run the solution
            run([solutions(sol).folder '/' solutions(sol).name]);
            
            %disp(['The overall traffic is ' num2str(allgs)]);


            %load needed variables from the curresponding .mat file
            data_name = split(solutions(sol).name, '_'); %split the string
            data_name = data_name{end}; %get the run
            data_name = data_name(4:end-2); %truncate .m and 'run' to get the .mat data name

            site_cache_id = DataHash([DataHash(scenario_struct.site) num2str(data_name)]); % hash is salted with rng_seed, since the site data is generated randomly
            radio_cache_id = DataHash([DataHash(scenario_struct.radio) site_cache_id]);
            site_cache_path = ['cache/containment_for_parallel/' site_cache_id '.mat'];
            radio_cache_path = ['cache/containment_for_parallel/' radio_cache_id '.mat'];
            if isfile(site_cache_path)
            	load(site_cache_path,...
                            'cs_tp_distance_matrix','cs_cs_distance_matrix','smallest_angles','n_cs','n_tp','scenario');

            else
            	disp("Site cache not found!!")
           	continue;

            end
            if isfile(radio_cache_path)
            	load(radio_cache_path,...
                 'bh_rates','weighted_rates','ris_rates','direct_rates','reflected_rates','state_probs','ris_better_mask');
                ris_fullrates = sum(reflected_rates.*state_probs,4);
                time_ratio = sum(state_probs.*ris_better_mask,4);

            else
            	disp("Radio cache not found!!")
            	continue;

            end
            
            switch model_id{mod}
                case {'sumMCS','sumrate','maxminMCS','maxminrate','minmaxt','sumairtime','sumall','sumfree','sumlen','sumfreeMCS','sumfreeabs','minmaxlen','sumrateforextra'}
                    allgs = sum(nonzeros(g));
                    if sum(g,'all') > max_g
                        max_g = sum(g,'all');
             %           disp([[solutions(sol).name] ': ' num2str(max_g) ' Mbps']);
                    end


                    if (mean(nonzeros(g))) > mean_max_rate
                        mean_max_rate = mean(nonzeros(g));

                        %         disp(['New mean max rate is ' num2str(mean_max_rate)])

                    end

                    temp_acc_dist = 0;
                    temp_ang_div = 0;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    [ue,bs,sd] = ind2sub(size(x),find(x)); %find all SDs involved in an access connection x
                    % disp([ue,bs,sd,sdt])
                    sd_counter = zeros(n_cs,1);
                    sd_useless = [];
                    for ttt = 1:n_tp
                        if sd(ttt) ~= 1
                            disp(time_ratio(ue(ttt),bs(ttt),sd(ttt)));
                            if time_ratio(ue(ttt),bs(ttt),sd(ttt))==0
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
                    [tx,rx] = find(f>1);
                    ris_idx = setdiff(unique(sd),[1; sd_useless]);

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %temp_ris = sum(y_ris(2:end));
                    %temp_ris = sum(y_ris.*squeeze(sum(g./ris_fullrates,[1,2]) >0)); %sum only RIS that have traffic associated to them
                    % temp_ris = sum(y_ris.*squeeze(sum((g./ris_fullrates > 0 & g./ris_fullrates < 1),[1,2])) > 0);
                    temp_ris = numel(ris_idx);
                    %temp_iab = sum(y_iab(1:end-1));
                    temp_iab = sum(f>1,'all');  %counts only the iab nodes that have traffic flowing to them. Every node has a parent and an incoming flow (besides the Donor)
                    %When the budget is high, the solver buys iab nodes indiscriminately but then it doesn't use them
                    temp_ris_users = 0;
                    temp_dir_users = 0;

                    temp_bh_length = 0;
                    bh_link_count = 0;

                    avg_cost(d) = avg_cost(d) + temp_ris*scenario.sim.ris_price + temp_iab*scenario.sim.iab_price;
                    avg_solver_time(d) = avg_solver_time(d) + time;

                    degree = sum(z,2);
        		    avg_node_degree(d) = avg_node_degree(d) + sum(degree(1:end-1))/temp_iab;
        		    avg_don_degree(d) = avg_don_degree(d) + degree(end);
                    iab_occupation_time = zeros(n_cs,1);
                    ris_occupation_time = zeros(n_cs,1);
                    ris_contribute = zeros(n_tp,1);
                    path = cell(n_tp,2); %cell structure for recreating the backwards path from each TP to the Donor. It is needed to find the bottleneck in the network and
                    %calculate how much additional
                    %througput can be given to the TP

                    for t=1:n_tp

                        [~, iab, ris] = ind2sub(size(x(t,:,:)), find(x(t,:,:)));
                        path{t,1} = [path{t,1} iab];
                        path = find_parent(t,path,z,n_cs);
        		    end
                    avg_tp_min(d) = avg_tp_min(d) + min(g(g>1));
                    for c=1:n_cs

                        for c2=1:n_cs
                            bh_counter = sum(cellfun(@(m)ismember(c2,m),path(:,1)));
                            if f(c,c2)>1
                				bh_link_count = bh_link_count +1;
                                temp_bh_length = temp_bh_length + cs_cs_distance_matrix(c,c2);
                                if dontcomparenetworks

                                    iab_occupation_time(c) = iab_occupation_time(c) + f(c,c2)/bh_rates(c,c2);
                                    iab_occupation_time(c2) = iab_occupation_time(c2) + f(c,c2)/bh_rates(c,c2);
                                else
                                    iab_occupation_time(c) = iab_occupation_time(c) + (bh_counter*scenario_struct.sim.R_dir_min)/bh_rates(c,c2);
                                    iab_occupation_time(c2) = iab_occupation_time(c2) + (bh_counter*scenario_struct.sim.R_dir_min)/bh_rates(c,c2);
                                end
                            end
                            for t=1:n_tp

                                if (x(t,c,c2)==1)
                				    if c == n_cs
                                        avg_donor_tps(d) = avg_donor_tps(d) + 1;
                                    end

                                    if dontcomparenetworks

                                        iab_occupation_time(c) = iab_occupation_time(c) + g(t,c,c2)/weighted_rates(t,c,c2);

                                    else

                                        iab_occupation_time(c) = iab_occupation_time(c) + scenario_struct.sim.R_dir_min/weighted_rates(t,c,c2);

                                    end
                                    avg_tp_rate(d) = avg_tp_rate(d) + g(t,c,c2);
                                    if c2~=1
                                        if dontcomparenetworks
                                            ris_occupation_time(c2) = ris_occupation_time(c2) + g(t,c,c2)/ris_fullrates(t,c,c2);
                                        else
                                            ris_occupation_time(c2) = ris_occupation_time(c2) + scenario_struct.sim.R_dir_min/ris_fullrates(t,c,c2);
                                        end
                                        if (weighted_rates(t,c,1)>0)
                                            ris_contribute(t) = weighted_rates(t,c,c2)/weighted_rates(t,c,1) -1;
                                        end

                                        %disp(['The RIS contribute for user ' num2str(t) ' is +' num2str(ris_contribute(t)*100) '%']);
                                        temp_ris_users = temp_ris_users + 1;
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

                    avg_ris(d) = avg_ris(d) + temp_ris;
                    avg_iab(d) = avg_iab(d) + temp_iab;
        		    avg_bh_length(d) = avg_bh_length(d) + temp_bh_length/bh_link_count;

                    avg_acc_dist(d) = avg_acc_dist(d) + temp_acc_dist/(temp_ris_users*2 + temp_dir_users);
                    if (temp_ris_users~=0)
                        avg_ang_div(d) = avg_ang_div(d) + temp_ang_div/temp_ris_users;
                        avg_ris_users(d) = avg_ris_users(d) + temp_ris_users;
                        avg_ris_contrib(d) = avg_ris_contrib(d) + sum(ris_contribute)/temp_ris_users;
                    end
                    avg_dir_users(d) = avg_dir_users(d) + temp_dir_users;
                    if temp_iab~=0
                        avg_iab_time(d) = avg_iab_time(d) + (sum(iab_occupation_time(2:end-1)))/temp_iab;
                    end
                    avg_don_time(d) = avg_don_time(d) + iab_occupation_time(end);
                    if temp_ris~=0
                        avg_ris_time(d) = avg_ris_time(d) + (sum(ris_occupation_time(2:end-1)))/temp_ris;
                    end

                    iab_free_time = 1 - iab_occupation_time;
                    ris_free_time = 1 - ris_occupation_time;
                    %disp(iab_free_time)

                    for t=1:n_tp

                        [~, iab, ris] = ind2sub(size(x(t,:,:)), find(x(t,:,:)));
                        avg_hop_number(d) = avg_hop_number(d) + numel(path{t,1});

                        if numel(path{t,1})==1
                            if ris~=1
                                if dontcomparenetworks
                                    path{t,2} = min([iab_free_time(iab)*weighted_rates(t,iab,ris), ris_fullrates(t,iab,ris) - g(t,iab,ris)]);
                                else
                                    path{t,2} = min([iab_free_time(iab)*weighted_rates(t,iab,ris), ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min]);
                                end
                            else
                                path{t,2} = iab_free_time(iab)*weighted_rates(t,iab,ris);
                            end
                        else
                            for seq=1:numel(path{t,1})
                                current = path{t,1}(seq);
                                if seq == 1
                                    next = path{t,1}(seq +1);
                                    access_sum = (iab_free_time(current)*bh_rates(next,current)*weighted_rates(t,iab,ris))/(bh_rates(next,current)+weighted_rates(t,iab,ris));
                                    if ris~=1
                                        if dontcomparenetworks
                                            limit_acc = min([access_sum, ris_fullrates(t,iab,ris) - g(t,iab,ris)]);
                                        else
                                            limit_acc = min([access_sum, ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min]);
                                        end
                                    else
                                        limit_acc = access_sum;
                                    end

                                    path{t,2} = limit_acc;
                                    %disp(path{t,2});

                                elseif seq == numel(path{t,1})
                                    previous = path{t,1}(seq -1);
                                    path{t,2} = min(path{t,2}, iab_free_time(current)*bh_rates(current,previous));
                                else
                                    next = path{t,1}(seq +1);
                                    previous = path{t,1}(seq -1);
                                    limit_bh = (iab_free_time(current)*bh_rates(current,previous)*bh_rates(next,current))/(bh_rates(current,previous)+bh_rates(next,current));
                                    path{t,2} = min([path{t,2} limit_bh]);
                                    %disp(path{t,2});
                                    
                                end    
                            end
                        end
                    end

                    for t=1:n_tp

                        avg_tp_full(d) = avg_tp_full(d) + path{t,2};

                    end

                case 'sumextra'
                 
                    temp_acc_dist = 0;
                    temp_ang_div = 0;
                    %disp(scenario_struct.sim.R_dir_min); 

                    %temp_ris = sum(y_ris(2:end));
                    %temp_ris = sum(y_ris.*squeeze(sum(g./ris_fullrates,[1,2]) >0)); %sum only RIS that have traffic associated to them
                    temp_ris = sum(y_ris.*squeeze(sum(((scenario_struct.sim.R_dir_min*x)./ris_fullrates > 0 & (scenario_struct.sim.R_dir_min*x)./ris_fullrates < 1),[1,2])) > 0);
                    %temp_iab = sum(y_iab(1:end-1));
                    temp_iab = sum(f>1,'all');  %counts only the iab nodes that have traffic flowing to them. Every node has a parent and an incoming flow (besides the Donor)
                    %When the budget is high, the solver buys iab nodes indiscriminately but then it doesn't use them
                    temp_ris_users = 0;
                    temp_dir_users = 0;
                    temp_bh_length = 0;
                    bh_link_count = 0;                    
                    avg_cost(d) = avg_cost(d) + temp_ris*scenario.sim.ris_price + temp_iab*scenario.sim.iab_price;
                    avg_solver_time(d) = avg_solver_time(d) + time;
		    degree = sum(z,2);
                    avg_node_degree(d) = avg_node_degree(d) + sum(degree(1:end-1))/temp_iab;
                    avg_don_degree(d) = avg_don_degree(d) + degree(end);                    
                    iab_occupation_time = zeros(n_cs,1);
                    ris_occupation_time = zeros(n_cs,1);
                    ris_contribute = zeros(n_tp,1);
                    path = cell(n_tp,2); %cell structure for recreating the backwards path from each TP to the Donor. It is needed to find the bottleneck in the network and
                    %calculate how much additional
                    %througput can be given to the TP
                    
                    avg_tp_min(d) = avg_tp_min(d) + scenario_struct.sim.R_dir_min;
                    for c=1:n_cs
                        
                        for c2=1:n_cs
                            if f(c,c2)>1
			        bh_link_count = bh_link_count + 1;
                                temp_bh_length = temp_bh_length + cs_cs_distance_matrix(c,c2);	
                                iab_occupation_time(c) = iab_occupation_time(c) + f(c,c2)/bh_rates(c,c2);
                                iab_occupation_time(c2) = iab_occupation_time(c2) + f(c,c2)/bh_rates(c,c2);
                            end
                            for t=1:n_tp
                                
                                if (x(t,c,c2)==1)
                    		    if c == n_cs
                                        avg_donor_tps(d) = avg_donor_tps(d) + 1;
                                    end
                                    iab_occupation_time(c) = iab_occupation_time(c) + scenario_struct.sim.R_dir_min/weighted_rates(t,c,c2);
                                    avg_tp_rate(d) = avg_tp_rate(d) + scenario_struct.sim.R_dir_min;
                                    
                                    if c2~=1
                                        
                                        ris_occupation_time(c2) = ris_occupation_time(c2) + (scenario_struct.sim.R_dir_min*x(t,c,c2))/ris_fullrates(t,c,c2);
                                        if (weighted_rates(t,c,1)>0)
                                            ris_contribute(t) = weighted_rates(t,c,c2)/weighted_rates(t,c,1) -1;
                                        end
                                        
                                       % disp(['The RIS contribute for user ' num2str(t) ' is +' num2str(ris_contribute(t)*100) '%']);
                                        temp_ris_users = temp_ris_users + 1;
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
                    
                    avg_ris(d) = avg_ris(d) + temp_ris;
                    avg_iab(d) = avg_iab(d) + temp_iab;
                    avg_acc_dist(d) = avg_acc_dist(d) + temp_acc_dist/(temp_ris_users*2 + temp_dir_users);
                    avg_bh_length(d) = avg_bh_length(d) + temp_bh_length/bh_link_count;

                    
                    if (temp_ris_users~=0)
                        avg_ang_div(d) = avg_ang_div(d) + temp_ang_div/temp_ris_users;
                        avg_ris_users(d) = avg_ris_users(d) + temp_ris_users;
                        avg_ris_contrib(d) = avg_ris_contrib(d) + sum(ris_contribute)/temp_ris_users;
                    end
                    avg_dir_users(d) = avg_dir_users(d) + temp_dir_users;
                    if temp_iab~=0
                        avg_iab_time(d) = avg_iab_time(d) + (sum(iab_occupation_time(2:end-1)))/temp_iab;
                    end
                    avg_don_time(d) = avg_don_time(d) + iab_occupation_time(end);
                    if temp_ris~=0
                        avg_ris_time(d) = avg_ris_time(d) + (sum(ris_occupation_time(2:end-1)))/temp_ris;
                    end
                    
                    iab_free_time = 1 - iab_occupation_time;
                    ris_free_time = 1 - ris_occupation_time;
                    %disp(iab_free_time)
                    
                    for t=1:n_tp
                        
                        [~, iab, ris] = ind2sub(size(x(t,:,:)), find(x(t,:,:)));
                        path{t,1} = [path{t,1} iab];
                        path = find_parent(t,path,z,n_cs);
                        avg_hop_number(d) = avg_hop_number(d) + numel(path{t,1});

                        if numel(path{t,1})==1
                            if ris~=1
                                disp(['The RIS capacity limit is ' num2str(ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min) ' mbps']);
                                path{t,2} = min([iab_free_time(iab)*weighted_rates(t,iab,ris), ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min]);
                                
                            else
                                path{t,2} = iab_free_time(iab)*weighted_rates(t,iab,ris);
                            end
                        else
                            for seq=1:numel(path{t,1})
                                current = path{t,1}(seq);
                                if seq == 1
                                    next = path{t,1}(seq +1);
                                    access_sum = (iab_free_time(current)*bh_rates(next,current)*weighted_rates(t,iab,ris))/(bh_rates(next,current)+weighted_rates(t,iab,ris));
                                    if ris~=1
                                        limit_acc = min([access_sum, ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min]);
                                        
                                    else
                                        limit_acc = access_sum;
                                    end
                                    
                                    path{t,2} = limit_acc;
                                    %disp(path{t,2});
                                    
                                elseif seq == numel(path{t,1})
                                    previous = path{t,1}(seq -1);
                                    path{t,2} = min(path{t,2}, iab_free_time(current)*bh_rates(current,previous));
                                else
                                    next = path{t,1}(seq +1);
                                    previous = path{t,1}(seq -1);
                                    limit_bh = (iab_free_time(current)*bh_rates(current,previous)*bh_rates(next,current))/(bh_rates(current,previous)+bh_rates(next,current));
                                    path{t,2} = min([path{t,2} limit_bh]);
                                    %disp(path{t,2});
                                    
                                end
                            end
                        end
                    end
                    
                    for t=1:n_tp
                        if abs(sum(g_x(t,:,:),'all') - path{t,2}) < 1
                           % disp(['The optimal extra traffic is the same as the bottleneck (difference of ' num2str(abs(sum(g_x(t,:,:),'all') - path{t,2})) ' Mbps)'])
                            avg_tp_full(d) = avg_tp_full(d) + path{t,2};
                        else
                            disp(['Problem!! The optimal extra traffic is ' num2str(sum(g_x(t,:,:),'all')) ' and the predicted bottleneck is ' num2str(path{t,2}) ' in ' num2str(dir_name_list{d}) ' with ' num2str(numel(solutions)) ' solved instances']);
                           % avg_tp_full(d) = avg_tp_full(d) + NaN;
                            avg_tp_full(d) = avg_tp_full(d) + path{t,2};
                        end    
                        
                    end

            end


        end
        %finish computing averages


        avg_ris(d) = avg_ris(d)/numel(solutions);
        avg_iab(d) = avg_iab(d)/numel(solutions);
        avg_cost(d) = avg_cost(d)/numel(solutions);
        avg_tp_full(d) = avg_tp_full(d)/(numel(solutions)*n_tp);
        avg_tp_rate(d) = avg_tp_rate(d)/(numel(solutions)*n_tp);
        avg_tp_min(d) = avg_tp_min(d)/numel(solutions);
        avg_acc_dist(d) = avg_acc_dist(d)/numel(solutions);
        avg_ang_div(d) = avg_ang_div(d)/numel(solutions);
        avg_ris_users(d)= avg_ris_users(d)/numel(solutions);
        avg_dir_users(d) = avg_dir_users(d)/numel(solutions);
        avg_iab_time(d) = avg_iab_time(d)/numel(solutions);
        avg_don_time(d) = avg_don_time(d)/numel(solutions);
        avg_ris_time(d) = avg_ris_time(d)/numel(solutions);
        avg_ris_contrib(d) = avg_ris_contrib(d)/numel(solutions);
        avg_solver_time(d) = avg_solver_time(d)/numel(solutions);
        avg_hop_number(d) = avg_hop_number(d)/(numel(solutions)*n_tp);
        avg_donor_tps(d) = avg_donor_tps(d)/numel(solutions);
        avg_don_degree(d) = avg_don_degree(d)/numel(solutions);
        avg_node_degree(d) = avg_node_degree(d)/numel(solutions);
        avg_bh_length(d) = avg_bh_length(d)/numel(solutions);
    end

   % waitbar(1,wb,'Saving...');
   % pause(1)

    %get the x ticks by splitting the folder names and getting the varying
    %parameter

    ticks_labels = split([directories.name], '_');
    ticks_labels = ticks_labels(7:7:end);
    ticks_labels = natsort(cellfun(@(ticks)ticks(:,14:end), ticks_labels, 'uni', false));
    %% save results
    if ~exist(['Mat_files_solutions/' sim_folder 'mat_results/'], 'dir')

        mkdir(['Mat_files_solutions/' sim_folder 'mat_results/']);

    end


    save(['Mat_files_solutions/' sim_folder ['mat_results/results_' model_id{mod}]], 'avg_ris', 'avg_iab', 'avg_cost',...
        'avg_tp_full', 'avg_tp_rate','avg_tp_min','avg_acc_dist', 'avg_ang_div','solved_count', 'ticks_labels',...
        'avg_ris_users', 'avg_dir_users', 'avg_iab_time', 'avg_ris_time', 'avg_don_time','avg_solver_time','avg_ris_contrib','avg_hop_number','avg_donor_tps','avg_don_degree','avg_node_degree','avg_bh_length');

  %  waitbar(1,wb,'Done');
  %  pause(1)

  %  close(wb)
  %  clearvars -except model_id sim_folder common_string dontcomparenetworks
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
