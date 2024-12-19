opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 60;

opti_template.objective = 'iab_only/min_cost';

opti_template.constraint_list = {
    'iab_only/flow';
    'iab_only/topology';
    };

opti_template.parameters_list = {
     'iab_only_parameters';
    };

opti_template.variables_list = {
    'iab_only'
    };
    
opti_template.preprocessing_list ={
    'iabonly_postprocessing';
    };