opti_template.name = mfilename;
opti_template.opti_gap = 0;
opti_template.time_lim = 0.5*3600;

%opti_template.objective = 'min_cost';
opti_template.objective = 'adversarial_slave/maxangsep_intermediate';

opti_template.constraint_list = {
    'adversarial_intermediate/all';
    };

opti_template.parameters_list = {
     'aversarial_slave_parameters';
    };

opti_template.variables_list = {
    'adversarial_slave'
    };
    
opti_template.preprocessing_list ={
    'adversarial_slave_postprocessing';
    };