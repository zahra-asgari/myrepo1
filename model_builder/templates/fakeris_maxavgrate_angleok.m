opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 12000;

opti_template.objective = 'max_rate';

opti_template.constraint_list = {
    'budget';
    'fakeris/angles_section';
    'fakeris/constraints';
    'fakeris/fakeris_creation';
    'fakeris/angles_ok';
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