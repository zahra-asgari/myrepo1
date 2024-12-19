opti_template.name = mfilename;
opti_template.cplex.epgap = {0.05, 'Tolerated Optimality Gap'};
opti_template.cplex.tilim = {0.5*3600, 'Time Limit in Seconds'};

opti_template.objective = 'iab_ris_fixedDonor_fakeRis_blockageModel/sum_rate';

opti_template.constraint_list = {
    'iab_ris_fixedDonor_fakeRis_blockageModel/topology';
    'iab_ris_fixedDonor_fakeRis_blockageModel/flow';
    'iab_ris_fixedDonor_fakeRis_blockageModel/angles_section';
    'iab_ris_fixedDonor_fakeRis_blockageModel/budget';
    'iab_ris_fixedDonor_fakeRis_blockageModel/fixed_devices';
    };

opti_template.parameters_list = {
     'iab_ris_fixedDonor_fakeRis_blockageModel';
    };

opti_template.variables_list = {
    'iab_ris_fixedDonor_fakeRis_blockageModel';
    };
    
opti_template.preprocessing_list ={
    'iab_ris_fixedDonor_fakeRis_blockageModel_postprocessing';
    };
