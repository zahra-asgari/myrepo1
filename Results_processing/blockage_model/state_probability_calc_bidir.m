clear;
clc;
scenario_struct = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel();
EXTRA = 0;
SOLVED = 1; %check blockage state probability distribution for actual solved instances
if EXTRA
    sim_folder = 'extra_100/';
    model_name = 'iab_ris_fixedDonor_fakeRis_blockageModel_sumextra';

else
    sim_folder = 'sbzwrong_100/';
    sd = (contains(sim_folder,'sd'));
    if sd
        model_name = 'complete_fixedDonor_blockageModel_sd_sum_mean';

    else
        model_name = 'complete_fixedDonor_blockageModel_sum_mean';
    end
end
wrong = (contains(sim_folder,'wrong'));
folder_names_root = 'hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel';
%% open results folder and list files curresponding to the model

if SOLVED
    directories = dir(['solved_instances/' sim_folder folder_names_root '*']);
    n_dir = numel(directories);
    avg_probs_dir = zeros(16,n_dir);
    avg_probs_src = zeros(16,n_dir);
    all_sol_dir = cell(n_dir,1);
    all_sol_src = cell(n_dir,1);
    
    dir_name_list = {directories.name};
    dir_name_list = natsort(dir_name_list, '\d+\.?\d*');
    solved_count    = zeros(n_dir,1); % how many solved instances for scenario, useful for mean calculation, under half shadow the plot
    % for di = 1:numel(dir_name_list)
    for di = 50:50
        all_probs_dir = [];
        all_probs_src = [];
        sd_better.DL.ris = zeros(16,1);
        sd_better.UL.ris = zeros(16,1);
        sd_better.DL.ncr = zeros(16,1);
        sd_better.UL.ncr = zeros(16,1);
        disp(['Processing ' dir_name_list{di}]);
        solutions = dir(['solved_instances/' sim_folder dir_name_list{di} '/solutions/' model_name '*.m']);
        [~,sortidx]=natsort({solutions.name});
        solutions = solutions(sortidx);
        if numel(solutions) < 100
            disp([dir_name_list{di} ' has ' num2str(100-numel(solutions)) ' unsolved instances']);
            if numel(solutions) == 0

                continue;

            end
        end
        solved_count(di) = numel(solutions);
        for sol=1:numel(solutions)
            probs_dir = zeros(16, scenario_struct.site.uniform_n_tp);
            probs_src = zeros(16, scenario_struct.site.uniform_n_tp);
            run([solutions(sol).folder '/' solutions(sol).name]);
            %load needed variables from the curresponding .mat file
            data_name = split(solutions(sol).name, '_'); %split the string
            model_title = data_name{end -1};
            data_name = data_name{end}; %get the run
            data_name = data_name(4:end-2); %truncate .m and 'run' to get the .mat data name
            site_cache_id = DataHash([DataHash(scenario_struct.site) num2str(data_name)]); % hash is salted with rng_seed, since the site data is generated randomly
            radio_cache_id = DataHash([DataHash(scenario_struct.radio) site_cache_id]);
            if wrong
                radio_cache_path = ['cache/instances before sbz probabilities correction/' radio_cache_id '.mat'];
            else
                radio_cache_path = ['cache/' radio_cache_id '.mat'];
            end
            if isfile(radio_cache_path)
                load(radio_cache_path,...
                    'state_probs','sd_better_mask');
            else
                disp("Site cache not found!!")
                continue;
                
            end
            [row, col, depth, type] = ind2sub(size(x),find(x));
            for i=1:scenario_struct.site.uniform_n_tp
                if (depth(i)) == 1
                    probs_dir(:,i) = squeeze(state_probs.UL(row(i),col(i),depth(i),:));
                else
                    probs_src(:,i) = squeeze(state_probs.UL(row(i),col(i),depth(i),:));
                        switch type(i)
                            case 1
                                sd_better.DL.ris = [sd_better.DL.ris squeeze(sd_better_mask.DL.ris(row(i),col(i),depth(i),:))];
                                sd_better.UL.ris = [sd_better.UL.ris squeeze(sd_better_mask.UL.ris(row(i),col(i),depth(i),:))];
                            case 2
                                sd_better.DL.ncr = [sd_better.DL.ncr squeeze(sd_better_mask.DL.ncr(row(i),col(i),depth(i),:))];
                                sd_better.UL.ncr = [sd_better.UL.ncr squeeze(sd_better_mask.UL.ncr(row(i),col(i),depth(i),:))];
                        end

                    
                end
            end
            probs_dir(:,all(probs_dir == 0))=[]; % removes column if the entire column is zero
            probs_src(:,all(probs_src == 0))=[]; % removes column if the entire column is zero            
            all_probs_dir = [all_probs_dir probs_dir];
            all_probs_src = [all_probs_src probs_src];
            
        end
        sd_better.DL.ris(:,all(sd_better.DL.ris == 0)) = [];
        sd_better.UL.ris(:,all(sd_better.UL.ris == 0)) = [];
        sd_better.DL.ncr(:,all(sd_better.DL.ncr == 0)) = [];
        sd_better.UL.ncr(:,all(sd_better.UL.ncr == 0)) = [];
        sd_better.DL.ris = mean(sd_better.DL.ris,2);
        sd_better.UL.ris = mean(sd_better.UL.ris,2);
        sd_better.DL.ncr = mean(sd_better.DL.ncr,2);
        sd_better.UL.ncr = mean(sd_better.UL.ncr,2);
        avg_probs_dir(:,di) = mean(all_probs_dir,2);
        avg_probs_src(:,di) = mean(all_probs_src,2);
        all_sol_dir{di} = all_probs_dir;
        all_sol_src{di} = all_probs_src;
    end
    ticks_labels = split([directories.name], '_');
    ticks_labels = ticks_labels(7:7:end);
    ticks_labels = natsort(cellfun(@(ticks)ticks(:,14:end), ticks_labels, 'uni', false));
    if ~exist(['Mat_files_solutions/' sim_folder 'blockage_probs_solved/'], 'dir')

        mkdir(['Mat_files_solutions/' sim_folder 'blockage_probs_solved/']);

    end
    save(['Mat_files_solutions/' sim_folder ['blockage_probs_solved/states_' model_name]],...
        'solved_count','avg_probs_dir','avg_probs_src','all_sol_dir','all_sol_src','sd_better');

else
    avg_state_probs=zeros(16,1);
    sd_better.DL.ris = zeros(16,1);
    sd_better.UL.ris = zeros(16,1);
    sd_better.DL.ncr = zeros(16,1);
    sd_better.UL.ncr = zeros(16,1);

    for inst=1:100
        site_cache_id = DataHash([DataHash(scenario_struct.site) num2str(inst)]); % hash is salted with rng_seed, since the site data is generated randomly
        radio_cache_id = DataHash([DataHash(scenario_struct.radio) site_cache_id]);
        if wrong
            radio_cache_path = ['cache/instances before sbz probabilities correction/' radio_cache_id '.mat'];
        else
            radio_cache_path = ['cache/' radio_cache_id '.mat'];
        end
        if isfile(radio_cache_path)
            load(radio_cache_path,...
                'state_probs','sd_better_mask');
        else
            disp("Site cache not found!!")
            continue;

        end


        probs = state_probs.DL(:,2:end,2:end-1,:);
        probs = permute(probs,[4,1,2,3]);
        probs = reshape(probs,16,26*25*15);
        probs(:,all(probs == 0))=[]; % removes column if the entire column is zero
        avg_state_probs = avg_state_probs + mean(probs,2);
        sd_better.DL.ris = sd_better.DL.ris + squeeze(sum(sd_better_mask.DL.ris,[1 2 3]));
        sd_better.UL.ris = sd_better.UL.ris + squeeze(sum(sd_better_mask.UL.ris,[1 2 3]));
        sd_better.DL.ncr = sd_better.DL.ncr + squeeze(sum(sd_better_mask.DL.ncr,[1 2 3]));
        sd_better.UL.ncr = sd_better.UL.ncr + squeeze(sum(sd_better_mask.UL.ncr,[1 2 3]));
    end
    avg_state_probs = avg_state_probs/100;
    state_size = 15*26*25;
    sd_better.DL.ris = sd_better.DL.ris/(100*state_size);
    sd_better.UL.ris = sd_better.UL.ris/(100*state_size);
    sd_better.DL.ncr = sd_better.DL.ncr/(100*state_size);
    sd_better.UL.ncr = sd_better.UL.ncr/(100*state_size);
    if ~exist(['Mat_files_solutions/' sim_folder 'blockage_probs_all/'], 'dir')

        mkdir(['Mat_files_solutions/' sim_folder 'blockage_probs_all/']);

    end
    save(['Mat_files_solutions/' sim_folder ['blockage_probs_all/states_' model_name]],'avg_state_probs',"sd_better");
end


