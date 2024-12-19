opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 10*60;
opti_template.threads = 20;

opti_template.objective = 'IAB_maxangsep_minlen';

opti_template.constraint_list = {
    'IAB_existence';
    %'IAB_budget';
    'IAB_link_activation';
    'IAB_k_cov';
    'IAB_Capacity_and_Flow';
    'IAB_halfduplex_and_singlebeam';
    'IAB_tree_topology_downlink';
    'IAB_power_law';
    'IAB_orientation_angdiv_minlength_section';
    'IAB_fixed_bs';
    'ris_budget';
    };

opti_template.parameters_list = {
    'RIS_parameters';
    };

opti_template.variables_list = {
    'RIS_variables';
    };

opti_template.preprocessing_list = {'paolo_post_processing'};