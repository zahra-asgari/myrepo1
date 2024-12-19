opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 0.5*3600;

opti_template.objective = 'iab_ris_multi_final';

opti_template.constraint_list = {
    'iab_ris_multi_final/topoplogy';
    'iab_ris_multi_final/flow';
    'iab_ris_multi_final/angles_section';
    'iab_ris_multi_final/budget';
    'iab_ris_multi_final/fixed_donor';
    };

opti_template.parameters_list = {
     'iab_ris_multi_final';
    };

opti_template.variables_list = {
    'iab_ris_multi_final'
    };
    
opti_template.preprocessing_list ={
    'iab_ris_multi_final_postprocessing';
    };