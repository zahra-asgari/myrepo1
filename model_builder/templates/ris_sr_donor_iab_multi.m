opti_template.name = mfilename;
opti_template.opti_gap = 0.05;
opti_template.time_lim = 100*60;
opti_template.threads = 20;

opti_template.objective = 'IAB_maxangsep_minlen';

opti_template.constraint_list = {
    'RIS_SR_existence';
    'RIS_SR_budget';
    %'RIS_SR_link_activation_new';
    'RIS_SR_link_activation_explicit';
    'RIS_SR_k_cov';
    %'RIS_SR_donor_iab_logical';
    'RIS_SR_tree_topology';
    'RIS_SR_assignment';
    'RIS_SR_capacity_and_flow_UL_donor_iab';
    %'RIS_SR_halfduplex_TDM_UL_donor_iab';
    'RIS_SR_sharing_UL_donor_iab';
    'RIS_SR_orientation_angdiv_minlength_section_minangle';
    %'IAB_fixed_bs';
    %'ris_budget';
    };

opti_template.parameters_list = {
    'RIS_SR_parameters_UL_donor_iab';
    };

opti_template.variables_list = {
    'RIS_SR_variables_UL_donor_iab';
    };

opti_template.preprocessing_list = {'ris_sr_donor_iab_post_processing'};