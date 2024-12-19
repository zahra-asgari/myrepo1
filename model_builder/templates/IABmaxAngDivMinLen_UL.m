opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 10*60;
opti_template.threads = 20;

opti_template.objective = 'IAB_maxangsep_minlen';

opti_template.constraint_list = {
    'IAB_existence';
    'IAB_budget_UL';
    'IAB_link_activation_UL';
    'IAB_k_cov';
    'IAB_tree_topology_UL';
    'IAB_RIS_assignment';
    'IAB_Capacity_and_Flow_UL';
    'IAB_halfduplex_and_singlebeam_UL';
    'IAB_RIS_sharing_UL';
    'IAB_orientation_angdiv_minlength_section';
    %'IAB_fixed_bs';
    %'ris_budget';
    };

opti_template.parameters_list = {
    'RIS_parameters_UL';
    };

opti_template.variables_list = {
    'RIS_variables_UL';
    };

opti_template.preprocessing_list = {'paolo_post_processing'};