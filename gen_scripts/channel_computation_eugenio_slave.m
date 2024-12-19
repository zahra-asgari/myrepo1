function [direct_rate,reflected_rate] = channel_computation_eugenio_slave(cs_tp_distance_matrix,cs_cs_distance_matrix, scenario)
%CHANNEL_COMPUTATION_EUGENEIO_ADVERSARIAL Summary of this function goes here
%   Detailed explanation goes here

[n_cs, n_tp] = size(cs_tp_distance_matrix);

direct_rate = zeros(n_tp,n_cs);
reflected_rate = zeros(n_tp,n_cs,n_cs);

%% generate the entire channel for each tp positioning configuration

%cs_cs pathloss matrix
cs_cs_pathloss_LOS = pathloss(cs_cs_distance_matrix,'linear','los');
%cs_cs_pathloss_nLOS = pathloss(cs_cs_distance_matrix,'linear','nlos');

n_antennas = scenario.n_antennas;
ris_components = scenario.ris_components;
p_tx = scenario.p_tx;
bandwidth = scenario.bandwidth;
ue_noise_fig = scenario.ue_noise_fig;
bs_noise_fig = scenario.bs_noise_fig;

alpha_radio = n_antennas*ris_components^2*(pi/4) + n_antennas*ris_components*(1-pi/4);
beta  = 2*ris_components*sqrt(n_antennas);



%cs_tp pathloss matrix
cs_tp_pathloss_LOS = pathloss(cs_tp_distance_matrix(:,:),'linear','los');
%cs_tp_pathloss_NLOS = pathloss(cs_tp_distance_matrix(:,:,p),'linear','nlos');

%PHI parameters
phi_LOS = n_antennas.*cs_tp_pathloss_LOS;


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
direct_rate(:,:) = direct_r;
reflected_rate(:,:,:) = ris_rate;



end

