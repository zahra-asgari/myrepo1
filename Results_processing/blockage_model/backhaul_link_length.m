%% init
clear;
addpath('utils/','cache/','scenarios/');
%sim_folder = 'budget/';
sim_folder = 'small_highD/';
common_string = 'iab_ris_fixedDonor_fakeRis_blockageModel_';
model_id = {
   % 'maxminMCS';
   % 'minmaxt';
   % 'sumairtime';
   % 'sumall';
   % 'sumfree';
   % 'sumMCS';
   % 'sumextra';
   % 'sumlen';
   % 'sumfreeMCS';
   % 'sumfreeabs';
    'sumrate';
    };
for mod=1:numel(model_id)
    model_name = [common_string model_id{mod}];
    scenario_struct = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel();
    folder_names_root = 'hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel';
    %% open results folder and list files curresponding to the model
    directories = dir(['solved_instances/' sim_folder folder_names_root '*']);
    n_dir = numel(directories);
    
    %nat sort forlder such that the are sorted in increasing parameter
    %variations
    dir_name_list = {directories.name};
    dir_name_list = natsort(dir_name_list, '\d+\.?\d*');
    
    
    %% execute some data processing for each folder, over all the runs in the folder
    
    avg_bh_length    = zeros(n_dir,1); % avg access link distance to see if model tries to shorten link: only direct count 1, 2-coverage counts 2
    solved_count    = zeros(n_dir,1); % how many solved instances for scenario, useful for mean calculation, under half shadow the plot
    
    
    for d = 1:numel(dir_name_list)
    %for d = 6:6
        %enter solution folders and get all the solved .mfiles
        disp(['Processing ' dir_name_list{d}]);
    
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
            %disp(['The overall traffic is ' num2str(allgs)]);
            %load needed variables from the curresponding .mat file
            data_name = split(solutions(sol).name, '_'); %split the string
            data_name = data_name{end}; %get the run
            data_name = data_name(4:end-2); %truncate .m and 'run' to get the .mat data name
            
            site_cache_id = DataHash([DataHash(scenario_struct.site) num2str(data_name)]); % hash is salted with rng_seed, since the site data is generated randomly
            site_cache_path = ['cache/' site_cache_id '.mat'];
            if isfile(site_cache_path)
                load(site_cache_path,...
                    'cs_cs_distance_matrix','n_cs','scenario');
            else
                disp("Site cache not found!!")
                continue;
                
            end
            
            switch model_id{mod}
                case {'sumMCS','sumrate','maxminMCS','maxminrate','minmaxt','sumairtime','sumall','sumfree','sumlen','sumfreeMCS','sumfreeabs','sumextra'}
                    
                    temp_bh_length = 0;
                    bh_link_count = 0;
                    

                    for c=1:n_cs
                        
                        for c2=1:n_cs
                            if f(c,c2)>1
                                bh_link_count = bh_link_count + 1;
                                temp_bh_length = temp_bh_length + cs_cs_distance_matrix(c,c2);
                            end

                            
                            
                        end
                        
                    end

                    if bh_link_count > 0
                    	avg_bh_length(d) = avg_bh_length(d) + temp_bh_length/bh_link_count;
                    end
                case 'irrelevant'

            end
            
            
        end
        %finish computing averages
        
        avg_bh_length(d) = avg_bh_length(d)/numel(solutions);
        
        
    end
    
    
    %get the x ticks by splitting the folder names and getting the varying
    %parameter
    
    ticks_labels = split([directories.name], '_');
    ticks_labels = ticks_labels(7:7:end);
    ticks_labels = natsort(cellfun(@(ticks)ticks(:,14:end), ticks_labels, 'uni', false));

    
    %% save results
    if ~exist(['Mat_files_solutions/' sim_folder 'bh_analysis/'], 'dir')
        
        mkdir(['Mat_files_solutions/' sim_folder 'bh_analysis/']);
        
    end
    
    
    save(['Mat_files_solutions/' sim_folder ['bh_analysis/results_' model_id{mod}]],'avg_bh_length', 'solved_count', 'ticks_labels');
    
    clearvars -except model_id sim_folder common_string
end
