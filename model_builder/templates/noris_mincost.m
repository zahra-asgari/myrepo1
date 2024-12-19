opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 4*3600;

opti_template.objective = 'min_cost_noris';

opti_template.constraint_list = {
    'noris/mincost_costraints';
    };

opti_template.parameters_list = {
    'fakeris_parameters';
    };   

opti_template.variables_list = {
    'noris'
    };
    
opti_template.preprocessing_list ={
    'noris_postprocessing';
    };