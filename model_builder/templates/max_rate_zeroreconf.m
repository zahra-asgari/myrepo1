opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 4*3600;

opti_template.objective = 'max_rate';

opti_template.constraint_list = {
    'budget';
    'k_cov_don';
    'link_activation';
    'topology';
    'angles_section';
    'rate_adaptation';
    'tdm';
    'outage_ra_zeroreconf';
    'min_outage_rate';
    };

opti_template.parameters_list = {
    };   