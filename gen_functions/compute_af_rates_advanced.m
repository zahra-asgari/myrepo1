function [af_rates] ...
    = compute_af_rates_advanced(scenario,cs_positions,tp_positions,tx_entity,rx_entity,af_entity)
%COMPUTE_RATES_BASEMODEL This function generates the backhaul and access
%rates according to the advanced pathloss and snr models (see documentation)


n_tp = size(tp_positions,1);
n_cs = size(cs_positions,1);

af_snr = zeros(n_tp,n_cs,n_cs);
tot=n_tp*n_cs*n_cs;
it = 0;

for t=1:n_tp
    for c=1:n_cs
        for r=1:n_cs
            if r==c
                af_snr(t,c,r) = 0;
            else
                %update positions
                rx_entity.update_2d_position(tp_positions(t,:));
                tx_entity.update_2d_position(cs_positions(c,:));
                af_entity.update_2d_position(cs_positions(r,:));
                
                % compute snr
                af_snr(t,c,r) = af_channel_snr(tx_entity, rx_entity, af_entity, scenario.radio_prm);
                
            end
            it=it+1;
        end
    end
    disp(it/tot);
end
af_snr( af_snr < 0 ) = 0;
af_rates = ...
  scenario.radio_prm.BW * log2(1+10^(0.1.*af_snr));
% convert to mbps
af_rates = af_rates.*1e-6;


end

