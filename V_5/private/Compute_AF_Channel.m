
function [MaxChannel, MaxNoise, MinChannel, MinNoise,Blockage] = ...
    Compute_AF_Channel(Params,Angles,Distances ,ScenarioFlag1,ScenarioFlag2, RelayOptionFlag,Panel2Rot,Panel2Tilt) %#ok<INUSD>

Tx = Params.Tx;
Rx = Params.Rx;
AF = Params.AF;

% % %
% % % lineseg2D_1 =  [Tx.Center(1) ,Tx.Center(2); AF.Center(1) ,AF.Center(2)];
% % % lineseg2D_2 =  [AF.Center(1) ,AF.Center(2); Rx.Center(1) ,Rx.Center(2)];
% % % Buildings = Params.Blockage.Buildings;
% % % N_BLD = length(Buildings);
% % % for POL = 1:N_BLD
% % %     This_BLD = Buildings{1,POL};
% % %     [LineSegInside_1,LineSegOutside_1] = intersect(This_BLD,lineseg2D_1);
% % %     [LineSegInside_2,LineSegOutside_2] = intersect(This_BLD,lineseg2D_2);
% % %     if (isempty(LineSegOutside_1)) || (~isempty(LineSegInside_1)) || (isempty(LineSegOutside_2)) || (~isempty(LineSegInside_2))
% % %         Blockage.Status = 'Static_Blocked';
% % %         Blockage.Event = 'true';
% % %         Blockage.PB = 1;
% % %         Blockage.Loss = inf;
% % %         MaxChannel = 0;
% % %         MaxNoise = 0;
% % %         MinChannel = 0;
% % %         MinNoise = 0;
% % %         return
% % %     end
% % % end

% AF_Horizontal_Limit = AF.Horizontal_FOV + AF.Horizontal_Alignment_Limit;
AF_Horizontal_Limit = deg2rad(170);
% AF_Horizontal_Limit = deg2rad(90);
h_BS = Tx.Center(3);
h_UE  = Rx.Center(3);
h_Rel = AF.Center(3);

Genaral_Tx_Orientation_for_AF = Get_Orientation(Tx,AF,Angles);
Tx.Panel =  computeElemPos(Tx,Genaral_Tx_Orientation_for_AF,'OnlyRotation');
[~,Tx, DoesServe1] = BS_Panel_Selection(AF,Tx,'OnlyRotation');

if isequal(Tx.Device,'BS')
    Tx_Orientation_selected =  Tx.Selected.Orientation;
elseif isequal(Tx.Device,'UE')
    Tx_Orientation_selected =  Tx.Panel.Orientation;
end


Genaral_Rx_Orientation_for_AF = Get_Orientation(Rx,AF,Angles);
Rx.Panel =  computeElemPos(Rx,Genaral_Rx_Orientation_for_AF,'OnlyRotation');
[Rx,~, DoesServe2] = BS_Panel_Selection(Rx,AF,'OnlyRotation');
if isequal(Rx.Device,'BS')
    Rx_Orientation_selected =  Rx.Selected.Orientation;
elseif isequal(Rx.Device,'UE')
    Rx_Orientation_selected  =  Rx.Panel.Orientation;
end

Pan1_Orient = Angles.Relay.Tx;
Theta_v_Relay2Tx_Pan1 = atan2((h_BS - h_Rel), Distances.Rx.Relay_2D);
Theta_v_Tx2Relay = - Theta_v_Relay2Tx_Pan1;
Tilt_Relay_Pan1 = Theta_v_Relay2Tx_Pan1;
Theta_v_Relay2Rx_Pan2 = atan2((h_UE - h_Rel),Distances.Tx.Relay_2D);
Theta_v_Rx2Relay = - Theta_v_Relay2Rx_Pan2;
switch AF.Orientation
    case  'Optimum'
        Tilt_Relay_Pan2 = Theta_v_Relay2Rx_Pan2;
        [~,indmax] = max([abs(wrapToPi(Pan1_Orient - Angles.Relay.Rx)), AF_Horizontal_Limit]); % if indmax =1 >> Panel 2 can be aligned toward Rx, if indmax = 2 >> panel 2 can be aligned toward pi/2 +- Panel 1
        Temp = abs(wrapToPi(Pan1_Orient - AF_Horizontal_Limit - Angles.Relay.Rx)) < abs(wrapToPi(Pan1_Orient + AF_Horizontal_Limit - Angles.Relay.Rx));
        Pan2_Orient = Angles.Relay.Rx * (indmax == 1) + wrapToPi(Pan1_Orient - AF_Horizontal_Limit) * (indmax == 2)* Temp + wrapToPi(Pan1_Orient + AF_Horizontal_Limit) * (indmax == 2)* (1-Temp)  ;
        DoesServe3 = 1;
    case 'Random'
        Tilt_Relay_Pan2 = AF.Pan2DownTiltRad * rand;
        Pan2_Orient = wrapToPi(Pan1_Orient + (pi/2 + 0.0001) + (pi - 0.00001) * rand);
        DoesServe3 = 1;
    otherwise
        Tilt_Relay_Pan2 = AF.Pan2DownTiltRad;
        Pan2_Orient = AF.Orientation;
        [~,indmax] = max([abs(wrapToPi(Pan1_Orient - Angles.Relay.Rx)), abs(wrapToPi(Pan1_Orient - (pi/2)))]);
        DoesServe3 = (indmax ~=2);
end


if (~DoesServe1)  || (~DoesServe2) || (~DoesServe3)
    MaxChannel = 0;
    MaxNoise = 0;
    MinChannel = 0;
    MinNoise = 0;
    Blockage = [];
else
    NoisePower_Rel = db2pow(-174 + 10 * log10(Params.comm.BW) + AF.NF);
    NoisePower_UE = db2pow(-174 + 10 * log10(Params.comm.BW) + AF.NF );
    
    E2E_gain_min_dB = AF.EIRP_min + 2* AF.AppGain;
    E2E_gain_max_dB = AF.EIRP_max + 2* AF.AppGain;
    
    % I use normalised element pattern, because Ge is already considered inside the apperture gains given by H
    Normalized_Dir_Tx = Dir_Patch(wrapToPi(Angles.Tx.Relay- Tx_Orientation_selected) , wrapToPi(Theta_v_Tx2Relay - Tx.DownTiltRad));
    Normalized_Dir_Rx = Dir_Patch(wrapToPi(Angles.Rx.Relay- Rx_Orientation_selected) , wrapToPi(Theta_v_Rx2Relay - Rx.DownTiltRad));
    %     Normalized_Dir_Rx = 0;
    
    Normalized_Dir_Pan1 = Dir_Patch(wrapToPi(Angles.Relay.Tx - Pan1_Orient) , wrapToPi(Theta_v_Relay2Tx_Pan1 - Tilt_Relay_Pan1));
    Normalized_Dir_Pan2 = Dir_Patch(wrapToPi(Angles.Relay.Rx - Pan2_Orient) , wrapToPi(Theta_v_Relay2Rx_Pan2 - Tilt_Relay_Pan2));
    
    PL1_dB = PL_calc([Tx.Center],[ AF.Center],ScenarioFlag1,Params.comm.fc);
    PL2_dB = PL_calc([Rx.Center],[ AF.Center],ScenarioFlag2,Params.comm.fc);
    %     FlucPower_dB = db2pow(prm.ShadowingSTD * randn(1,1));
    FlucPower_dB = 0;
    AngleDepGain_dB = Normalized_Dir_Pan1 + Normalized_Dir_Pan2;
    %     disp(AngleDepGain_dB)
    %     if AngleDepGain_dB < -26
    %         disp('Stop')
    %     end
    RelayGain_Min_dB_temp = E2E_gain_min_dB + AngleDepGain_dB;
    RelayGain_Max_dB_temp = E2E_gain_max_dB + AngleDepGain_dB;
    
    Relay_Pr_min = Params.Tx.EIRP + Normalized_Dir_Tx -PL1_dB;
    RelayGain_Min_dB = min(RelayGain_Min_dB_temp,-(Normalized_Dir_Tx -PL1_dB));
    RelayGain_Max_dB = min(RelayGain_Max_dB_temp,-(Normalized_Dir_Tx -PL1_dB));
    
    if RelayGain_Max_dB_temp > RelayGain_Max_dB
        disp('stop')
    end
    
    MinChannel =  sqrt(db2pow(Relay_Pr_min + RelayGain_Min_dB - PL2_dB + ...
        Normalized_Dir_Rx + FlucPower_dB + 10*log10(Rx.ArrSize * Rx.Efficiency)));
    
    MaxChannel =  sqrt(db2pow(Relay_Pr_min + RelayGain_Max_dB - PL2_dB ...
        + Normalized_Dir_Rx + FlucPower_dB + 10*log10(Rx.ArrSize * Rx.Efficiency)));
    
    MinNoise = NoisePower_UE + NoisePower_Rel * db2pow(-PL2_dB + RelayGain_Min_dB ...
        + 10*log10(Rx.ArrSize * Rx.Efficiency));
    
    MaxNoise = NoisePower_UE + NoisePower_Rel * db2pow(-PL2_dB + RelayGain_Max_dB ...
        + 10*log10(Rx.ArrSize * Rx.Efficiency));
    
    
    
    if Params.Config.Check_Dynamic_Blockage
        Blockage = Params.Blockage.Handle(Distances.Rx.Relay,Params.Blockage);
    elseif ~Params.Config.Check_Dynamic_Blockage
        Blockage.Loss = 0;
        Blockage.PB = 0;
    else
        error('Undefined Dynamic Blockage Status')
    end
    
end
% end
end