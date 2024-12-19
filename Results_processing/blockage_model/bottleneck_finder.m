%% init
clear;
addpath('utils/','cache/','scenarios/');
%sim_folder = 'budget/';
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
    };
for mod=1:numel(model_id)
    model_name = [common_string model_id{mod}];
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
    
    
    avg_accdon_bn   = zeros(n_dir,1);
    avg_don_bn      = zeros(n_dir,1);
    avg_acciab_bn   = zeros(n_dir,1);
    avg_pathiab_bn  = zeros(n_dir,1);
    avg_ris_bn      = zeros(n_dir,1);
    peak_rate_sum   = NaN(n_dir,100); %matrix to associate each instance to the peak rate sum
    star_degree     = NaN(n_dir,100);
    solved_count    = zeros(n_dir,1); % how many solved instances for scenario, useful for mean calculation, under half shadow the plot
    
    wb = waitbar(0);
    
    for d = 1:numel(dir_name_list)
        %for d = 6:6
        %enter solution folders and get all the solved .mfiles
        disp(['Processing ' dir_name_list{d}]);
        waitbar(d/numel(dir_name_list),wb,[num2str(round(d/numel(dir_name_list)*100,1)) '%']);
        solutions = dir([ sim_folder dir_name_list{d} '/solutions/' model_name '*.m']);
        
        if numel(solutions) < 20
            disp([dir_name_list{d} ' has ' num2str(20-numel(solutions)) ' unsolved instances']);
            if numel(solutions) == 0
                
                continue;
                
            end
        end
        solved_count(d) = numel(solutions);
        
        
        %for each solution...
        for sol=1:numel(solutions)
            %run the solution
            run([solutions(sol).folder '/' solutions(sol).name]);
            %load needed variables from the curresponding .mat file
            data_name = split(solutions(sol).name, '_'); %split the string
            data_name = data_name{end}; %get the run
            data_name = data_name(4:end-2); %truncate .m and 'run' to get the .mat data name
            star_degree(d,str2double(data_name)) = sum(f(end,:)>1);            
            site_cache_id = DataHash([DataHash(scenario_struct.site) num2str(data_name)]); % hash is salted with rng_seed, since the site data is generated randomly
            radio_cache_id = DataHash([DataHash(scenario_struct.radio) site_cache_id]);
            site_cache_path = ['cache/' site_cache_id '.mat'];
            radio_cache_path = ['cache/' radio_cache_id '.mat'];
            if isfile(site_cache_path)
                load(site_cache_path,'n_cs','n_tp','scenario');
            else
                disp("Site cache not found!!")
                continue;
                
            end
            if isfile(radio_cache_path)
                load(radio_cache_path,...
                 'bh_rates','weighted_rates','ris_rates','reflected_rates','state_probs');
                ris_fullrates = sum(reflected_rates.*state_probs,4);
            else
                disp("Site cache not found!!")
                continue;
                
            end
            
            iab_occupation_time = zeros(n_cs,1);
            ris_occupation_time = zeros(n_cs,1);
            path = cell(n_tp,3); %cell structure for recreating the backwards path from each TP to the Donor. It is needed to find the bottleneck in the network and
            %calculate how much additional
            %througput can be given to the TP
            
            switch model_id{mod}
                case {'sumMCS','sumrate','maxminMCS','maxminrate','minmaxt','sumairtime','sumall','sumfree','sumlen','sumfreeMCS','sumfreeabs','minmaxlen'}
                    
                    
                    for ll=1:n_tp
                        path{ll,3} = 'N/A';
                        [~, iab, ris] = ind2sub(size(x(ll,:,:)), find(x(ll,:,:)));
                        path{ll,1} = [path{ll,1} iab];
                        path = find_parent(ll,path,z,n_cs);
                    end
                    
                    for c=1:n_cs
                        
                        for c2=1:n_cs
                            bh_counter = sum(cellfun(@(m)ismember(c2,m),path(:,1)));
                            if f(c,c2)>1
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
                                    
                                    if dontcomparenetworks
                                        
                                        iab_occupation_time(c) = iab_occupation_time(c) + g(t,c,c2)/weighted_rates(t,c,c2);
                                        
                                    else
                                        
                                        iab_occupation_time(c) = iab_occupation_time(c) + scenario_struct.sim.R_dir_min/weighted_rates(t,c,c2);
                                        
                                    end
                                    if c2~=1
                                        
                                        if dontcomparenetworks
                                            ris_occupation_time(c2) = ris_occupation_time(c2) + g(t,c,c2)/ris_fullrates(t,c,c2);
                                        else
                                            ris_occupation_time(c2) = ris_occupation_time(c2) + scenario_struct.sim.R_dir_min/ris_fullrates(t,c,c2);
                                        end
                                    end
                                    
                                end
                                
                            end
                            
                        end
                        
                    end
                    
                    iab_free_time = 1 - iab_occupation_time;
                    ris_free_time = 1 - ris_occupation_time;
                    %disp(iab_free_time)
                    
                    for t=1:n_tp
                        
                        [~, iab, ris] = ind2sub(size(x(t,:,:)), find(x(t,:,:)));
                        if numel(path{t,1})==1
                            if ris~=1
                                if dontcomparenetworks
                                    path{t,2} = min([iab_free_time(iab)*weighted_rates(t,iab,ris), ris_fullrates(t,iab,ris) - g(t,iab,ris)]);
                                    if iab_free_time(iab)*weighted_rates(t,iab,ris) <= ris_fullrates(t,iab,ris) - g(t,iab,ris)
                                        path{t,3} = "Access Donor TDM";
                                    else
                                        path{t,3} = "RIS TDM";
                                    end
                                else
                                    path{t,2} = min([iab_free_time(iab)*weighted_rates(t,iab,ris), ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min]);
                                    if iab_free_time(iab)*weighted_rates(t,iab,ris) <= ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min
                                        path{t,3} = "Access Donor TDM";
                                    else
                                        path{t,3} = "RIS TDM";
                                    end

                                end
                            else
                                path{t,2} = iab_free_time(iab)*weighted_rates(t,iab,ris);
                                path{t,3} = "Access Donor TDM";
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
                                            if access_sum <= ris_fullrates(t,iab,ris) - g(t,iab,ris)
                                                path{t,3} = "Access IAB TDM";
                                            else
                                                path{t,3} = "RIS TDM";
                                            end
                                        else
                                            limit_acc = min([access_sum, ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min]);
                                            if access_sum <= ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min
                                                path{t,3} = "Access IAB TDM";
                                            else
                                                path{t,3} = "RIS TDM";
                                            end

                                        end
                                    else
                                        limit_acc = access_sum;
                                        path{t,3} = "Access IAB TDM";
                                    end
                                    
                                    path{t,2} = limit_acc;
                                    %disp(path{t,2});
                                    
                                elseif seq == numel(path{t,1})
                                    previous = path{t,1}(seq -1);
                                    if iab_free_time(current)*bh_rates(current,previous) <= path{t,2}
                                        path{t,3} = "Donor TDM";
                                    end
                                    path{t,2} = min(path{t,2}, iab_free_time(current)*bh_rates(current,previous));
                                else
                                    next = path{t,1}(seq +1);
                                    previous = path{t,1}(seq -1);
                                    limit_bh = (iab_free_time(current)*bh_rates(current,previous)*bh_rates(next,current))/(bh_rates(current,previous)+bh_rates(next,current));
                                    if limit_bh <= path{t,2}
                                        path{t,3} = "Path IAB TDM";
                                        %disp(path{t,2});
                                    end
                                    path{t,2} = min([path{t,2} limit_bh]);
                                    
                                end
                            end
                        end
                    end
                    
                    avg_accdon_bn(d)   = avg_accdon_bn(d) + sum([path{:,3}] == "Access Donor TDM");
                    avg_don_bn(d)      = avg_don_bn(d) + sum([path{:,3}] == "Donor TDM");
                    avg_acciab_bn(d)   = avg_acciab_bn(d) + sum([path{:,3}] == "Access IAB TDM");
                    avg_pathiab_bn(d)  = avg_pathiab_bn(d) + sum([path{:,3}] == "Path IAB TDM");
                    avg_ris_bn(d)      = avg_ris_bn(d) + sum([path{:,3}] == "RIS TDM");
                    peak_rate_sum(d,str2double(data_name))   = sum(cellfun(@sum,path(:,2)));
                    
                    
                case {'sumextra'}
                    
                    
                    for ll=1:n_tp
                        path{ll,3} = 'N/A';
                    end
                
                    for c=1:n_cs
                        
                        for c2=1:n_cs
                            if f(c,c2)>1
                                iab_occupation_time(c) = iab_occupation_time(c) + f(c,c2)/bh_rates(c,c2);
                                iab_occupation_time(c2) = iab_occupation_time(c2) + f(c,c2)/bh_rates(c,c2);
                            end
                            for t=1:n_tp
                                
                                if (x(t,c,c2)==1)
                                    
                                    iab_occupation_time(c) = iab_occupation_time(c) + scenario_struct.sim.R_dir_min/weighted_rates(t,c,c2);
                                    
                                    if c2~=1
                                        
                                        ris_occupation_time(c2) = ris_occupation_time(c2) + scenario_struct.sim.R_dir_min/ris_fullrates(t,c,c2);
                                        
                                    end
                                    
                                end
                                
                            end
                            
                        end
                        
                    end
                    
                    iab_free_time = 1 - iab_occupation_time;
                    ris_free_time = 1 - ris_occupation_time;
                    %disp(iab_free_time)
                    
                    for t=1:n_tp
                        
                        [~, iab, ris] = ind2sub(size(x(t,:,:)), find(x(t,:,:)));
                        path{t,1} = [path{t,1} iab];
                        path = find_parent(t,path,z,n_cs);
                        if numel(path{t,1})==1
                            if ris~=1
                                path{t,2} = min([iab_free_time(iab)*weighted_rates(t,iab,ris), ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min]);
                                if iab_free_time(iab)*weighted_rates(t,iab,ris) <= ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min
                                    path{t,3} = "Access Donor TDM";
                                    disp(['Access Donor limited,' num2str(path{t,2}) ' Mbps']);
                                else
                                    path{t,3} = "RIS TDM";
                                    disp(['RIS limited,' num2str(path{t,2}) ' Mbps']);
                                end
                                
                            else
                                path{t,2} = iab_free_time(iab)*weighted_rates(t,iab,ris);
                                path{t,3} = "Access Donor TDM";
                                disp(['Access Donor limited,' num2str(path{t,2}) ' Mbps']);

                            end
                        else
                            for seq=1:numel(path{t,1})
                                current = path{t,1}(seq);
                                if seq == 1
                                    next = path{t,1}(seq +1);
                                    access_sum = (iab_free_time(current)*bh_rates(next,current)*weighted_rates(t,iab,ris))/(bh_rates(next,current)+weighted_rates(t,iab,ris));
                                    if ris~=1
                                        
                                        if access_sum <= ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min
                                            path{t,3} = "Access IAB TDM";
                                            path{t,2} = access_sum;
                                            disp(['Access IAB limited,' num2str(path{t,2}) ' Mbps']);
                                        else
                                            path{t,3} = "RIS TDM";
                                            path{t,2} = ris_fullrates(t,iab,ris) - scenario_struct.sim.R_dir_min;
                                            disp(['RIS limited,' num2str(path{t,2}) ' Mbps']);
                                        end
                                    else
                                        
                                        path{t,3} = "Access IAB TDM";
                                        path{t,2} = access_sum;
                                        disp(['Access IAB limited,' num2str(path{t,2}) ' Mbps']);
                                    end
                                    
                                    
                                    %disp(path{t,2});
                                    
                                elseif seq == numel(path{t,1})
                                    previous = path{t,1}(seq -1);
                                    if iab_free_time(current)*bh_rates(current,previous) <= path{t,2}
                                        path{t,3} = "Donor TDM";
                                        path{t,2} = iab_free_time(current)*bh_rates(current,previous);
                                        disp(['Donor limited,' num2str(path{t,2}) ' Mbps']);
                                    end
                                    
                                else
                                    next = path{t,1}(seq +1);
                                    previous = path{t,1}(seq -1);
                                    limit_bh = (iab_free_time(current)*bh_rates(current,previous)*bh_rates(next,current))/(bh_rates(current,previous)+bh_rates(next,current));
                                    if limit_bh <= path{t,2}
                                        path{t,3} = "Path IAB TDM";
                                        path{t,2} = limit_bh;
                                        disp(['Path IAB limited,' num2str(path{t,2}) ' Mbps']);
                                        %disp(path{t,2});
                                    end
                                    path{t,2} = min([path{t,2} limit_bh]);
                                    
                                end
                            end
                        end
                    end
                    
                    for t=1:n_tp
                        if abs(sum(g_x(t,:,:),'all') - path{t,2}) < 1
                            disp(['The optimal extra traffic is the same as the bottleneck (difference of ' num2str(abs(sum(g_x(t,:,:),'all') - path{t,2})) ' Mbps)'])
                           
                        else
                            disp(['Problem!! The optimal extra traffic is ' num2str(sum(g_x(t,:,:),'all')) ' and the predicted bottleneck is ' num2str(path{t,2}) '!!']);
                            disp(['TP ' num2str(t) ', instance ' data_name ', budget ' num2str(d)]);
                            
                        end    
                        
                    end



                    avg_accdon_bn(d)   = avg_accdon_bn(d) + sum([path{:,3}] == "Access Donor TDM");
                    avg_don_bn(d)      = avg_don_bn(d) + sum([path{:,3}] == "Donor TDM");
                    avg_acciab_bn(d)   = avg_acciab_bn(d) + sum([path{:,3}] == "Access IAB TDM");
                    avg_pathiab_bn(d)  = avg_pathiab_bn(d) + sum([path{:,3}] == "Path IAB TDM");
                    avg_ris_bn(d)      = avg_ris_bn(d) + sum([path{:,3}] == "RIS TDM");
                    peak_rate_sum(d,str2double(data_name))   = sum(cellfun(@sum,path(:,2)));
                    
                    
                    
            end
            
            
        end
        %finish computing averages
        
        
        avg_acciab_bn(d)    = avg_acciab_bn(d)/numel(solutions);
        avg_accdon_bn(d)    = avg_accdon_bn(d)/numel(solutions);
        avg_pathiab_bn(d)   = avg_pathiab_bn(d)/numel(solutions);
        avg_don_bn(d)       = avg_don_bn(d)/numel(solutions);
        avg_ris_bn(d)       = avg_ris_bn(d)/numel(solutions);

        
        
    end
    
    waitbar(1,wb,'Saving...');
    pause(1)
    
    %get the x ticks by splitting the folder names and getting the varying
    %parameter
    
    ticks_labels = split([directories.name], '_');
    ticks_labels = ticks_labels(7:7:end);
    ticks_labels = natsort(cellfun(@(ticks)ticks(:,14:end), ticks_labels, 'uni', false));
    
    %% save results
    if ~exist(['Mat_files_solutions/' sim_folder 'bottleneck/'], 'dir')
        
        mkdir(['Mat_files_solutions/' sim_folder 'bottleneck/']);
        
    end
    
    
    save(['Mat_files_solutions/' sim_folder ['bottleneck/data_' model_id{mod}]], 'avg_accdon_bn',...
        'avg_don_bn','avg_acciab_bn','avg_pathiab_bn','avg_ris_bn','peak_rate_sum','star_degree','solved_count', 'ticks_labels');
    
    waitbar(1,wb,'Done');
    pause(1)
    
    close(wb)
    clearvars -except model_id sim_folder common_string dontcomparenetworks
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
