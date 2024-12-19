function [instance,temp_mask] = integrateAversarialPositioning(instance_folder, dataname,datapath,adver_tp_pos)
%INTEGRATEAVERSARIALPOSITIONING Summary of this function goes here
%   Detailed explanation goes here

%% load the instance
load([datapath(1:end-4)]);

%% add new tp positions to tp_positions
%disp(adver_tp_pos);
p=size(tp_positions,3)+1;

tp_positions(:,:,p) = adver_tp_pos;


%% compute new distances

cs_tp_distance_matrix(:,:,p) = pdist2(cs_positions, adver_tp_pos);

%% compute new capacities

cs_tp_pathloss_LOS = pathloss(cs_tp_distance_matrix(:,:,p),'linear','los');
cs_cs_pathloss_LOS = pathloss(cs_cs_distance_matrix,'linear','los');
%cs_tp_pathloss_NLOS = pathloss(cs_tp_distance_matrix(:,:,p),'linear','nlos');

%PHI parameters
phi_LOS = n_antennas.*cs_tp_pathloss_LOS;

n_antennas = scenario.n_antennas;
ris_components = scenario.ris_components;
p_tx = scenario.p_tx;
bandwidth = scenario.bandwidth;
ue_noise_fig = scenario.ue_noise_fig;
bs_noise_fig = scenario.bs_noise_fig;

alpha_radio = n_antennas*ris_components^2*(pi/4) + n_antennas*ris_components*(1-pi/4);
beta  = 2*ris_components*sqrt(n_antennas);


%THETA parameters
%we have one theta for each donor-rs-tp triplet
theta_LOS = ones(n_tp,n_cs,n_cs).*pi/4;

for d=1:n_cs
    for r=1:n_cs
        for t=1:n_tp
            theta_LOS(t,d,r) = ...
                sqrt(cs_cs_pathloss_LOS(d,r))*sqrt(pi)/2*...  %this is donor-ris
                sqrt(cs_tp_pathloss_LOS(d,t))*...              %this is ris-tp
                sqrt(cs_tp_pathloss_LOS(r,t));                 %this is donor-tp
        end
    end
end

% GAMMA parameters
%we have one gamma for each donor-rs-tp triplet
gamma_radio = ones(n_tp,n_cs,n_cs);

for d=1:n_cs
    for r=1:n_cs
        for t=1:n_tp
            gamma_radio(t,d,r) = ...
                cs_tp_pathloss_LOS(r,t)*... ris_tp
                cs_cs_pathloss_LOS(d,r);
        end
    end
end


%finally we multiply by ptx_lin and alpha or beta in order to rx_power
%contributions (linear)
ptx_lin = 10^(0.1*p_tx);
gamma_radio = gamma_radio.*ptx_lin.*alpha_radio;
theta_LOS = theta_LOS.*ptx_lin.*beta;
phi_LOS = phi_LOS.*ptx_lin;

% now the ris rates and direct rates
ue_noise_lin = 10^(0.1 * ( -174 + 10*log10(bandwidth) + ue_noise_fig));
ris_snr = gamma_radio./ue_noise_lin;
ris_rate = bandwidth.*log2(1+ris_snr)./1e6;
ris_rate (ris_rate == inf) = 0;

direct_snr = zeros(n_tp,n_cs);
p_tx_lin = 10^(0.1*p_tx);
bs_noise = -174 + 10*log10(bandwidth) + bs_noise_fig;
bs_noise_lin = 10^(0.1*bs_noise);

for t=1:n_tp
    for d = 1:n_cs
        direct_snr(t,d) = (n_antennas * p_tx_lin * cs_tp_pathloss_LOS(d,t))/bs_noise_lin;
    end
end

direct_r = bandwidth.*log2(1+direct_snr)./1e6;

% now finalize
direct_rate(:,:,p) = direct_r;
reflected_rate(:,:,:,p) = ris_rate;

direct_airtime = permute(repmat(R_dir_min./direct_rate, 1,1,1,n_cs),[1,2,4,3]);
reflected_airtime = (R_dir_min*rate_ratio)./reflected_rate;
max_airtime = max(direct_airtime, reflected_airtime);


max_airtime(max_airtime == Inf) = 0;
reflected_airtime(reflected_airtime == Inf) = 0;

%% compute new angles

for n=1:n_cs
    offset = cs_positions(n,:);
    for t=1:n_tp
        %everything will be referenced to the position of the cs, so we
        %need an offset
        relative_tp_position = tp_positions(t,:,p) - offset;
        %now it is like computing the angle of a vector having coordinates relative_tp_position
        cs_tp_angles(n,t,p) = angle(relative_tp_position(1) +1i*relative_tp_position(2))*180/pi; %1i is the imaginary unit
        if cs_tp_angles(n,t,p) < 0
            cs_tp_angles(n,t,p) = cs_tp_angles(n,t,p) + 360;
        end
    end
end

for t=1:n_tp
    for n1=1:n_cs
        for n2=1:n_cs
            %tp as reference
            offset = tp_positions(t,:,p);
            %compute angle with n1
            relative_cs_position = cs_positions(n1,:) - offset;
            a1 = angle(relative_cs_position(1) + 1i*relative_cs_position(2))*180/pi;
            if a1 <0
                a1 = a1+360;
            end
            %compute angle with n2
            relative_cs_position = cs_positions(n2,:) - offset;
            a2 = angle(relative_cs_position(1) + 1i*relative_cs_position(2))*180/pi;
            if a2 <0
                a2 = a2+360;
            end
            %compute smallest angle
            smallest_angles(t,n1,n2,p) = abs(a1-a2);
            if smallest_angles(t,n1,n2,p) > 180
                smallest_angles(t,n1,n2,p) = 360 - smallest_angles(t,n1,n2,p);
            end
        end
    end
end

%% recompute variable pruning
%% variable pruning
%af_links_angles_pruning;

%src_p_mask = ones(n_tp,n_cs,starting_tp_positioning);

%direct links pruning mask
%direct_p_mask = direct_rate >= R_dir_min;

%refl. links pruning
%af_p_mask  = af_rel_rate >= R_out_min;
%ris_p_mask = reflected_rate >= R_dir_min*rate_ratio;
%ris_p_mask = true(n_tp, n_cs, n_cs);

%angles
temp_mask = true(n_tp, n_cs, n_cs);
for r=1:n_cs
    for d=1:n_cs
        for t=1:n_tp
            %temp_mask(t,d,r) = max([cs_tp_angles(r,t,p) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t,p) cs_cs_angles(r,d)]) <= 2*max_angle_span;
            temp_mask(t,d,r) = temp_mask(t,d,r) & (cs_tp_distance_matrix(d,t,p) <= max_bs_tp_dist) & (cs_tp_distance_matrix(r,t,p) <= max_bs_tp_dist);
            temp_mask(t,d,r) = temp_mask(t,d,r) & max_airtime(t,d,r) <= 1;
        end
    end
end

ris_p_mask(:,:,:,p) = temp_mask;

% ris_p_mask = ris_p_mask & angles_mask_ris;
% %af_p_mask  = af_p_mask & repmat(direct_p_mask,1,1,n_cs);


% put diagonals to 0
for t=1:n_tp
    for c=1:n_cs
        ris_p_mask(t,c,c,p) = 0;
    end
end

%% generate instance structure
instance.n_cs=n_cs;
instance.n_tp=n_tp;
instance.n_ps = p;

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
instance.output_filename = [num2str(dataname) '.m'];
%% workspace saving
%save([instance_folder dataname]);
avoidVariable= 'adver_tp_pos';
save([instance_folder dataname],'-regexp', ['^(?!', avoidVariable,'$).'])
end

