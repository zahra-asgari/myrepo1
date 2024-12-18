function [Channel,Params,pat] = Compute_Direct_Channel_Bamforming(Params,Angles,Distances,Scenario)
PLOT = 1;
Tx = Params.Tx;
Rx = Params.Rx;
h_Tx = Tx.Center(3);
h_Rx  = Rx.Center(3);

fc = Params.comm.fc;
bandwidth = Params.comm.BW;
lambda = Params.comm.lambda;
element = phased.GaussianAntennaElement('FrequencyRange',[fc - bandwidth/2, fc+bandwidth/2],'Beamwidth',[100,100]);
array = phased.URA('Size',[2 2],...
    'ElementSpacing',[lambda/2 lambda/2],'Element',element);


General_Tx_Orientation_for_Rx = Get_Orientation(Tx,Rx,Angles);
Tx.Panel =  computeElemPos(Tx,General_Tx_Orientation_for_Rx,'OnlyRotation');

General_Rx_Orientation_for_Tx = Get_Orientation(Rx,Tx,Angles);
Rx.Panel =  computeElemPos(Rx,General_Rx_Orientation_for_Tx,'OnlyRotation');

% if (isequal(Tx.Device,'BS')||isequal(Rx.Device,'BS'))
[Rx,Tx, DoesServe] = BS_Panel_Selection(Rx,Tx,'OnlyRotation');
% end
if DoesServe

    if isequal(Tx.Device,'BS')
        Tx_Orientation_selected = Tx.Selected.Orientation;
    elseif isequal(Tx.Device,'UE')
        Tx_Orientation_selected = Tx.Panel.Orientation;
    end
    Theta_v_Tx2Rx = atan2((h_Rx - h_Tx),Distances.Tx.Rx_2D); %% in radians
    tx_azimuth = wrapToPi(Angles.Tx.Rx - Tx_Orientation_selected);
    tx_elevation = wrapToPi(Theta_v_Tx2Rx -  Tx.DownTiltRad);
    %round the direction no the nearest integer degree
    tx_azimuth = deg2rad(round(rad2deg(tx_azimuth)));
    tx_elevation = deg2rad(round(rad2deg(tx_elevation)));
    array.Size = [Tx.Nv Tx.Nh];
    [tx_weights] = get_phaseshifts([tx_azimuth tx_elevation],[Tx.Horizontal_FOV/2 abs(Tx.MaxDownSteerElevRad)],array,fc);
    [pat_tx,az,el]=pattern(array,fc,-180:180,-90:90,'CoordinateSystem','polar', ...
            'PropagationSpeed',physconst('lightspeed'),'Type','powerdb','Weights',tx_weights);
    if PLOT
        beam_properties = {'BackFaceLighting', 'DiffuseStrength', 'FaceLighting','LineStyle', 'SpecularStrength',  'FaceColor','EdgeColor','FaceAlpha' };
        beam_values = {'unlit', 0.8, 'gouraud','none',  0,  'interp','none',0.3 };
        
        el = el';
        az = deg2rad(repmat(az,[181,1]));
        el = deg2rad(repmat(el,[1,361]));
        pat_plot = [pat_tx(mod(1 - round(rad2deg(Tx.DownTiltRad)),180):end,:);...
            repmat(pat_tx(end,:),[7,1])];
        pat_plot = [pat_plot(:,mod(1 - round(rad2deg(Tx.Selected.Orientation)),360):end-1),...
            pat_plot(:,1:mod(1 - round(rad2deg(Tx.Selected.Orientation)),360))];
        pat_plot = Distances.Tx.Rx/2*db2pow(pat_plot);
        [x_tx,y_tx,z_tx]= sph2cart(az,el,pat_plot);
        x_tx = x_tx + Tx.Center(1);
        y_tx = y_tx + Tx.Center(2);
        z_tx = z_tx + Tx.Center(3);
        sh = surface(x_tx,y_tx,z_tx,db2pow(pat_plot));
        set(sh,beam_properties,beam_values);
    end
    Normalized_Dir_Tx = pat_tx(rad2deg(tx_elevation)+91,rad2deg(tx_azimuth)+181);

    % Normalized_Dir_Tx = Dir_Patch(tx_azimuth,tx_elevation,Tx);

    if isequal(Rx.Device,'BS')
        Rx_Orientation_selected = Rx.Selected.Orientation;
    elseif isequal(Rx.Device,'UE')
        Rx_Orientation_selected = Rx.Panel.Orientation;
    end

    Theta_v_Rx2Tx = -Theta_v_Tx2Rx;
    rx_azimuth = wrapToPi(Angles.Rx.Tx - Rx_Orientation_selected);
    rx_elevation = wrapToPi(Theta_v_Rx2Tx -  Rx.DownTiltRad);
    rx_azimuth = deg2rad(round(rad2deg(rx_azimuth)));
    rx_elevation = deg2rad(round(rad2deg(rx_elevation)));
    array.Size = [Rx.Nv Rx.Nh];
    [rx_weights] = get_phaseshifts([rx_azimuth rx_elevation],[Rx.Horizontal_FOV/2 abs(Rx.MaxDownSteerElevRad)],array,fc);
    [pat_rx,az,el]=pattern(array,fc,-180:180,-90:90,'CoordinateSystem','polar', ...
        'PropagationSpeed',physconst('lightspeed'),'Type','powerdb','Weights',rx_weights);  
    if PLOT
        beam_properties = {'BackFaceLighting', 'DiffuseStrength', 'FaceLighting','LineStyle', 'SpecularStrength',  'FaceColor','EdgeColor','FaceAlpha' };
        beam_values = {'unlit', 0.8, 'gouraud','none',  0,  'interp','none',0.3 };        
        el = el';
        az = deg2rad(repmat(az,[181,1]));
        el = deg2rad(repmat(el,[1,361]));
        pat_plot = [pat_rx(mod(1 - round(rad2deg(Rx.DownTiltRad)),180):end,:);...
            repmat(pat_rx(end,:),[7,1])];
        pat_plot = [pat_plot(:,mod(1 - round(rad2deg(Rx.Selected.Orientation)),360):end-1),...
            pat_plot(:,1:mod(1 - round(rad2deg(Rx.Selected.Orientation)),360))];
        pat_plot = Distances.Tx.Rx/2*db2pow(pat_plot);
        [x_rx,y_rx,z_rx]= sph2cart(az,el,pat_plot);
        x_rx = x_rx + Rx.Center(1);
        y_rx = y_rx + Rx.Center(2);
        z_rx = z_rx + Rx.Center(3);
        sh = surface(x_rx,y_rx,z_rx,db2pow(pat_plot));
        set(sh,beam_properties,beam_values);
    end
    Normalized_Dir_Rx = pat_rx(rad2deg(rx_elevation)+91,rad2deg(rx_azimuth)+181);

    % Normalized_Dir_Rx = Dir_Patch(rx_azimuth,rx_elevation,Rx);
    PL_dB.DL = PL_calc(Tx.Center,  Rx.Center,  Scenario.Tx2Rx,  fc);
    PL_dB.UL = PL_calc(Rx.Center,  Tx.Center,  Scenario.Tx2Rx,  fc);

    Amplitude.DL = sqrt(db2pow(Tx.EIRP + Normalized_Dir_Tx + ...
        Normalized_Dir_Rx + 10*log10(Rx.ArrSize * Rx.Efficiency) - PL_dB.DL ));
    Amplitude.UL = sqrt(db2pow(Rx.EIRP + Normalized_Dir_Tx + ...
        Normalized_Dir_Rx + 10*log10(Tx.ArrSize * Tx.Efficiency) - PL_dB.UL ));


    Channel = Amplitude;

    if Params.Config.Check_Dynamic_Blockage
        Blockage = Params.Blockage.Handle(Distances.Tx.Rx,Params.Blockage);
    elseif ~Params.Config.Check_Dynamic_Blockage
        Blockage.Loss = 0;
        Blockage.PB = 0;
    else
        error('Undefined Dynamic Blockage Status')
    end

elseif ~DoesServe
    Channel.DL = 0;
    Channel.UL = 0;
    Blockage.Loss = inf;
    Blockage.PB = 1;
    warning('At this distance, direct serving is not possible given the down-steering limitations')
end
% end
Params.Tx = Tx;
Params.Rx = Rx;
pat(:,:,1) = pat_tx;
pat(:,:,2) = pat_rx;
end