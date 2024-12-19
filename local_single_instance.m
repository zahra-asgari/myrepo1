% this scripts shows how to run a single planning instance locally
% please modify run_oplrun.sh according to the local machine
clc;
clearvars;
addpath('scenarios','utils','gen_functions','gen_scripts','Blockage_Data','WIP_functions','derived','leonardo study case',...
    'model_builder','Process_Buildings_code','site_plot_functions','radio/assets','radio/reza','classes');
%% inputs
% this is the planning scenario - scenarios are found in scenarios/
scenario = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel();

% this is the name of the folder where to save the planning instance data
% after it is generated
instance_folder = 'instances/';

% this is the name of the generated data to be saved (matlab-compatible and
% opl-compatible data are saved)
rng_seed = 40;
dataname = int2str(rng_seed);



% global options are set in GLOBAL_OPTIONS.m and are retreived through the
% following function
global_options = get_global_options();

% this is the folder where the generated opl model will be saved
model_folder = 'models/';

% this is the name of the model to be used to solve this particular
% instance - it should currespond to any model template name in
% model_builder/templates
model_name = 'complete_fixedDonor_blockageModel_sum_mean';

% call instance constructor
ins = instance_complete_fixedDonor_blockageModel(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed);
% ins = iab_ris_fixedDonor_fakeRis_blockageModel(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed);

%% run
% generate the planning instance data
ins.generate();

% save the planning instance data
ins.save_data();

% solve the planning instance
% ins.solve();

%plot the solution 
%ins.plot_solution();

