opti_template.name = mfilename;
opti_template.cplex.epgap = {0.05, 'Tolerated Optimality Gap'};
opti_template.cplex.tilim = {0.5*3600, 'Time Limit in Seconds'};

opti_template.objective = 'complete_fixedDonor_fakeRis_blockageModel/maxmin';

opti_template.constraint_list = {
    'complete_model_fixedDonor_blockageModel/topology';
    'complete_model_fixedDonor_blockageModel/flow';
    'complete_model_fixedDonor_blockageModel/angles_section';
    'complete_model_fixedDonor_blockageModel/budget';
    'complete_model_fixedDonor_blockageModel/fixed_devices';
    'complete_model_fixedDonor_blockageModel/maxmin_rate';
    'complete_model_fixedDonor_blockageModel/solved_topology';
    };

opti_template.parameters_list = {
     'complete_model_fixedDonor_blockageModel_parameters';
     'solved_topology_pars';
    };

opti_template.variables_list = {
    'complete_model_fixedDonor_blockageModel_variables';
    };
    
opti_template.preprocessing_list ={
    'complete_model_fixedDonor_blockageModel_postprocessing';
    };

