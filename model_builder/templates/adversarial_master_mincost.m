opti_template.name = mfilename;
opti_template.opti_gap = 0;
opti_template.time_lim = 0.5*3600;

%opti_template.objective = 'min_cost';
opti_template.objective = 'maxmin_angsep_adversarial';

opti_template.constraint_list = {
    'adversarial_master/all_simpler';
    'adversarial_master/angles_section';
    'adversarial_master/budget';
    };

opti_template.parameters_list = {
     'aversarial_master_parameters';
    };

opti_template.variables_list = {
    'adversarial_master'
    };
    
opti_template.preprocessing_list ={
    'adversarial_master_postprocessing';
    };