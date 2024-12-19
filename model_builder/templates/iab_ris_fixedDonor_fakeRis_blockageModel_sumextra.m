opti_template.name = mfilename;
opti_template.cplex.epgap = {0.05, 'Tolerated Optimality Gap'};
opti_template.cplex.tilim = {300, 'Time Limit in Seconds'};
opti_template.cplex.mipemphasis = {0, '0 balanced, 1 feasibility, 2 optimality, 3 best bound, 4 hidden, 5 heuristic '};
%opti_template.cplex.cutpass = {-1, 'Number of cut passes, 0 default, -1 disabled'};
%opti_template.cplex.heurfreq = {-1, 'Number of heursitc passes, 0 default, -1 disabled'};
opti_template.objective = 'iab_ris_fixedDonor_fakeRis_blockageModel/sum_extra';

opti_template.constraint_list = {
    'extra_iab_ris_fixedDonor_fakeRis_blockageModel/topology';
    'extra_iab_ris_fixedDonor_fakeRis_blockageModel/flow';
    'extra_iab_ris_fixedDonor_fakeRis_blockageModel/angles_section';
    'extra_iab_ris_fixedDonor_fakeRis_blockageModel/budget';
    'extra_iab_ris_fixedDonor_fakeRis_blockageModel/fixed_devices';
    };

opti_template.parameters_list = {
     'iab_ris_fixedDonor_fakeRis_blockageModel';
    };

opti_template.variables_list = {
    'extra_iab_ris_fixedDonor_fakeRis_blockageModel';
    };
    
opti_template.preprocessing_list ={
    'extra_iab_ris_fixedDonor_fakeRis_blockageModel_postprocessing';
    };
