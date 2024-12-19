opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 12000;

opti_template.objective = 'af_relays/min_cost_leaner';

opti_template.constraint_list = {
    'af_relays_leaner/orientation';
    'af_relays_leaner/tdm';
    'af_relays_leaner/topology';
    };

opti_template.parameters_list = {
     'af_parameters_leaner';
    };

opti_template.variables_list = {
    'af_leaner'
    };
    
opti_template.preprocessing_list ={
    'af_postprocessing_leaner';
    };