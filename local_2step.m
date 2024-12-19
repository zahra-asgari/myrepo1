%% init
clearvars;
n_instances =0;

%local options
PLOT_SITE = 1;
PLOT_DISTANCE_STATISTICS = 0;

DISPLAY_SOLUTION = 0;
LEAN_MODEL = 0;

addpath('utils/', 'scenarios', 'gen_functions/');
addpath(genpath('model_builder/'));
rng_seed = 7;

%% generate instance
rng(rng_seed);

disp('Generating instance...');
instance_folder = 'instances/';
%scenario = feval('a200x200_10cs5tp_5mcs_1e5el_D60_maxR_minRout');
%scenario = feval('SR_a200x200_20cs_30tp_5mcs_1e4el_D60_maxR_minRout');
%scenario = feval('a200x200_20cs_10tp_5mcs_1e4el_D60_maxR_minRout');
%scenario = feval('SR_a400x300_52cs_32tp_5mcs_1e4el_D60_maxR_minRout');
%scenario = feval('SR_a200x200_10cs_5tp_5mcs_1e5el_D60_maxR_minRout');
scenario = a300x300_24cs_15tp();
%scenario = convert_scenario_new2old(scenario);
% scenario.uniform_n_tp = 15;
% scenario.uniform_n_cs = 25;
%scenario.R_dir_min = 100;
scenario.iab_budget = 3;
%scenario.R_out_min = 10

%experimenting
%scenario.R_out_min = 100;
%scenario.max_angle_span = 60;
% scenario.singleRis = true;
% scenario.fakeris = true;
%scenario.budget = 10;
%scenario.tuplematic = true;
%scenario.ris_components= 1e5;
%scenario.uniform_n_cs = 8;
%scenario.uniform_n_tp = 4;
%scenario.budget = scenario.uniform_n_tp*2/3;
%scenario.donor_price = 0.5;
%scenario.rx_sensitivity = -60;
%scenario.site_height = 200; %meters
%scenario.site_width  = 200; %meters

%instance = generateInstanceRelaysBuildings(scenario, instance_folder, 'data');
%instance = generateInstanceIABonly(scenario, instance_folder, 'data',rng_seed);
%instance = generateInstance(scenario_script, instance_folder, 'data');

instance = generateInstanceIABonlyUL(scenario, instance_folder, 'data',rng_seed);
%instance = generateInstanceIABonly(scenario, instance_folder, 'data',rng_seed);
% instance.C_acc = instance.C_acc*1e3;
% instance.C_acc(:,:,end) = zeros(15,25)+1;

% for i = 1:15
%     instance.C_acc(:,:,i) = instance.C_acc(:,:,i) - diag(instance.C_acc(:,:,i));
% end

%% save instance
disp('saving...');
save_datafile(instance,strcat(instance_folder, 'data.dat '));
disp('done');

%% run opl locally
disp('Running cplex...');
full_instance_path = '/Users/eugenio/no_indexing/RIS_planning_generator/RIS_Planning_Instance_Generator/instances/data.dat';
%full_model_path = '/Users/eugenio/Dropbox/RIS_planning_generator/models/angSepv2.mod';
%full_model_path = '/Users/eugenio/Dropbox/RIS_planning_generator/models/maxNlosAvgV2.mod';
%full_model_path = '/Users/eugenio/Dropbox/RIS_planning_generator/models/maxNlosSnr_angularThr_Nomin.mod';
%full_model_path = '/Users/eugenio/Dropbox/RIS_planning_generator/models/maxNlosSnr.mod';
%full_model_path = '''/Users/eugenio/no_indexing/RIS_planning_generator/RIS_Planning_Instance_Generator/models/speriamoFunzioni.mod''';

%build model and save it
full_model_path = '/Users/eugenio/no_indexing/RIS_planning_generator/RIS_Planning_Instance_Generator/models/built/';
%mod_template = 'maxPeakNlosSnr';
%mod_template  = 'max_rate_zeroreconf';
%mod_template = 'singleris_maxavgrate';
%mod_template = 'fakeris_maxavgrate';
%mod_template = 'af_ris_mincost_leaner';
%mod_template = 'iab_only_mincost';
mod_template = 'iab_only_minlen_ul';
%mod_template = 'iab_only_minlen';
%mod_template = 'af_iab_fakerel_multi';
%mod_template = 'fakeris_mincost2';
%mod_template = 'noris_mincost';
%mod_template = 'noris_maxavgrate';
%mod_template = 'singleris_max_rate_zeroreconf';
buildModel(mod_template, full_model_path);

opl_command = ['./utils/run_oplrun.sh',' ', [full_model_path mod_template '.mod'],' ', full_instance_path];
%opl_command = ['./utils/run_oplrun.sh',' ', '/Users/eugenio/no_indexing/RIS_planning_generator/RIS_Planning_Instance_Generator/models/tuplematic.mod',' ', full_instance_path];
%opl_command = ['./utils/run_oplrun.sh',' ', '/Users/eugenio/no_indexing/RIS_planning_generator/RIS_Planning_Instance_Generator/models/singleris_maxavgrate.mod',' ', full_instance_path];
[status, cmdout]=system(opl_command);
disp(cmdout);

%% 
%load instance and solution
run(['models/solutions/' mod_template '_data.m']);

disp(['Installed iab nodes: ' num2str(sum(y_iab))]);
%disp(['Installed relays: ' num2str(sum(y_rel))]);
%%
rng(rng_seed);
%%
mod_template = 'RISSRmaxAngDivMinLenUL_FixedBs';
%instance = generateInstanceFixedBS_noautoresult(scenario, instance_folder, 'data',rng_seed);
instance = generateInstanceRISSRUL(scenario, instance_folder, 'data',rng_seed);
instance.Y_IAB = y_iab;
instance.Y_DON = y_don;
instance.rate_ratio = 0.5;
instance.sem_budget = 1;


   %% save instance
disp('saving...');
save_datafile(instance,strcat(instance_folder, 'data.dat'));
disp('done');  
     

%% run opl locally
disp('Running cplex...');
full_instance_path = '/Users/eugenio/no_indexing/RIS_planning_generator/RIS_Planning_Instance_Generator/instances/data.dat';
%full_model_path = '/Users/eugenio/Dropbox/RIS_planning_generator/models/angSepv2.mod';
%full_model_path = '/Users/eugenio/Dropbox/RIS_planning_generator/models/maxNlosAvgV2.mod';
%full_model_path = '/Users/eugenio/Dropbox/RIS_planning_generator/models/maxNlosSnr_angularThr_Nomin.mod';
%full_model_path = '/Users/eugenio/Dropbox/RIS_planning_generator/models/maxNlosSnr.mod';
%full_model_path = '''/Users/eugenio/no_indexing/RIS_planning_generator/RIS_Planning_Instance_Generator/models/speriamoFunzioni.mod''';

%build model and save it
full_model_path = '/Users/eugenio/no_indexing/RIS_planning_generator/RIS_Planning_Instance_Generator/models/built/';
%mod_template = 'maxPeakNlosSnr';
%mod_template  = 'max_rate_zeroreconf';
%mod_template = 'singleris_maxavgrate';
%mod_template = 'fakeris_maxavgrate';
%mod_template = 'af_ris_mincost_leaner';
%mod_template = 'iab_only_mincost';
%mod_template = 'fakeris_mincost2';
%mod_template = 'noris_mincost';
%mod_template = 'noris_maxavgrate';
%mod_template = 'singleris_max_rate_zeroreconf';
buildModel(mod_template, full_model_path);

opl_command = ['./utils/run_oplrun.sh',' ', [full_model_path mod_template '.mod'],' ', full_instance_path];
%opl_command = ['./utils/run_oplrun.sh',' ', '/Users/eugenio/no_indexing/RIS_planning_generator/RIS_Planning_Instance_Generator/models/tuplematic.mod',' ', full_instance_path];
%opl_command = ['./utils/run_oplrun.sh',' ', '/Users/eugenio/no_indexing/RIS_planning_generator/RIS_Planning_Instance_Generator/models/singleris_maxavgrate.mod',' ', full_instance_path];
[status, cmdout]=system(opl_command);
disp(cmdout);
     
     
     
     