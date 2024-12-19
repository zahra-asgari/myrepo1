opti_template.name = mfilename;
opti_template.cplex.epgap = {0.40, 'Tolerated Optimality Gap'};
opti_template.cplex.tilim = {0.5*3600, 'Time Limit in Seconds'};

opti_template.objective = 'complete_fixedDonor_fakeRis_blockageModel/sum_extra';

opti_template.constraint_list = {
    'peak_complete_model_fixedDonor_blockageModel/topology';
    'peak_complete_model_fixedDonor_blockageModel/flow';
    'peak_complete_model_fixedDonor_blockageModel/angles_section';
    'peak_complete_model_fixedDonor_blockageModel/budget';
    'peak_complete_model_fixedDonor_blockageModel/fixed_devices';
    'peak_complete_model_fixedDonor_blockageModel/peak_flow';
    };

opti_template.parameters_list = {
     'complete_model_fixedDonor_blockageModel_parameters';
    };

opti_template.variables_list = {
    'complete_model_fixedDonor_blockageModel_variables';
    'peak_complete_model_fixedDonor_blockageModel_variables';
    };
    
opti_template.preprocessing_list ={
    'peak_complete_model_fixedDonor_blockageModel_postprocessing';
    };
