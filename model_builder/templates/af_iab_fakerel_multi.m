opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 12000;

opti_template.objective = 'af_relays/multi_iab_af';

opti_template.constraint_list = {
    %'af_relays_iab_fakerelay/orientation';
    'af_relays_iab_fakerelay/orientation_vanilla';
    'af_relays_iab_fakerelay/flow';
    'af_relays_iab_fakerelay/topology';
    'af_relays_iab_fakerelay/src';
    'af_relays_iab_fakerelay/budget';
    };

opti_template.parameters_list = {
     'fakerel_parameters';
    };

opti_template.variables_list = {
    'fakerel'
    };
    
opti_template.preprocessing_list ={
    'fakerel_postprocessing';
    };