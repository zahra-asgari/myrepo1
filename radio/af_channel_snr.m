function [snr] = af_channel_snr(tx_entity,rx_entity,srd_entity,radio_prm)
%AF_CHANNEL_SNR Summary of this function goes here
%   Detailed explanation goes here

%assert if the srd entity is a ris
assert(strcmp(srd_entity.type,'af_type_1') || strcmp(srd_entity.type,'af_type_2'),...
    'Srd_entity is not a RIS');

% eugenio-reza interface
radio_prm.Tx = tx_entity.Tx;
radio_prm.Rx = rx_entity.Rx;
radio_prm.AF = srd_entity.AF;
radio_prm.Tx.Pos = tx_entity.pos;
radio_prm.Rx.Pos = rx_entity.pos;
radio_prm.relay_pos = srd_entity.pos;


Panel2Tilt = 0;
Panel2Rot = 0;
[H_AF, NoisePower_AF, ~, ~] = AF_Channel(radio_prm ,'UMa', 'UMi', radio_prm.AF.Type,Panel2Rot,Panel2Tilt);
snr = 10 .* log10(H_AF^2 ./ NoisePower_AF);
end

