opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 0.5*3600;

opti_template.objective = 'min_cost';

opti_template.constraint_list = {
    'fakeris/angles_section';
    'fakeris/mincost_constraints';
    'fakeris/fakeris_creation';
    };

opti_template.parameters_list = {
     'fakeris_parameters';
    };

opti_template.variables_list = {
    'fakeris'
    };
    
opti_template.preprocessing_list ={
    'fakeris_postprocessing';
    };