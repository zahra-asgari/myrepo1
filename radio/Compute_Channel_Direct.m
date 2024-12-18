% function [H_D,H_RIS,SNR] = Compute_Channel(prm,Scenario)
function [SNR,Blockage] = Compute_Channel_Direct(Params,Scenario)

epsilon = 1e-10;
if ~isprop(Params.Rx,'Role')
    Params.Rx.addprop('Role');
    Params.Rx.Role = 'Rx';
end

if ~isprop(Params.Tx,'Role')
    Params.Tx.addprop('Role');
    Params.Tx.Role = 'Tx';
end

[Distances,Angles,Params] = Define_Distances(Params);
Pn_at_UE = -174 + 10*log10(Params.comm.BW) + Params.Rx.NF;     % noise power
%% Static Blockage Check
 
if Params.Config.Check_Static_Blockage
    Static_Blockage_Dir = Static_Blockage_Check(Params,'Direct');
    Static_Blockage_Relay = Static_Blockage_Check(Params,'Relay'); 
elseif ~Params.Config.Check_Static_Blockage
    Static_Blockage_Dir.Event = false;
    Static_Blockage_Relay.Event = false;
end

%% DL Channel


% Static_Blockage_Dir = Static_Blockage_Check(Params,'Direct');
if (~Static_Blockage_Dir.Event) 
    [H_D,Dynamic_Blockage_Dir] = Compute_Direct_Channel(Params,Angles,Distances,Scenario);      % MIMO channel Matrix
    Phi_Direct = 0;
    Blockage.Direct = Dynamic_Blockage_Dir;
elseif Static_Blockage_Dir.Event 
    H_D = 0;
    Phi_Direct = 0;
    Blockage.Direct = Static_Blockage_Dir;
else
    error('Unknown Static Blockage Situation')
end



%% Assign Channels
% Channel.Direct = H_D;
% Channel.RIS = H_RIS;
% Channel.AF_max = H_AF_max;
% Channel.AF_min = H_AF_min;



%% Assign SNRs
Pow_dir = H_D^2;
SNR.DL = 10 .* log10(Pow_dir ./ db2pow(Pn_at_UE));


end
