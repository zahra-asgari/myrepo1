%% init
clear all;
addpath('utils/','cache/','scenarios/');
sim_folder = 'blockagecampaign_peak_demand_sbz_journal_UL_NCR_100/';
model_name = 'peak_complete_fixedDonor_blockageModel_sum_mean';
folder_names_root = 'hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel';
%% open results folder and list files curresponding to the model
directories = dir(['remote_campaigns/' sim_folder folder_names_root '*']);
%nat sort forlder such that the are sorted in increasing parameter
%variations
dir_name_list = {directories.name};
dir_name_list = natsort(dir_name_list, '\d+\.?\d*');
useless_var = zeros(101,100);

%% execute some data processing for each folder, over all the runs in the folder

for di = 1:numel(dir_name_list)
% for di=34:34

    %enter solution folders and get all the solved .mfiles
    disp(['Processing ' dir_name_list{di}]);
    solutions = dir(['remote_campaigns/' sim_folder dir_name_list{di} '/solutions/' model_name '*.m']);
    [~,sortidx]=natsort({solutions.name});
    solutions = solutions(sortidx);

    if numel(solutions) < 20
        disp([dir_name_list{di} ' has ' num2str(20-numel(solutions)) ' unsolved instances']);
        if numel(solutions) == 0

            continue;

        end
    end


    %for each solution...
    for sol=1:numel(solutions)
        %for sol=14:14
        %run the solution

        %load needed variables from the curresponding .mat file
        data_name = split(solutions(sol).name, '_'); %split the string

        data_name = data_name{end}; %get the run
        data_name = data_name(4:end-2); %truncate .m and 'run' to get the .mat data name

        % if ismember(str2double(data_name),[52])
        % 
        % else
        %     continue;
        % end
        run([solutions(sol).folder '/' solutions(sol).name]);
        [tx_dl,rx_dl] = find(f_dl>1);
        iab_idx = unique([tx_dl rx_dl]);
        % if isempty(ncr_idx)
        %     continue;
        % end


        used_iab = numel(iab_idx);
        if used_iab > 0
            used_iab = used_iab - 1;
        end
        all_iab = sum(y_iab) -1;
        useless_var(di,sol) = all_iab - used_iab ;
        disp(useless_var(di,sol));
        clearvars -except dir_name_list useless_var di solutions model_name sim_folder sol
    end
        clearvars -except dir_name_list useless_var di model_name sim_folder
end



