
function H = Compute_Direct_Channel(prm,Scenario)

prm.aod_dir_Tx = atan2(prm.Rx.Center(2)-prm.Tx.Center(2), prm.Rx.Center(1)-prm.Tx.Center(1)); % Angle of departure in radians
prm.aoa_dir_Rx = atan2(prm.Tx.Center(2)-prm.Rx.Center(2), prm.Tx.Center(1)-prm.Rx.Center(1)); % Angle of arrival in radians
h_BS = prm.Tx.Center(3);
h_UE  = prm.Rx.Center(3);
h_Rel = prm.RIS.Center(3);
Dist_2D_Tx2Rx = pdist2(prm.Tx.Center,  prm.Rx.Center);
%     h_Rel = Params.relay_pos(3);

TxRotation = prm.Tx.Orientation;
switch prm.Tx.Orientation
    case  {'Optimum' , 'Relay'}
        TxRotation = prm.aod_dir_Tx;
    case 'Random'
        TxRotation = 2 * pi * rand;
    case 'Tx'
        if ~isempty(prm.aod_dir_Tx )
            TxRotation = prm.aod_dir_Tx;
        else
            prm.aod_dir_Tx = atan2(prm.Rx.Center(2) - prm.Tx.Center(2), prm.Rx.Center(1) - prm.Tx.Center(1));
            TxRotation = prm.aod_dir_Tx;
        end
    %case isnumeric(prm.Tx.Orientation)
    %    TxRotation = prm.Tx.Orientation;
end

[Panels]= computeElemPos(prm.Tx,TxRotation,'OnlyRotation');
[prm.Tx,~, DoesServe] = Fetch(prm.Rx, prm.Tx, Panels, 'OnlyRotation');
% [~,TxPanelOrientation,~,~, DoesServe] = Fetch_BS(prm.relay_pos,[], TxRotTemp, prm, prm.aod_dir_Tx,'OnlyRotation');
% [~,TxPanelOrientation,~,~, DoesServe] = Fetch_BS(prm.relay_pos,[], TxRotTemp, prm, prm.aod_dir_Tx,'OnlyRotation');

if ~DoesServe
    H = 0;
else
    Theta_v_Tx2Rx = atan2((h_UE - h_BS),Dist_2D_Tx2Rx); %% in radians
    % Calculate the normalized element directivity pattern, considering the
    % orientation of the Tx, while, considering that the UE is fully oriented
    % toward the Tx
    Normalized_Dir_Tx = Dir_Patch(wrapToPi(prm.aod_dir_Tx - prm.Tx.Selected.Orientation) , wrapToPi(Theta_v_Tx2Rx -  prm.Tx.DownTiltRad));
    switch prm.Rx.Orientation
        case'Optimum'
            Normalized_Dir_Rx = 0;
        case  'Tx'
            Normalized_Dir_Rx = 0;
        case 'Relay'
            % This option is disabled such that we don't need to pass the
            % relay to the function (Eugenio Moro)
            Dist_2D_Pan2 = pdist2(prm.Rx.Pos,  prm.relay_pos);
            %         Theta_v_Tx2RelayPan1 =  atan2d((h_UE - h_Rel), Dist_2D_Pan1);
            Theta_v_Rx2RelayPan2 = - atan2((h_UE - h_Rel),Dist_2D_Pan2); %% in radians
            Theta_H_Tx2RelPan1 = atan2(prm.relay_pos(2) - prm.Tx.Pos(2), prm.relay_pos(1) - prm.Tx.Pos(1)); %% in radians
            Normalized_Dir_Rx = Dir_Patch(wrapToPi(prm.aoa_dir_Rx - Theta_H_Tx2RelPan1) , wrapToPi(-Theta_v_Tx2Rx -  Theta_v_Rx2RelayPan2));
        case 'Random'
            Theta_H_Tx2RelPan1 = atan2(prm.relay_pos(2) - prm.Tx.Pos(2), prm.relay_pos(1) - prm.Tx.Pos(1));
            Normalized_Dir_Rx = Dir_Patch(wrapToPi(wrapToPi(rand * 2*pi) - Theta_H_Tx2RelPan1) , wrapToPi(-Theta_v_Tx2Rx -  ((rand * pi/3) - pi/6)));
        otherwise
            Theta_H_Tx2RelPan1 = atan2(prm.Rx.Center(2) - prm.Tx.Center(2), prm.Rx.Center(1) - prm.Tx.Center(1));
            Normalized_Dir_Rx = Dir_Patch(wrapToPi(wrapToPi(prm.Rx.Orientation) - Theta_H_Tx2RelPan1) , wrapToPi(-Theta_v_Tx2Rx -  (prm.Rx.DownTiltRad)));
    end
    PL_dB = PL_calc(prm.Tx.Center,  prm.Rx.Center,  Scenario.Tx2Rx,  prm.fc);
    
    Amplitude = sqrt(db2pow(prm.Tx.EIRP + Normalized_Dir_Tx + ...
        Normalized_Dir_Rx + 10*log10(prm.Rx.ArrSize * prm.Rx.Efficiency) - PL_dB ));
    H = Amplitude; % for now we don't care about phase, delay etc., as we will only pick the maximum channel
end
end