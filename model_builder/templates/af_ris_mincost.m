opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 12000;

opti_template.objective = 'af_relays/min_cost';

opti_template.constraint_list = {
    'af_relays/orientation';
    'af_relays/tdm';
    'af_relays/topology';
    };

opti_template.parameters_list = {
     'af_parameters';
    };

opti_template.variables_list = {
    'af'
    };
    
opti_template.preprocessing_list ={
    'af_postprocessing';
    };