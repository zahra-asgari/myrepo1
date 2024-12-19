% function [H_D,H_RIS,SNR] = Compute_Channel(prm,Scenario)
function [Channel,SNR,Blockage] = Compute_Channel(Params,Scenario)

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

%% IRS Channel

if ~Static_Blockage_Relay.Event 
    %%%%%%% RIS Channel %%%%%%%
    [Params,RIS_Serves] = Set_RIS(Params,Angles);
    if RIS_Serves
        [H_RIS,Dynamic_Blockage_RIS] = Compute_RIS_Channel(Angles,Distances,Params,Phi_Direct);
        Blockage.RIS = Dynamic_Blockage_RIS;
    else
        H_RIS = 0;
    end
    
    %%%%%%% AF Channel %%%%%%%
    
    Panel2Tilt = 0;
    Panel2Rot = 0;
    % % % [H_AF, NoisePower_AF, ~, ~] = AF_Channel(prm ,'UMa', 'UMi', 'Option1',Panel2Rot,Panel2Tilt);
    [H_AF_max, NoisePower_AF_max,H_AF_min, NoisePower_AF_min,Dynamic_Blockage_AF] = Compute_AF_Channel(Params,Angles, Distances ,'UMa', 'UMi', 'Option1',Panel2Rot,Panel2Tilt);
    % % % % % [SNR.DF, ~] = DF_Channel(prm, 'UMa','UMi', 'Option1',Panel2Rot,Panel2Tilt);
    Blockage.AF = Dynamic_Blockage_AF;
elseif Static_Blockage_Relay.Event 
    H_RIS = 0;
    Blockage.Direct = Static_Blockage_Relay;
    H_AF_max = 0;
    NoisePower_AF_max = epsilon;
    H_AF_min = 0;
    NoisePower_AF_min = epsilon;
    Blockage.RIS = Static_Blockage_Relay;
    Blockage.AF = Static_Blockage_Relay;
end


%% Assign Channels
Channel.Direct = H_D;
Channel.RIS = H_RIS;
Channel.AF_max = H_AF_max;
Channel.AF_min = H_AF_min;



%% Assign SNRs
Pow_dir = H_D^2;
Pow_AF_min = H_AF_min^2;
Pow_AF_max = H_AF_max^2;
[~,S_ris,~] = svd(H_RIS);
P_ris = trace(S_ris(1,1).^2);
SNR.DL = 10 .* log10(Pow_dir ./ db2pow(Pn_at_UE));
SNR.RIS = 10 .* log10(P_ris ./ db2pow(Pn_at_UE));
SNR.AF_min = 10 .* log10(Pow_AF_min ./ NoisePower_AF_min);
SNR.AF_max = 10 .* log10(Pow_AF_max ./ NoisePower_AF_max);


end
