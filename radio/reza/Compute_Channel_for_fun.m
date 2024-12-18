% function [H_D,H_RIS,SNR] = Compute_Channel(prm,Scenario)
function [Channel,SNR,Blockage] = Compute_Channel_for_fun(Params,Scenario)
% global DIS
if ~isprop(Params.Rx,'Role')
    Params.Rx.addprop('Role');
    Params.Rx.Role = 'Rx';
end

if ~isprop(Params.Tx,'Role')
    Params.Tx.addprop('Role');
    Params.Tx.Role = 'Tx';
end

[Distances,Angles,Params] = Define_Distances(Params,Params.RIS);
Pn_at_UE = -174 + 10*log10(Params.comm.BW) + Params.Rx.NF;     % noise power
%% Static Blockage Check



%% DL Channel


% Static_Blockage_Dir = Static_Blockage_Check(Params,'Direct');

[H_D,Dynamic_Blockage_Dir] = Compute_Direct_Channel(Params,Angles,Distances,Scenario);      % MIMO channel Matrix
Phi_Direct = 0;
Blockage.Direct = Dynamic_Blockage_Dir;


%% IRS Channel



[Params,RIS_Serves] = Set_RIS(Params,Angles);
% DIS = [DIS,Params.RIS.Dis.RxCenter2RISCenter_3D];
if RIS_Serves
    [H_RIS,~] = Compute_RIS_Channel(Params,Params.RIS,Phi_Direct);
%     Blockage.RIS = Dynamic_Blockage_RIS;
else
    H_RIS = 0;
end




%% Assign Channels

Channel.Direct = H_D;
Pow_dir = H_D^2;
SNR.DL = 10 .* log10(Pow_dir ./ db2pow(Pn_at_UE));


Channel.RIS = H_RIS;
[~,S_ris,~] = svd(H_RIS);
P_ris = trace(S_ris(1,1).^2);
SNR.RIS = 10 .* log10(P_ris ./ db2pow(Pn_at_UE));



end
