function [instance] = generateInstanceRISSRUL(scenario, instance_folder, dataname,rng_seed)
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

%% generate instance structure
%some local variables are set as transpose in the instance structìure in
%order to reflect the indexing in the model
instance.n_cs=n_cs;
instance.n_tp=n_tp;

instance.ris_price = ris_price;
instance.iab_price = iab_price;
instance.sr_price = af_price;

instance.L_acc = direct_p_mask;
instance.L_bh = bh_p_mask;

instance.d = ones(n_tp,1).*R_dir_min;
instance.d_ul = ones(n_tp,1).*R_dir_min*0.1;

instance.u = channel.backhaul_rates;
%instance.M_wired = 100000;

instance.cs_tp_angles = cs_tp_angles;
instance.cs_cs_angles = cs_cs_angles;
instance.smallest_angles = smallest_angles;
instance.angle_span = max_angle_span;

instance.cs_tp_dist = cs_tp_distance_matrix';
instance.rate_ratio = rate_ratio;

instance.angle_norm = 180;
instance.length_norm = max(cs_tp_distance_matrix(:));

instance.OF_weight = OF_weight;

instance.v_los = channel.access_rates_full(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs); %matrix of downlink direct rates
instance.v_nlos = channel.access_rates_partial(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs); %matrix of downlink ris assisted rates
instance.v_nlos(instance.v_nlos == 0) = 0.01; %workaround for zeroes out of diag
instance.v_nlos_sr=af_rel_rate(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs); %matrix of downlink sr assisted rates

instance.v_los_ul = channel.access_rates_full(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs); %same as above but for uplink
instance.v_nlos_ul = channel.access_rates_partial(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs);
instance.v_nlos_ul(instance.v_nlos_ul == 0) = 0.01; %workaround for zeros out of diag
instance.v_nlos_sr_ul=af_rel_rate(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs);

%maximum airtime calculation
max_airtime_dl_dir=max(instance.d(1)./instance.v_los(~isinf(instance.d(1)./instance.v_los)),[],'all');
disp(max_airtime_dl_dir);
max_airtime_dl_ris=max(rate_ratio*instance.d(1)./instance.v_nlos(~isinf(instance.d(1)./instance.v_nlos)),[],'all');
max_airtime_dl_sr=max(rate_ratio*instance.d(1)./instance.v_nlos_sr(~isinf(instance.d(1)./instance.v_nlos_sr)),[],'all');

max_airtime_ul_dir=max(instance.d_ul(1)./instance.v_los_ul(~isinf(instance.d_ul(1)./instance.v_los_ul)),[],'all');
max_airtime_ul_ris=max(rate_ratio*instance.d_ul(1)./instance.v_nlos_ul(~isinf(instance.d_ul(1)./instance.v_nlos_ul)),[],'all');
max_airtime_ul_sr=max(rate_ratio*instance.d_ul(1)./instance.v_nlos_sr_ul(~isinf(instance.d_ul(1)./instance.v_nlos_sr_ul)),[],'all');

instance.max_airtime_dl_ris = max(max_airtime_dl_dir, max_airtime_dl_ris);
instance.max_airtime_dl_sr = max(max_airtime_dl_dir, max_airtime_dl_sr);
instance.max_airtime_ul_ris = max(max_airtime_ul_dir, max_airtime_ul_ris);
instance.max_airtime_ul_sr = max(max_airtime_ul_dir, max_airtime_ul_sr);


%instance.angle_ok = orientation_matrix(1:uniform_n_tp,1:uniform_n_cs,1:uniform_n_cs);

%instance.angle_ok = ris_p_mask;
instance.angle_ok = ones(n_tp,n_cs,n_cs); %for now we don't consider the effective mask but a mask made by ones

instance.ris_budget = ris_budget;

%instance.Y_IAB = y_iab;
%instance.Y_DON = y_don;

instance.output_filename = [num2str(dataname) '.m'];
%% workspace saving
save([instance_folder dataname]);

end
