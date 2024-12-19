opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 0.5*3600;

opti_template.objective = 'iab_ris_multi_leonardo';

opti_template.constraint_list = {
    'iab_ris_multi_leonardo/topoplogy';
    'iab_ris_multi_leonardo/flow';
    'iab_ris_multi_leonardo/budget';
    };

opti_template.parameters_list = {
     'iab_ris_multi_leonardo';
    };

opti_template.variables_list = {
    'iab_ris_multi_leonardo'
    };
    
opti_template.preprocessing_list ={
    'iab_ris_multi_leonardo_postprocessing';
    };