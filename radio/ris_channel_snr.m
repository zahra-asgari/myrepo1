function [snr] = ris_channel_snr(tx_entity,rx_entity,srd_entity,radio_prm)
%RIS_CHANNEL_SNR Summary of this function goes here
%   Detailed explanation goes here


% eugenio-reza interface
radio_prm.Tx = tx_entity;
radio_prm.Rx = rx_entity;
radio_prm.RIS = srd_entity;


% optimize orientation if needed
if strcmp(srd_entity.Orientation, 'Specular')
    srd_entity.Orientation = ...
        ris_specular_orientation(tx_entity.Center(:,1:2),rx_entity.Center(:,1:2),srd_entity.Center(:,1:2));
end

% % Configurations
% Config = SetArrayConf(radio_prm);
% Config.Policy = srd_entity.SRD_properties.reconf_policy;
% Config.ElementDirectivity = radio_prm.ElementDirectivity;
% 
% radio_prm.RIS.Center = radio_prm.relay_pos;
% radio_prm.RIS.Plane = 'yz';
% [Distances,Vectors] = Define_Distances(radio_prm,Config);
% Angles = Define_Angles(Distances,Vectors);
% Phi_Direct = 0;
% H_RIS = Compute_RIS_Channel(Angles,Distances,radio_prm,Phi_Direct,Config);

radio_prm.RIS.Center = radio_prm.RIS.Center;
if ~isprop(radio_prm.RIS,'Plane')
    radio_prm.RIS.addprop('Plane');
    radio_prm.RIS.Plane = 'yz';
end
[Distances,Vectors,prm] = Define_Distances(radio_prm);
Angles = Define_Angles(Distances,Vectors);
H_RIS = Compute_RIS_Channel(Angles,Distances,prm,0);

[~,S_ris,~] = svd(H_RIS);
P_ris = trace(S_ris(1,1).^2);
Pn_at_UE = -174 + 10*log10(radio_prm.BW) + radio_prm.Rx.NF;     % noise power

snr = 10 .* log10(P_ris ./ db2pow(Pn_at_UE));

end

