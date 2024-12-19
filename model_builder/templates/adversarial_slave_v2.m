opti_template.name = mfilename;
opti_template.opti_gap = 0;
opti_template.time_lim = 0.5*3600;

%opti_template.objective = 'min_cost';
opti_template.objective = 'adversarial_slave/maxmin_slave_v2';

opti_template.constraint_list = {
    'adversarial_slave_v2/all';
    };

opti_template.parameters_list = {
     'aversarial_slave_parameters_v2';
    };

opti_template.variables_list = {
    'adversarial_slave_v2'
    };
    
opti_template.preprocessing_list ={
    'adversarial_slave_postprocessing_v2';
    };
