function [Channel,Params] = Compute_Interference_Directivity(Params,Angles,Distances,Scenario,tx_beam,rx_beam)
Tx = Params.Tx;
Rx = Params.Rx;
h_Tx = Tx.Center(3);
h_Rx  = Rx.Center(3);
fc = Params.comm.fc;

    if isequal(Tx.Device,'BS')
        Tx_Orientation_selected = Tx.Selected.Orientation;
    elseif isequal(Tx.Device,'UE')
        Tx_Orientation_selected = Tx.Panel.Orientation;
    end
    Theta_v_Tx2Rx = atan2((h_Rx - h_Tx),Distances.Tx.Rx_2D); %% in radians
    tx_azimuth = wrapToPi(Angles.Tx.Rx - Tx_Orientation_selected);
    tx_elevation = wrapToPi(Theta_v_Tx2Rx -  Tx.DownTiltRad);
    tx_azimuth = round(rad2deg(tx_azimuth)) + 181;
    tx_elevation = round(rad2deg(tx_elevation)) + 91;
    %round the direction no the nearest integer degree
    Normalized_Dir_Tx = tx_beam(tx_elevation,tx_azimuth);
    if Normalized_Dir_Tx > -1e-3
        
        disp("High Tx Directivity")
        disp("")
    end    
    if isequal(Rx.Device,'BS')
        Rx_Orientation_selected = Rx.Selected.Orientation;
    elseif isequal(Rx.Device,'UE')
        Rx_Orientation_selected = Rx.Panel.Orientation;
    end

    Theta_v_Rx2Tx = -Theta_v_Tx2Rx;
    rx_azimuth = wrapToPi(Angles.Rx.Tx - Rx_Orientation_selected);
    rx_elevation = wrapToPi(Theta_v_Rx2Tx -  Rx.DownTiltRad);
    rx_azimuth = round(rad2deg(rx_azimuth)) + 181;
    rx_elevation = round(rad2deg(rx_elevation)) + 91;
    %round the direction no the nearest integer degree
    Normalized_Dir_Rx = rx_beam(rx_elevation,rx_azimuth);
    if Normalized_Dir_Rx > -1e-3
        
        disp("High Rx Directivity")
        disp("")
    end
    PL_dB = PL_calc(Tx.Center,  Rx.Center,  Scenario.Tx2Rx,  fc);

    Amplitude = sqrt(db2pow(Tx.EIRP + Normalized_Dir_Tx + ...
        Normalized_Dir_Rx + 10*log10(Rx.ArrSize * Rx.Efficiency) - PL_dB ));


    Channel = Amplitude;

    if Params.Config.Check_Dynamic_Blockage
        Blockage = Params.Blockage.Handle(Distances.Tx.Rx,Params.Blockage);
    elseif ~Params.Config.Check_Dynamic_Blockage
        Blockage.Loss = 0;
        Blockage.PB = 0;
    else
        error('Undefined Dynamic Blockage Status')
    end
end