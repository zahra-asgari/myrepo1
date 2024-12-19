function [direct_rates] ...
    = compute_direct_rates_advanced(scenario,tx_position,rx_position,tx_entity,rx_entity,ris_entity)
%COMPUTE_RATES_BASEMODEL This function generates the backhaul and access
%rates according to the advanced pathloss and snr models (see documentation)


n_tp = size(tp_positions,1);
n_cs = size(cs_positions,1);

direct_rates = zeros(n_tp,n_cs);
for t=1:n_tp
    for c=1:n_cs
        %update positions
        rx_entity.update_2d_position(tp_positions(t,:));
        tx_entity.update_2d_position(cs_positions(c,:));
        
        % compute direct rate
        direct_snr = direct_channel_snr(tx_entity, rx_entity, ris_entity, scenario.radio_prm);
        direct_rates(t,c) = ...
            scenario.radio_prm.BW * log2(1+10^(0.1*direct_snr));
    end
% check if rx entity and tx entity are the same object, if so we need to
% make a copy
if tx_entity == rx_entity % use == when you want to determine if handle variables refer to the same object 
    rx_entity = copy(rx_entity);
end



%update positions
rx_entity.update_2d_position(rx_position);
tx_entity.update_2d_position(tx_position);

% compute direct rate
direct_snr = direct_channel_snr(tx_entity, rx_entity, ris_entity, scenario.radio_prm);
direct_rates = ...
    scenario.radio_prm.BW * log2(1+10.^(0.1.*direct_snr));

% convert to mbps
direct_rates = direct_rates.*1e-6;


end

