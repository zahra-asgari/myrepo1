opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 100*60;
opti_template.threads = 20;

opti_template.objective = 'IAB_maxangsep_minlen';

opti_template.constraint_list = {
    'RIS_SR_existence_fd';
    'RIS_SR_budget_fd';
    'RIS_SR_link_activation_fd';
    'RIS_SR_k_cov_fd';
    'RIS_SR_tree_topology_fd';
    'RIS_SR_assignment_fd';
    'RIS_SR_capacity_and_flow_UL_fd';
    'RIS_SR_halfduplex_TDM_UL_fd';
    'RIS_SR_sharing_UL_fd';
    'RIS_SR_orientation_angdiv_minlength_section_minangle_fd';
    %'IAB_fixed_bs';
    %'ris_budget';
    };

opti_template.parameters_list = {
    'RIS_SR_parameters_UL_fd';
    };

opti_template.variables_list = {
    'RIS_SR_variables_UL_fd';
    };

opti_template.preprocessing_list = {'ris_sr_fd_post_processing'};