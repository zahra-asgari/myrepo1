function [ris_rate] ...
    = compute_ris_rates_advanced(scenario,tx_position,rx_position,ris_position,tx_entity,rx_entity,ris_entity)
%COMPUTE_RATES_BASEMODEL This function generates the backhaul and access
%rates according to the advanced pathloss and snr models (see documentation)


%update positions
rx_entity.update_2d_position(rx_position);
tx_entity.update_2d_position(tx_position);
ris_entity.update_2d_position(ris_position);

<<<<<<< Updated upstream
ris_snr = zeros(n_tp,n_cs,n_cs);
tot=n_tp*n_cs*n_cs;
it = 0;

for t=1:n_tp
    for c=1:n_cs
        for r=1:n_cs
            if r==c
                ris_snr(t,c,r) = 0;
            else
                %update positions
                rx_entity.update_2d_position(tp_positions(t,:));
                tx_entity.update_2d_position(cs_positions(c,:));
                ris_entity.update_2d_position(cs_positions(r,:));
                
                % compute snr
                ris_snr(t,c,r) = ris_channel_snr(tx_entity, rx_entity, ris_entity, scenario.radio_prm);
                
            end
            it=it+1;
        end
    end
    disp(it/tot);
end
ris_snr( ris_snr < 0 ) = 0;
ris_rates = ...
  scenario.radio_prm.BW * log2(1+10^(0.1*ris_snr));
% convert to mbps
ris_rate = ris_rate.*1e-6;


end

