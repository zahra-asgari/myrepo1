function [instance] = generateInstanceRISSRULFixedBs(scenario, instance_folder, dataname, rng_seed)
%generateInstances this function generates a random instance to be later
%simulated
%
% [instance] = generateInstances()
%
% $Author: Eugenio Moro $	$Date: 2020/11/30 16:29:44 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020
addpath('utils', 'radio', 'gen_scripts');
%these are local options that should be set to 1 only for debug
PLOT_SITE = 0;
PLOT_DISTANCE_STATISTICS = 0;
LOAD_FROM_MAT = true;


%unpack scenario into workspace
v2struct(scenario);
clear size;
rng(rng_seed);

%% cs and tp

%[n_tp,n_cs,cs_positions,tp_positions,cs_cs_distance_matrix, cs_tp_distance_matrix]...
%    = cs_tp_generation(scenario);
if LOAD_FROM_MAT
    run_id = dataname(2:end);
    load(['solved_instances/STEP1_iab_ul_budget3/tesipaolo_20runs/instances/r' num2str(run_id)],...
        'cs_positions', 'tp_positions', 'cs_cs_distance_matrix', 'cs_tp_distance_matrix',...
        'n_cs','n_tp');
else
    cs_tp_generation;
    distances;
end
%% Building collision
%if scenario.has_buildings
%    building_collisions;
%end

%% Distance computation

%distances;

%% Radio channels computation
pathloss_matrices;
ris_radio_channels_eugenio;
%
%
af_snr_eugenio;
% ris_snr_eugenio;
% direct_snr_eugenio;
% max_rate = max(direct_rate(:));
bh_snr_eugenio;
%
%
% %fake relay has the same rate as direct comm
% af_rel_rate(:,:,n_cs) = direct_rate(:,:);

[direct_rate,reflected_rate] =...
    channel_computation_eugenio(cs_tp_distance_matrix,cs_cs_distance_matrix, scenario);

direct_airtime_dl = permute(repmat(R_dir_min./direct_rate, 1,1,n_cs),[1,2,3]);
reflected_airtime_dl = (R_dir_min*rate_ratio)./reflected_rate;
sr_airtime_dl = (R_dir_min*rate_ratio)./af_rel_rate;

direct_airtime_ul = permute(repmat(0.1*R_dir_min./direct_rate, 1,1,n_cs),[1,2,3]);
reflected_airtime_ul = (0.1*R_dir_min*rate_ratio)./reflected_rate;
sr_airtime_ul = (0.1*R_dir_min*rate_ratio)./af_rel_rate;
%disp(reflected_airtime_dl)

max_airtime_dl_ris = max(direct_airtime_dl, reflected_airtime_dl);
max_airtime_ul_ris = max(direct_airtime_ul, reflected_airtime_ul);

max_airtime_dl_sr = max(direct_airtime_dl, sr_airtime_dl);
max_airtime_ul_sr = max(direct_airtime_ul, sr_airtime_ul);

max_airtime_dl_ris(max_airtime_dl_ris == Inf) = 0;
max_airtime_ul_ris(max_airtime_ul_ris == Inf) = 0;
max_airtime_dl_sr(max_airtime_dl_sr == Inf) = 0;
max_airtime_ul_sr(max_airtime_ul_sr == Inf) = 0;

reflected_airtime_dl(reflected_airtime_dl == Inf) = 0;
reflected_airtime_ul(reflected_airtime_ul == Inf) = 0;

channels_paolo;
%% Rate adaptation section
%rate_adaptation;
%src_dir_back_rate;

%% angles computation

%[cs_tp_angles,cs_cs_angles, smallest_angles] ...
%    = angles_adversarial(cs_positions, tp_positions);
angle_parameters;
%% outage-weighted rate

%channel_state_weight_rate;

%% variable pruning
%af_links_angles_pruning;

%src_p_mask = ones(n_tp,n_cs,starting_tp_positioning);

%direct links pruning mask
direct_p_mask = direct_rate >= R_dir_min;

%refl. links pruning
af_p_mask  = af_rel_rate >= R_dir_min*rate_ratio;
ris_p_mask = reflected_rate >= R_dir_min*rate_ratio;

%angles
angles_mask_ris = zeros(n_tp,n_cs,n_cs);

for r=1:n_cs
    for d=1:n_cs
        for t=1:n_tp
            angles_mask_ris(t,d,r) = max([cs_tp_angles(r,t) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t) cs_cs_angles(r,d)]) <= 2*max_angle_span;
        end
    end
end


ris_p_mask = ris_p_mask & angles_mask_ris;
af_p_mask  = af_p_mask & repmat(direct_p_mask,1,1,n_cs);

% put diagonals to 0
for t=1:n_tp
    
    for c=1:n_cs
        ris_p_mask(t,c,c) = 0;
    end
    
end

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

%% load step1 solution
run_id = dataname(2:end);
run(['solved_instances/STEP1_iab_ul_budget3/tesipaolo_20runs/solutions/iab_only_minlen_ul_r' run_id '.m']);

%% generate instance structure
%some local variables are set as transpose in the instance structure in
%order to reflect the indexing in the model

%candidate sites and test points
instance.n_cs=n_cs;
instance.n_tp=n_tp;

%budgeting
instance.ris_price = ris_price;
instance.iab_price = iab_price;
instance.sr_price = rel_price;

%access and backhaul masks
instance.bh_p_mask = bh_p_mask;
instance.acc_p_mask = ris_p_mask;
instance.sr_p_mask = af_p_mask;

%downlink and uplink demands
instance.d = ones(n_tp,1).*R_dir_min;
instance.d_ul = ones(n_tp,1).*R_dir_min*0.1;

%distances
instance.cs_tp_dist = cs_tp_distance_matrix';

%angle section
instance.cs_tp_angles = cs_tp_angles;
instance.cs_cs_angles = cs_cs_angles;
instance.smallest_angles = smallest_angles;
instance.angle_span = max_angle_span;

%sr bs panel orientation
sr_minangle=mod(cs_cs_angles+90,360);
instance.sr_minangle=sr_minangle-diag(diag(sr_minangle));

sr_maxangle=mod(cs_cs_angles-90,360);
instance.sr_maxangle=sr_maxangle-diag(diag(sr_maxangle));
%OF weight and degradation factor
instance.OF_weight = OF_weight;
instance.rate_ratio = rate_ratio;

%OF normalization constraints
instance.angle_norm = 180;
instance.length_norm = max(cs_tp_distance_matrix(:));


instance.max_airtime_dl_ris=max_airtime_dl_ris;
instance.max_airtime_ul_ris=max_airtime_ul_ris;

instance.max_airtime_dl_sr = max_airtime_dl_sr;
instance.max_airtime_ul_sr = max_airtime_ul_sr;

%rates
instance.v_los = repmat(direct_rate,1,1,n_cs);
instance.v_nlos = reflected_rate;
%instance.v_nlos_sr=af_rel_rate(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs);
instance.v_nlos_sr=af_rel_rate;

instance.v_los_ul = repmat(direct_rate,1,1,n_cs);
instance.v_nlos_ul = reflected_rate;
%instance.v_nlos_sr=af_rel_rate(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs);
instance.v_nlos_sr_ul=af_rel_rate;

%instance.u=bh_rate;
instance.u = channel.backhaul_rates;

instance.angle_ok = ones(n_tp,n_cs,n_cs); %for now we don't consider the effective mask but a mask made by ones

instance.ris_budget = ris_budget;
instance.sem_budget = sem_budget;
instance.Y_DON = y_don;
instance.Y_IAB = y_iab;

instance.output_filename = [num2str(dataname) '.m'];
%% workspace saving
save([instance_folder dataname]);

end