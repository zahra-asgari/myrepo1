
function [MaxChannel, MaxNoise, MinChannel, MinNoise] = ...
    Compute_AF_Channel(Params, ScenarioFlag1,ScenarioFlag2, RelayOptionFlag,Panel2Rot,Panel2Tilt) %#ok<INUSD>

Azim_aod_Tx2Rel = atan2(Params.AF.Center(2) - Params.Tx.Center(2), Params.AF.Center(1) - Params.Tx.Center(1));
% aoa_Rel2Rx = atan2(Params.relay_pos(2)- Params.Tx.Pos(2), Params.relay_pos(1)-Params.Tx.Pos(1));

% [~,TxRotTemp]= computeElemPos('BS',Params,'Tx','OnlyRotation');
% [~,TxPanelOrientation,~,~, DoesServe1] = Fetch_BS(Params.Relay.Center,[], TxRotTemp, Params, Azim_aod_Tx2Rel,'OnlyRotation');

switch Params.Tx.Orientation
    case  {'Optimum' , 'Relay'}
        TxRotation = Params.aod_Tx2RIS;
    case 'Random'
        TxRotation = 2 * pi * rand;
    case 'Tx'
        if ~isempty(Params.aod_dir_Tx )
            TxRotation = Params.aod_dir_Tx;
        else
            Params.aod_dir_Tx = atan2(Params.Rx.Center(2) - Params.Tx.Center(2), Params.Rx.Center(1) - Params.Tx.Center(1));
            TxRotation = Params.aod_dir_Tx;
        end
    case isnumeric(Params.Rx.Orientation)
        TxRotation = Params.Tx.Orientation;
end
% % % [Params.Tx.ElemPos,Params.Tx.Rot] = computeElemPos(Params,'Tx', TxRotation,'PositionAndRotation');
% % % [Params.Tx,~, DoesServe1] = Fetch(Params.RIS, Params.Tx, 'PositionAndRotation');

[Tx_Panels]= computeElemPos(Params.Tx,TxRotation,'PositionAndRotation');
[Params.Tx,~, DoesServe1] = Fetch(Params.AF, Params.Tx, Tx_Panels, 'PositionAndRotation');



h_BS = Params.Tx.Center(3);
h_UE  = Params.Rx.Center(3);
h_Rel = Params.AF.Center(3);
NoServeDistance2 = abs((h_Rel - h_UE)) ./ tan(abs(Params.AF.MaxDownSteerElevRad) + abs(Params.AF.DownTiltRad));
Dist_2D_Pan1 = pdist2(Params.Tx.Center,  Params.AF.Center);
Dist_2D_Pan2 = pdist2(Params.Rx.Center,  Params.AF.Center);
DoesServe2 = NoServeDistance2 < Dist_2D_Pan2;
aoa_Rel = atan2(Params.Tx.Center(2)- Params.AF.Center(2), Params.Tx.Center(1)- Params.AF.Center(1));
aod_Rel = atan2(Params.Rx.Center(2)- Params.AF.Center(2), Params.Rx.Center(1)- Params.AF.Center(1));
Pan1_Orient = aoa_Rel;
% Pan2_Orient = Pan1_Orient + pi + Panel2Rot;
Theta_v_Relay_Pan12Tx = atan2((h_BS - h_Rel), Dist_2D_Pan1);
Tilt_Relay_Pan1 = Theta_v_Relay_Pan12Tx;
Theta_v_Tx2RelayPan1 = - Theta_v_Relay_Pan12Tx;
Theta_v_Relay_Pan2 = atan2((h_UE - h_Rel),Dist_2D_Pan2);
% Pan2_tilt = Panel2Tilt;
switch Params.AF.Orientation
    case  'Optimum'
        [~,indmax] = max([abs(wrapToPi(Pan1_Orient - aod_Rel)), abs(wrapToPi(Pan1_Orient - (pi/2)))]);
        Tilt_Relay_Pan2 = Theta_v_Relay_Pan2;
        Temp = abs(wrapToPi(Pan1_Orient - (pi/2) - aod_Rel)) < abs(wrapToPi(Pan1_Orient + (pi/2) - aod_Rel));
        Pan2_Orient = aod_Rel * (indmax == 1) + wrapToPi(Pan1_Orient - (pi/2)) * (indmax == 2)* Temp + wrapToPi(Pan1_Orient + (pi/2)) * (indmax == 2)* (1-Temp)  ;
        DoesServe3 = 1;
    case 'Random'
        Tilt_Relay_Pan2 = - deg2rad(6) * rand;
        Pan2_Orient = wrapToPi(Pan1_Orient + (pi/2 + 0.0001) + (pi - 0.00001) * rand);
        DoesServe3 = 1;
    otherwise
        Tilt_Relay_Pan2 = Params.AF.Pan2DownTiltRad;
        Pan2_Orient = Params.AF.Orientation;
        [~,indmax] = max([abs(wrapToPi(Pan1_Orient - aod_Rel)), abs(wrapToPi(Pan1_Orient - (pi/2)))]);
        DoesServe3 = (indmax ~=2);
end


if (~DoesServe1)  || (~DoesServe2) || (~DoesServe3)
    MaxChannel = 0;
    MaxNoise = 0;
else
    NoisePower_Rel = db2pow(-174 + 10 * log10(Params.comm.BW) + Params.AF.NF);
    NoisePower_UE = db2pow(-174 + 10 * log10(Params.comm.BW) + Params.Rx.NF );
    
    E2E_gain_min_dB = Params.AF.EIRP_min + 2* Params.AF.AppGain;
    E2E_gain_max_dB = Params.AF.EIRP_max + 2* Params.AF.AppGain;
    
    % I use normalised element pattern, because Ge is already considered inside the apperture gains given by H
    Normalized_Dir_Tx = Dir_Patch(wrapToPi(Azim_aod_Tx2Rel - Params.Tx.Selected.Orientation) , wrapToPi(Theta_v_Tx2RelayPan1 - Params.Tx.DownTiltRad));
    %     Normalized_Dir_Rx = ElemDir(wrapToPi(aoa_Rel2Rx - Pan1_Orient) , wrapToPi(Theta_v_Relay_Pan1 - Tilt_Relay_Pan1));
    Normalized_Dir_Rx = 0;
    
    Normalized_Dir_Pan1 = Dir_Patch(wrapToPi(aoa_Rel - Pan1_Orient) , wrapToPi(Theta_v_Relay_Pan12Tx - Tilt_Relay_Pan1));
    Normalized_Dir_Pan2 = Dir_Patch(wrapToPi(aod_Rel - Pan2_Orient) , wrapToPi(Theta_v_Relay_Pan2 - Tilt_Relay_Pan2));
    
    PL1_dB = PL_calc([Params.Tx.Center],[ Params.AF.Center],ScenarioFlag1,Params.comm.fc);
    PL2_dB = PL_calc([Params.Rx.Center],[ Params.AF.Center],ScenarioFlag2,Params.comm.fc);
    %     FlucPower_dB = db2pow(prm.ShadowingSTD * randn(1,1));
    FlucPower_dB = 0;
    AngleDepGain_dB = Normalized_Dir_Pan1 + Normalized_Dir_Pan2;
    %     disp(AngleDepGain_dB)
    if AngleDepGain_dB < -26
        disp('Stop')
    end
    RelayGain_Min_dB_temp = E2E_gain_min_dB + AngleDepGain_dB;
    RelayGain_Max_dB_temp = E2E_gain_max_dB + AngleDepGain_dB;
    
    Relay_Pr_min = Params.Tx.EIRP + Normalized_Dir_Tx -PL1_dB;
    RelayGain_Min_dB = min(RelayGain_Min_dB_temp,-(Normalized_Dir_Tx -PL1_dB));
    RelayGain_Max_dB = min(RelayGain_Max_dB_temp,-(Normalized_Dir_Tx -PL1_dB));
    
    %     if RelayGain_Min_dB_temp > RelayGain_Min_dB
    %                 disp('stop')
    %     end
    if RelayGain_Max_dB_temp > RelayGain_Max_dB
        disp('stop')
    end
    
    
    MinChannel =  sqrt(db2pow(Relay_Pr_min + RelayGain_Min_dB - PL2_dB + ...
        Normalized_Dir_Rx + FlucPower_dB + 10*log10(Params.Rx.ArrSize * Params.Rx.Efficiency)));
    
    MaxChannel =  sqrt(db2pow(Relay_Pr_min + RelayGain_Max_dB - PL2_dB ...
        + Normalized_Dir_Rx + FlucPower_dB + 10*log10(Params.Rx.ArrSize * Params.Rx.Efficiency)));
    
    MinNoise = NoisePower_UE + NoisePower_Rel * db2pow(-PL2_dB + RelayGain_Min_dB ...
        + 10*log10(Params.Rx.ArrSize * Params.Rx.Efficiency));
    
    MaxNoise = NoisePower_UE + NoisePower_Rel * db2pow(-PL2_dB + RelayGain_Max_dB ...
        + 10*log10(Params.Rx.ArrSize * Params.Rx.Efficiency));
    
end
end