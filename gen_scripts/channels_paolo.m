
lin_power_mW = 10^((p_tx)/10);
channel.cs_tp_pathloss_LOS = zeros(n_cs,n_tp);
channel.cs_cs_pathloss_LOS = zeros(n_cs,n_cs);
channel.phi = zeros(n_cs,n_tp);
channel.theta = ones(n_tp,n_cs,n_cs).*pi/4;
channel.gamma = ones(n_tp,n_cs,n_cs);
channel.links_cs_tp = zeros(n_cs,n_tp);
channel.links_cs_cs = zeros(n_cs,n_cs);
channel.access_rates_full = zeros(n_tp,n_cs,n_cs);
channel.access_rates_partial = zeros(n_tp,n_cs,n_cs);
channel.access_rates_no_RIS = zeros(n_tp,n_cs);
channel.backhaul_rates = zeros(n_cs,n_cs);
channel.max_length=0;
%alpha and beta parameters of the model
alpha = n_antennas*ris_components^2*(pi/4) + n_antennas*ris_components*(1-pi/4);
beta  = 2*ris_components*sqrt(n_antennas);


%MCSs info

MCS_th_dB      = [ -11.5464 -10.2494 -9.2269 -8.0868 -7.1586 -6.0145 -5.0724 -3.7157 -2.6298 -1.1819 0.01604 1.3086 2.4409 3.5727 4.6086 5.6086 6.5379 7.8452 9.0994 10.4644 11.7946 12.6461 13.51 15.0653 16.574 18.0413 19.5304 21.1033 22.6712 24.148 25.652 26.7423 27.8618 29.5493 31.2366 32.9621 34.6877 35.9228 37.1578 ];

MCS_rate_mbps   = [ 23.2056 30.9276 38.6892 49.5 60.3108 76.5864 92.8224 121.4136 149.292 194.1192 238.2336 293.1192 347.292 406.8108 465.6168 525.9276 584.7336 671.3388 757.9836 855.4392 952.8948 1016.2944 1081.278 1199.6028 1315.6308 1429.3224 1545.3108 1668.3084 1791.2664 1907.2944 2025.6192 2111.472 2199.6612 2332.6776 2465.7336 2601.8388 2737.9836 2835.4392 2932.8948 ];

n_MCS = size(MCS_th_dB ,2);

%radio
n_antennas = 64;
p_tx = 30; %dBm
p_noise_bh = -84; %dBm -84 RN -82 UE
p_noise_acc = -82;

%%

%disp("Generating channel number "+num2str(inst)+"...");



%DIRECT TP_CS channels

%cs_tp pathloss matrix
channel.cs_tp_pathloss_LOS(:,:) = pathloss(cs_tp_distance_matrix(:,:),'linear','los');

%cs_cs pathloss matrix
channel.cs_cs_pathloss_LOS(:,:) = pathloss(cs_cs_distance_matrix(:,:),'linear','los');

%channel.phi parameters
channel.phi(:,:) = n_antennas.*channel.cs_tp_pathloss_LOS(:,:);

%channel.theta parameters
%we have one channel.theta for each donor-rs-tp triplet

for d=1:n_cs
    for r=1:n_cs
        for t=1:n_tp
            channel.theta(t,d,r) = ...
                sqrt(channel.cs_cs_pathloss_LOS(d,r))*sqrt(pi)/2*...  %this is donor-ris
                sqrt(channel.cs_tp_pathloss_LOS(d,t))*...              %this is ris-tp
                sqrt(channel.cs_tp_pathloss_LOS(r,t));                 %this is donor-tp
        end
    end
end

% channel.gamma parameters
%we have one channel.gamma for each donor-rs-tp triplet

for d=1:n_cs
    for r=1:n_cs
        for t=1:n_tp
            channel.gamma(t,d,r)= ...
                channel.cs_tp_pathloss_LOS(r,t)*... ris_tp
                channel.cs_cs_pathloss_LOS(d,r);
        end
    end
end

%finally we multiply by snr_at_tx and alpha or beta in order to have snr contributions
channel.gamma(:,:,:) = channel.gamma(:,:,:).*lin_power_mW.*alpha;
channel.theta(:,:,:) = channel.theta(:,:,:).*lin_power_mW.*beta;
channel.phi(:,:) = channel.phi(:,:).*lin_power_mW;

%% link establishment computation


%just use the received power and compare it to the sensitivity of
%the Wigig MCS list (when we'll have a better way of determining
%the actual MCS used in 5g with respect also to bandwidth and noise
%power, we'll use them
probs =  channel_state_prob(cs_tp_distance_matrix(:,:));
channel.links_cs_tp(:,:) = (probs.p_nlos<= 0.9 & probs.p_out <= 0);
MISO_rx_power = 10*log10(channel.gamma(:,:,:) + channel.theta(:,:,:) +repmat(channel.phi(:,:)',1,1,n_cs));
access_rates_full_temp = zeros(n_tp,n_cs,n_cs);
access_rates_partial_temp = zeros(n_tp,n_cs,n_cs);

for t = 1:n_MCS
    access_rates_full_temp(MISO_rx_power - p_noise_acc>= MCS_th_dB(t)) = MCS_rate_mbps(t);
    access_rates_partial_temp(10*log10(channel.gamma(:,:,:)) - p_noise_acc>= MCS_th_dB(t)) = MCS_rate_mbps(t);
end

channel.access_rates_full(:,:,:) = access_rates_full_temp;
channel.access_rates_partial(:,:,:) = access_rates_partial_temp;

access_rates_no_RIS_temp = zeros(n_tp,n_cs);
MISO_rx_power = p_tx + 10*log10(channel.cs_tp_pathloss_LOS(:,:)*n_antennas);
for t = 1:n_MCS
    access_rates_no_RIS_temp(MISO_rx_power - p_noise_acc >= MCS_th_dB(t)) = MCS_rate_mbps(t);
end

channel.access_rates_no_RIS(:,:) = access_rates_no_RIS_temp;

MISO_rx_power = p_tx + 10*log10(channel.cs_cs_pathloss_LOS(:,:)*n_antennas);
probs =  channel_state_prob(cs_cs_distance_matrix(:,:));
channel.links_cs_cs(:,:) = (probs.p_nlos<= 0.9 & probs.p_out <= 0);
backhaul_rates_temp=zeros(n_cs,n_cs);
for t = 1:n_MCS
    backhaul_rates_temp(MISO_rx_power - p_noise_bh >= MCS_th_dB(t)) = MCS_rate_mbps(t);
end
channel.backhaul_rates(:,:) = backhaul_rates_temp;
for c=1:n_cs
    
    channel.access_rates_full(:,c,c) = 0;
    channel.access_rates_partial(:,c,c) = 0;
    channel.backhaul_rates(c,c) = 0;
    channel.links_cs_cs(c,c) = 0;
    
end

