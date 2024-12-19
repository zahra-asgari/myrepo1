function [instance] = generateInstanceFixedBS(scenario, instance_folder, dataname,rng_seed)
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


%unpack scenario into workspace
v2struct(scenario);
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

channels_paolo;

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

%% load step1 solution 
run_id = dataname(2:end);
run(['solved_instances/iab_minlen_wbudget_s1/tesipaolo2_20runs/solutions/iab_only_minlen_r' run_id '.m']);
%% generate instance structure
%some local variables are set as transpose in the instance structìure in
%order to reflect the indexing in the model
instance.n_cs=n_cs;
instance.n_tp=n_tp;

instance.donor_price = donor_price;
instance.iab_price = iab_price;

instance.L_acc = direct_p_mask;
instance.L_bh = bh_p_mask;

instance.d = ones(n_tp,1).*R_dir_min;

instance.u = channel.backhaul_rates; %u is backhaul channel 
instance.M_wired = 100000;

instance.cs_tp_angles = cs_tp_angles;
instance.cs_cs_angles = cs_cs_angles;
instance.smallest_angles = smallest_angles;
instance.angle_span = max_angle_span;

instance.cs_tp_dist = cs_tp_distance_matrix';
instance.rate_ratio = rate_ratio;

instance.angle_norm = 180;
instance.length_norm = max(cs_tp_distance_matrix(:));

instance.OF_weight = OF_weight;

%instance.v_los = ris_rate;
%instance.v_nlos = repmat(direct_rate,1,1,n_cs);

instance.v_los = channel.access_rates_full(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs); %v_los is the direct link communication in src
instance.v_nlos = channel.access_rates_partial(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs); %v_nlos channel is the reflected link communication in src
%instance.angle_ok = orientation_matrix(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs);

%instance.angle_ok = ris_p_mask;
instance.angle_ok = ones(n_tp,n_cs,n_cs); %for now we don't consider the effective mask but a mask made by ones

instance.ris_budget = ris_budget;

instance.Y_IAB = y_iab;
instance.Y_DON = y_don;




%
%
% if leaner_af_model
%     %%
%     instance.n_f = 2;
%
%     instance.donor_price = donor_price;
%     instance.ris_price = [ris_price af_price]';
%     instance.budget = budget;
%
%     instance.cs_tp_angles = cs_tp_angles;
%     instance.cs_cs_angles = cs_cs_angles;
%     instance.smallest_angles = smallest_angles;
%     instance.angle_span = max_angle_span;
%     %instance.min_angle_threshold = min_angle_threshold;
%
%     instance.cs_cs_dist = cs_cs_distance_matrix;
%     instance.cs_tp_dist = cs_tp_distance_matrix';
%     instance.max_dist = max_dist;
%
%     instance.max_rate = max_rate;
%     instance.R_out_min = R_out_min;
%     instance.R_dir_min = R_dir_min;
%
%     instance.ris_src_act = cat(4,ris_p_mask,af_p_mask);
%     instance.dir_rate = repmat(direct_rate,1,1,n_cs,2);
%     instance.ris_rate = cat(4,ris_rate,af_rel_rate);
%
% else
%
%     instance.donor_price = donor_price.*ones(n_cs,1);
%     instance.ris_price = ris_price.*ones(n_cs,1);
%     instance.budget = budget;
%     if has_relays
%         instance.af_price = af_price;
%     end
%
%     %instance.L_acc = links_cs_tp';
%     %instance.L_bh = links_cs_cs;
%
%     % instance.alpha = alpha;
%     % instance.beta = beta;
%     %
%     % instance.gamma = gamma;
%     % instance.theta_los = theta_LOS;
%     % instance.theta_nlos = theta_NLOS;
%     % instance.phi_los = phi_LOS';
%     % instance.phi_nlos = phi_NLOS';
%
%     %instance.gamma = gamma_radio;
%     %instance.theta = theta_LOS;
%     %instance.phi = phi_LOS';
%
%
%     %opl cannot handle inf values, so we set it to zero (no issue because these values will never be used, since they are on diagonals)
%     %instance.gamma(instance.gamma == inf) = 0;
%     % instance.theta_los(instance.theta_los == inf) = 0;
%     %instance.theta(instance.theta == inf) = 0;
%     % instance.theta_nlos(instance.theta_nlos == inf) = 0;
%     % instance.phi_los(instance.phi_los == inf) = 0;
%     %instance.phi(instance.phi == inf) = 0;
%     % instance.phi_nlos(instance.phi_nlos == inf) = 0;
%
%     instance.cs_tp_angles = cs_tp_angles;
%     instance.cs_cs_angles = cs_cs_angles;
%     instance.smallest_angles = smallest_angles;
%     instance.angle_span = max_angle_span;
%     %instance.min_angle_threshold = min_angle_threshold;
%
%     instance.cs_cs_dist = cs_cs_distance_matrix;
%     instance.cs_tp_dist = cs_tp_distance_matrix';
%     instance.max_dist = max_dist;
%
%     %instance.P = 10^(0.1*p_tx);
%     % instance.min_snr_peak = snr_peak_LOS.*ones(n_tp,1);
%     % instance.min_snr_avg = snr_avg_LOS.*ones(n_tp,1);
%     % instance.los_nlos_peak_ratio = los_nlos_peak_ratio;
%     % instance.los_nlos_avg_ratio = los_nlos_avg_ratio;
%
%     %instance.K = K;
%
%     %instance.n_mcs = n_mcs;
%     %instance.pwr_thr = pwr_thr;
%     %instance.rate_mcs = mcs_rate;
%     instance.max_rate = max_rate;
%     instance.R_out_min = R_out_min;
%     instance.R_dir_min = R_dir_min;
%
%     if has_relays
%         instance.ris_src_act = ris_p_mask;
%         instance.af_src_act  = af_p_mask;
%         instance.dir_rate = repmat(direct_rate,1,1,n_cs);
%         instance.ris_rate = ris_rate;
%         instance.af_rate  = af_rel_rate;
%     end
%
%
%     if scenario.singleRis
%         instance.base_rate = expected_rate_woris;
%         instance.additional_ris_rate = differential_rate;
%         instance.los_rate = los_rate;
%         instance.outage_rate = outage_rate;
%     end
%
%     if scenario.tuplematic
%         instance.capacity = expected_rate_wris;
%         instance.capacity(instance.capacity < 0) = 0;
%         instance.capacity(isnan(instance.capacity)) = 0;
%     end
%
%     if scenario.fakeris
%         instance = [];
%         instance.n_cs=n_cs;
%         instance.n_tp=n_tp;
%
%         instance.fakeris_id = n_cs; %the last ris is fake
%
%         instance.donor_price = donor_price.*ones(n_cs,1);
%         instance.ris_price = ris_price.*ones(n_cs,1);
%         instance.budget = budget;
%
%         %installing the fake ris costs nothing
%         instance.donor_price(n_cs) = 0;
%         instance.ris_price(n_cs) = 0;
%
%         instance.L_acc = links_cs_tp';
%         instance.L_bh = links_cs_cs;
%
%         %fakeris can connect to any donor
%         instance.L_bh(n_cs, :) = ones(size(instance.L_bh(n_cs, :)));
%         instance.L_bh(:, n_cs) = ones(size(instance.L_bh(:, n_cs)))';
%
%         %fakeris can connect to any tp
%         instance.L_acc(:, n_cs) = ones(size(instance.L_acc(:, n_cs)));
%
%         instance.rates = expected_rate_wris;
%         instance.max_rate = max_rate;
%         instance.R_out_min = R_out_min;
%         instance.donor_rates = expected_rate_woris; %this is for noris model
%
%         %fakeris rate is simply the donor rate
%         instance.rates(:,:,n_cs) = expected_rate_woris(:,:);
%
%         %nan rates to 0
%         instance.rates(isnan(instance.rates)) = 1;
%
%         instance.cs_tp_angles = cs_tp_angles;
%         instance.cs_cs_angles = cs_cs_angles;
%         instance.angle_span = max_angle_span;
%
%         instance.s_angle_ok = s_angle_ok;
%     end
% end
instance.output_filename = [num2str(dataname) '.m'];
%% workspace saving
save([instance_folder dataname]);

end
