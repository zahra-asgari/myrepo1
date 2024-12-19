function [instance] = generateInstanceIABonlyUL(scenario, instance_folder, dataname, rng_seed)
%generateInstances this function generates a random instance to be later
%simulated
%
% [instance] = generateInstances()
%
% $Author: Eugenio Moro $	$Date: 2020/11/30 16:29:44 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020
addpath('utils', 'radio', 'gen_scripts');
%these are local options that should be set to 1 only for debug
PLOT_SITE = false;
PLOT_DISTANCE_STATISTICS = 0;


%unpack scenario into workspace
v2struct(scenario.site);
v2struct(scenario.radio);
v2struct(scenario.sim);
clear size;
rng(rng_seed);

%% cs and tp

cs_tp_generation;


%% Building collision
%if scenario.has_buildings
%    building_collisions;
%end

%% Distance computation

distances;

%% Radio channels computation
pathloss_matrices;
ris_radio_channels_eugenio;


    af_snr_eugenio;
    ris_snr_eugenio;
    direct_snr_eugenio;
    max_rate = max(direct_rate(:));
    bh_snr_eugenio;


%fake relay has the same rate as direct comm
af_rel_rate(:,:,n_cs) = direct_rate(:,:);

%CONTINUA QUIIIIIII!!!!!!!!!!!!!!!

channels_paolo
%% Rate adaptation section
%rate_adaptation;
%src_dir_back_rate;

%% angles computation

angle_parameters;

%% outage-weighted rate

%channel_state_weight_rate;

%% variable pruning
%af_links_angles_pruning;

%direct links pruning mask
direct_p_mask = direct_rate >= R_dir_min;

%refl. links pruning
af_p_mask  = af_rel_rate >= R_out_min;
ris_p_mask = ris_rate >= R_out_min;

%angles
angles_mask_ris = zeros(t,d,r);
for r=1:n_cs
    for d=1:n_cs
        for t=1:n_tp
            angles_mask_ris(t,d,r) = max([cs_tp_angles(r,t) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t) cs_cs_angles(r,d)]) <= 2*max_angle_span;        
        end
    end
end

ris_p_mask = ris_p_mask & angles_mask_ris & repmat(direct_p_mask,1,1,n_cs);
af_p_mask  = af_p_mask & repmat(direct_p_mask,1,1,n_cs);

if has_buildings
    for r=1:n_cs
        for d=1:n_cs
            for t=1:n_tp
                af_p_mask(t,d,r) = af_p_mask(t,d,r) & ~cs_cs_obstruction(d,r) & ~cs_tp_obstruction(d,t) & ~cs_tp_obstruction(r,t);
                ris_p_mask(t,d,r) = ris_p_mask(t,d,r) & ~cs_cs_obstruction(d,r) & ~cs_tp_obstruction(d,t) & ~cs_tp_obstruction(r,t);
            end
        end
    end
    if scenario.has_relays 
        bh_p_mask = ~cs_cs_obstruction;
    end
else %bh p mask is all 1 if no obstacles
        bh_p_mask = ones(n_cs,n_cs);
end

%decativate self links 
bh_p_mask = bh_p_mask - diag(diag(bh_p_mask));

%% generate instance structure
%some local variables are set as transpose in the instance structure in
%order to reflect the indexing in the model
instance.n_cs=n_cs;
instance.n_tp=n_tp;

instance.donor_price = donor_price;
instance.iab_price = iab_price;
instance.iab_budget = iab_budget;

instance.acc_p_mask = direct_p_mask';
instance.bh_p_mask = bh_p_mask; 


instance.C_bh = channel.backhaul_rates;
instance.D_dl = R_dir_min;
instance.D_ul = R_dir_min*0.1;
instance.C_acc = direct_rate';

instance.tp_cs_dist = cs_tp_distance_matrix';
instance.max_linlen = max(cs_tp_distance_matrix(:));
instance.linlen_emphasis = OF_weight;

instance.output_filename = [num2str(dataname) '.m'];
%% workspace saving
save([instance_folder dataname]);

end
