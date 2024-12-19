%this script generates the bash script necessary to make a campaign run on a
%remote server 

% INPUT: campaign settings defined below 
% OUTPUT: a campaign folder in remote_campaigns/ which contains the
% generated data and the bash scripts necessary to launch the campaign on a
% remote server 

% HOW TO LAUNCH A REMOTE CAMPAIGN: 
% 1- set campaign settings
% 2- run the script (if caches are empty it might take a while if using the
% avdanced snr model)
% 3- copy zipped file named <campaign_id>_nomat.zip over to a remote server
% 4- unzip on the remote server
% 5- execute ./run_all_scenarios.sh on the remote server
% 6- once the solver is done, solutions are in solutions.zip

% NOTE: set remote_opl_path variable (line 176) according to the oplrun
% executable path in the remote server

%% init 
clearvars;
clc;
addpath('model_builder');
addpath('scenarios/');
addpath('utils','gen_functions','WIP_functions');
addpath('classes/');
addpath('radio/assets','radio/reza');
%% campaign settings



% a folder in remote_campaigns/ will be created and named campaign_id. This
% identifies the particular campaign 
campaign_id = 'blockagecampaign_peak_demand_sbz_journal_UL_NCR_100/';

% this is a list of scenarios to be included in the campaign - strings
% should currespond to scenario names in simulation_scenarios
scenario_file_list = {
    %'a300x300_24cs_15tp';
    'hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel';
    };

% this is a list of models to be applied to scenarios in this campaign -
% strings should currespond to model template names in
% model_builder/templates
mod_list ={
    % 'complete_fixedDonor_blockageModel_fair_mean';
    % 'complete_fixedDonor_blockageModel_sum_mean';
    % 'complete_fixedDonor_blockageModel_sd_fair_mean';
    % 'complete_fixedDonor_blockageModel_sd_sum_mean';
    % 'peak_complete_fixedDonor_blockageModel_fair_mean';
     'peak_complete_fixedDonor_blockageModel_sum_mean';
    % 'peak_complete_fixedDonor_blockageModel_sd_fair_mean';
    % 'peak_complete_fixedDonor_blockageModel_sd_sum_mean';
    % 'complete_fixedDonor_blockageModel_sum_mean_for_peak';
    % 'complete_fixedDonor_blockageModel_sd_sum_mean_for_peak';
 };

% this is how many different planning instances (i.e., runs) should be
% solved for each scenario-model combination
runs_per_model = 100;

% for each scenario, the campaign will contains runs_per_model instances
% that are solved with all the models in the mod_list

% this is the name of the instance class - instance classes are found in
% classes folder, they represent particular planning problem instances
% (i.e. planning with RIS only, RIS+SR planning) and they contain methods
% to generate the instance data, save the data, solve (locally) and plot
% the results 
instance_class_name = 'instance_complete_fixedDonor_blockageModel';
instance_class_handle = str2func(instance_class_name);

% if this is set to false then the instance data is not generated - for
% debug only
GENERATE_INSTANCES = true;

% opl constaint labels facilitate opl model debugging but decrease the
% solver's performance. The model builder includes constraint labels by
% default, set the following variable to true to delete them in the final
% model generated for remote campaign runs 
DELETE_OPL_CONSTRAINT_LABELS = true;

% if the campaign contains more than 1 planning instance data, then the
% data generation is parallelized in a parpool - set the following variable
% to true to override parallelization (for debug only)
PARALLEL_OVERRIDE = false; 

% set the max number of threads that cplex can occupy in the remote server
server_threads = 40;

%% writing master script
if ~isfolder('remote_campaigns/')
    mkdir('remote_campaigns/');
end
master_script_name = 'run_all_scenarios.sh';
master_bash_script = ['#!/bin/bash' newline 'echo "Runs: ' ...
    num2str(runs_per_model) '; Scenarios templates: '...
    num2str(numel(scenario_file_list)) '; Models: ' num2str(numel(mod_list))...
    '" | tee -a master_log.txt' newline];

%% loading the scenarios structures into an array, to be fed to the instance generation
execute_once = true;
for s=numel(scenario_file_list):-1:1%backwards loop for efficiency

    %get the scenario struct by evaluating the curresponding function
    scenario = feval(cell2mat(scenario_file_list(s)));

    %if there is any vector in the scenario
    if scenario.contains_vector
        %loop over fileds of the struct
        f_names = fieldnames(scenario.sim);
        for fn=1:numel(f_names)
            %if field is scalar or not numeric then continue, else generate scenarios
            %according to the field vector
            if numel(scenario.sim.(f_names{fn}))>1 && isnumeric(scenario.sim.(f_names{fn}))
                %we need to start filling from the end of the vector plus the elements that we need to add and move
                %backwards
                if exist('scenario_struct_list','var')
                    temp_size = numel(scenario_struct_list);
                else
                    temp_size = 1;
                end
                for sc=scenario.size+temp_size:-1:temp_size+1
                    scenario_struct_list(sc) = scenario;
                    %save the scalar value
                    scalar_value = scenario.sim.(f_names{fn});
                    scalar_value = scalar_value(sc-temp_size);
                    scenario_struct_list(sc).sim.(f_names{fn}) = scalar_value;
                    %modify the name such that it contains the value of the spanned parameter
                    scenario_struct_list(sc).name = [scenario_struct_list(sc).name num2str(scalar_value)];
                    % set contains_vectors to false
                    scenario_struct_list(sc).contains_vector = false;
                end
            else
                continue
            end
        end
        %now the place allocated for the scenario if it was not vectorial
        %needs to be deleted
        if execute_once
            scenario_struct_list(1) = [];
            execute_once = false;
        end
    else %the scenario does not contain vectors
        %load the scenario into the scenario_struct_list
        scenario_struct_list(s) = scenario;
    end
end

%% outer for loop
textwaitbar(0,numel(scenario_struct_list),'Generating simulation: ');
for s = 1:numel(scenario_struct_list)
    scenario_name = scenario_struct_list(s).name;
    scen_name = [scenario_name '_' num2str(runs_per_model) 'runs'];
    models_folder = 'models/';
    instance_folder = 'instances/';
    solution_folder = 'solutions';
    parent_folder = ['remote_campaigns/' campaign_id];

    %make the folder with the simulation name and use it as parent
    mkdir([parent_folder scen_name '/']);
    parent_folder = [parent_folder scen_name '/'];
    %make instance folder
    mkdir([parent_folder instance_folder]);
    %make solution folder
    mkdir([parent_folder solution_folder]);
    %make model folder
    mkdir([parent_folder models_folder])
    %copy models
    %copyfile('models/built/', [parent_folder models_folder]);
    %build models
    for m=1:numel(mod_list)
        buildModel(cell2mat(mod_list(m)), [parent_folder models_folder],server_threads);
    end

    %delete constraint labels if needed
    if DELETE_OPL_CONSTRAINT_LABELS
        % note that this sed is mac os compilant, use commented version for
        % linux
        %system([ 'sed -i '''' "/:$/d" ' parent_folder models_folder '*' ]);
         system([ 'sed -i "/:$/d" ' parent_folder models_folder '*' ]);
    end


    %sim script
    script_name = 'run_all.sh';
    remote_opl_path = '/opt/ibm/ILOG/CPLEX_Studio2211/opl/bin/x86-64_linux/oplrun';
    bash_script = ['#!/bin/bash' newline 'echo ''This script will run ' num2str(runs_per_model) ' pre-generated instances per model''' newline];
    bash_script = [bash_script 'export LC_ALL=en_US.UTF-8' newline];

    %master script
    master_bash_script = [master_bash_script 'SECONDS=0' newline];
    master_bash_script = [master_bash_script 'echo "----Now solving scenario ' scenario_name '----" | tee -a master_log.txt' newline];
    master_bash_script = [master_bash_script 'cd ' scen_name newline];
    master_bash_script = [master_bash_script 'chmod +x ' script_name newline];
    master_bash_script = [master_bash_script './' script_name newline];
    master_bash_script = [ master_bash_script 'echo "Scenario ' scenario_name ' done in $SECONDS seconds" | tee -a time.txt' newline];
    master_bash_script = [ master_bash_script 'cd ..' newline];
    master_bash_script = [ master_bash_script 'echo "----Scenario ' scenario_name ' done in $SECONDS seconds----" | tee -a master_log.txt' newline];
    master_bash_script = [ master_bash_script 'echo ""' newline];

    %% generate the instances
    scenario_script_path = ['scenarios/' scenario_name];
    scenario_struct = scenario_struct_list(s);
    scenario_struct_list(s).instances = runs_per_model;
    if (runs_per_model >=1)
        PARALLELIZE_GENERATION = 1;
    else
        PARALLELIZE_GENERATION = 0;
    end
    if(GENERATE_INSTANCES)
        global_options = get_global_options();
        if(PARALLELIZE_GENERATION && ~PARALLEL_OVERRIDE)
            % sequentially instanciate all classes
            instances={};
            for r=1:runs_per_model
                instances{r} = instance_class_handle(scenario_struct_list(s),global_options, ...
                  [parent_folder instance_folder],['run' num2str(r)],models_folder, cell2mat(mod_list(m)), r);
            end
            parfor r=1:runs_per_model
                %disp(['Parallel generation of istance ' num2str(r) ' of ' num2str(runs_per_model) '...']);
                %instance = feval(gen_function,scenario_struct, [parent_folder instance_folder], ['r' num2str(r)],r);
                %instance=instance_class_handle(scenario,global_options, ...
                  %[parent_folder instance_folder],['r' num2str(r)],models_folder, cell2mat(mod_list(m)), r);
                instances{r}.save_data();
                %save_datafile(instance,strcat(parent_folder, instance_folder, ['run' num2str(r) '.dat']));
            end
        else
            for r=1:runs_per_model
                %disp(['Generating istance ' num2str(r) ' of ' num2str(runs_per_model) '...']);
                %instance = feval(gen_function,scenario_struct, [parent_folder instance_folder], ['r' num2str(r)],r);
                %save_datafile(instance,strcat(parent_folder, instance_folder, ['run' num2str(r) '.dat']));
                instance=instance_class_handle(scenario_struct_list(s),global_options, ...
                  [parent_folder instance_folder],['run' num2str(r)],models_folder, cell2mat(mod_list(m)), r);
                instance.save_data();
            end
        end
    end
    %% bash script finalization
    %disp('Writing bash script...');
    for m=1:numel(mod_list)

        model_name = cell2mat(mod_list(m));
        bash_script = [bash_script 'echo "Running ' model_name ' model" | tee -a script_log.txt' newline];
        bash_script = [bash_script 'touch "processed_jobs.txt"' newline];
        %create directory if not exist
        bash_script = [bash_script 'mkdir -p "solutions"' newline];

        for r=1:runs_per_model
            %start tic
            bash_script = [bash_script 'SECONDS=0' newline];
            bash_script = [bash_script 'echo "-----Now optimizing run ' num2str(r) ' of ' num2str(runs_per_model) '..." | tee -a script_log.txt' newline];

            %if solution not found, run the datafile
            bash_script = [bash_script 'if ! grep -q "'  model_name '_r' num2str(r) '" processed_jobs.txt; then' newline];
            bash_script = [bash_script remote_opl_path ' ' models_folder model_name '.mod ' instance_folder 'run' num2str(r) '.dat | tee -a opl.log ../master_opl.log > /dev/null' newline];
            bash_script = [bash_script 'echo "     done in $SECONDS seconds" | tee -a script_log.txt' newline];
            bash_script = [bash_script 'if [ -f ''solutions/' model_name '_run' num2str(r) ...
                '.m'' ]; then echo "     gap before optimum: $(cat opl.log | grep %% | tail -n1 | rev | cut -d '' '' -f1 | rev)" | tee -a script_log.txt; else echo "     no solution" | tee -a script_log.txt; fi; echo "" | tee -a script_log.txt' ...
                newline];
            %job has been processed at this point, record this in a file
            bash_script = [bash_script 'echo "' model_name '_r' num2str(r) '" >> processed_jobs.txt' newline];
            bash_script = [bash_script 'else echo "     run already processed, skipping"; echo;fi' newline];
        end
    end

    %% save on file
    fid = fopen(strcat(parent_folder,script_name), 'w');
    fprintf(fid, bash_script);
    fclose(fid);
    %disp('Done');
    %set x attribute
    fileattrib(strcat(parent_folder,script_name),'+x','a');
    textwaitbar(s,numel(scenario_struct_list),'Generating simulation: ');
end
%saving master script
parent_folder = ['remote_campaigns/' campaign_id];
master_bash_script = [master_bash_script 'echo "ALL DONE" | tee -a master_log.txt' newline];
master_bash_script = [master_bash_script 'zip -r -qq solutions.zip . -i ''*.m'' ''*.txt'' ''*.log'''];
fid = fopen(strcat(parent_folder,master_script_name), 'w');
fprintf(fid, master_bash_script);
fclose(fid);
fileattrib(strcat(parent_folder,master_script_name),'+x','a');

%zip_commands = {['cd ' parent_folder ';zip -qq -r ' campaign_id(1:end-1) '_nomat.zip . -i "*.sh" "*.dat" "*.mod"'];
 %   ['cd ' parent_folder ';zip -qq -r ' campaign_id(1:end-1) '_full.zip ./* -x "*.zip"']};

zip_commands = {['cd ' parent_folder ';zip -qq -r ' campaign_id(1:end-1) '_nomat.zip . -i "*.sh" "*.dat" "*.mod"']};


fprintf('Compressing files...');
parfor comm=1:numel(zip_commands)
    system(zip_commands{comm});
end
fprintf(' done\n');
