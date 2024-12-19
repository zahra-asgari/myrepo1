function [instance] = generateInstanceAdversarialMaster(scenario, instance_folder, dataname, rng_seed, adversarial_tp_positioning)
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

%% check in databank if a  instance of this particular scenario was already generated and saved in the cache
% we do this by using md5 hashes of the entire struct, since the name is
% not relaible enough 

% scenario_hash = DataHash(scenario);
% cache_folder = 'cache/instances/';
% 
% if isfile([cache_folder scenario_hash])
%     load([cache_folder scenario_hash]);
% end


%% unpack scenario into workspace
v2struct(scenario);
clear size;
rng(rng_seed);




%% cs and tp

[n_tp,n_cs,cs_positions,tp_positions,cs_cs_distance_matrix, cs_tp_distance_matrix]...
    = cs_tp_generation_adversarial(scenario);

%% Building collision
%if scenario.has_buildings
%    building_collisions;
%end

%% Distance computation


%% Radio channels computation
% pathloss_matrices;
% ris_radio_channels_eugenio;
%
%
% %af_snr_eugenio;
% ris_snr_eugenio;
% direct_snr_eugenio;
% max_rate = max(direct_rate(:));
% bh_snr_eugenio;
%
%
% %fake relay has the same rate as direct comm
% af_rel_rate(:,:,n_cs) = direct_rate(:,:);

[direct_rate,reflected_rate] =...
    channel_computation_eugenio_adversarial(cs_tp_distance_matrix,cs_cs_distance_matrix, scenario);

direct_airtime = permute(repmat(R_dir_min./direct_rate, 1,1,1,n_cs),[1,2,4,3]);
reflected_airtime = (R_dir_min*rate_ratio)./reflected_rate;
max_airtime = max(direct_airtime, reflected_airtime);


max_airtime(max_airtime == Inf) = 0;
reflected_airtime(reflected_airtime == Inf) = 0;

%channels_paolo
%% Rate adaptation section
%rate_adaptation;
%src_dir_back_rate;

%% angles computation

[cs_tp_angles,cs_cs_angles, smallest_angles] ...
    = angles_adversarial(cs_positions, tp_positions);

%% outage-weighted rate

%channel_state_weight_rate;

%% variable pruning
%af_links_angles_pruning;

%src_p_mask = ones(n_tp,n_cs,starting_tp_positioning);
ris_p_mask = true(n_tp,n_cs,n_cs,starting_tp_positioning);
%direct links pruning mask
%direct_p_mask = direct_rate >= R_dir_min;

%refl. links pruning
%af_p_mask  = af_rel_rate >= R_out_min;
%ris_p_mask = reflected_rate >= R_dir_min*rate_ratio;

%angles
% angles_mask_ris = zeros(n_tp,n_cs,n_cs,starting_tp_positioning);
% for p=1:starting_tp_positioning
%     for r=1:n_cs
%         for d=1:n_cs
%             for t=1:n_tp
%                 angles_mask_ris(t,d,r,p) = max([cs_tp_angles(r,t,p) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t,p) cs_cs_angles(r,d)]) <= 2*max_angle_span;
%             end
%         end
%     end
% end
% 
% ris_p_mask = ris_p_mask & angles_mask_ris;
%af_p_mask  = af_p_mask & repmat(direct_p_mask,1,1,n_cs);

% put diagonals to 0
for t=1:n_tp
    for p=1:starting_tp_positioning
        for c=1:n_cs
            ris_p_mask(t,c,c,p) = 0;
        end
    end
end

for p=1:starting_tp_positioning
    for r=1:n_cs
        for d=1:n_cs
            for t=1:n_tp
                ris_p_mask(t,d,r,p) = ris_p_mask(t,d,r,p) & (cs_tp_distance_matrix(d,t,p) <= max_bs_tp_dist) & (cs_tp_distance_matrix(r,t,p) <= max_bs_tp_dist);
            end
        end
    end
end

%% generate instance structure
%some local variables are set as transpose in the instance structure in
%order to reflect the indexing in the model
instance.n_cs=n_cs;
instance.n_tp=n_tp;
instance.n_ps = starting_tp_positioning;

instance.donor_price = donor_price;
instance.ris_price = ris_price;
instance.budget = budget;

instance.acc_p_mask = ris_p_mask;

instance.cs_tp_angles = cs_tp_angles;
instance.cs_cs_angles = cs_cs_angles;
instance.angsep = smallest_angles;
instance.angle_span = max_angle_span;
instance.min_angsep = min_angsep; 

instance.max_airtime = max_airtime;
instance.ris_airtime = reflected_airtime;

instance.A_max = A_max;

instance.output_filename = [num2str(dataname) '.m'];
%% workspace saving
save([instance_folder dataname]);

end
