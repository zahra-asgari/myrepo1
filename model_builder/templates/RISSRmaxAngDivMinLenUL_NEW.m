opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 100*60;
opti_template.threads = 20;

opti_template.objective = 'IAB_maxangsep_minlen';

opti_template.constraint_list = {
    'RIS_SR_existence';
    'RIS_SR_budget';
    'RIS_SR_link_activation_new';
    'RIS_SR_k_cov';
    'RIS_SR_tree_topology';
    'RIS_SR_assignment';
    'RIS_SR_capacity_and_flow_UL';
    'RIS_SR_halfduplex_TDM_UL_NEW';
    'RIS_SR_sharing_UL';
    'RIS_SR_orientation_angdiv_minlength_section_minangle';
    %'IAB_fixed_bs';
    %'ris_budget';
    };

opti_template.parameters_list = {
    'RIS_SR_parameters_UL_NEW';
    };

opti_template.variables_list = {
    'RIS_SR_variables_UL';
    };

opti_template.preprocessing_list = {'dario_post_processing'};