function [snr] = direct_channel_snr(tx_entity,rx_entity,srd_entity,radio_prm)
%DIRECT_CHANNEL_SNR Summary of this function goes here
%   Detailed explanation goes here

% eugenio-reza interface
radio_prm.Tx = tx_entity;
radio_prm.Rx = rx_entity;
radio_prm.RIS = srd_entity;
radio_prm.AF = Network_Entity('AF',[0,0,0], radio_prm,'Orientation','Optimum','Type','Option1');
% radio_prm.Tx.Pos = tx_entity.position;
% radio_prm.Rx.Pos = rx_entity.position;
% radio_prm.relay_pos = srd_entity.position;


Pn_at_UE = -174 + 10*log10(radio_prm.BW) + radio_prm.Rx.NF;     % noise power
H_D = Compute_Direct_Channel(radio_prm,radio_prm.PL_models);      % MIMO channel Matrix
snr = 10 .* log10(H_D^2 ./ db2pow(Pn_at_UE));

end

