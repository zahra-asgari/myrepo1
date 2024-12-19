function [Params, RIS_Serves]= Set_RIS(Params,Angles)

RIS = Params.RIS;
Tx = Params.Tx;
Rx = Params.Rx;

if ~isprop(RIS,'Plane')
    RIS.addprop('Plane');
    RIS.Plane = 'yz';
end


if ~isprop(RIS,'Dis')
    RIS.addprop('Dis');
end


if ~isprop(RIS,'AZ')
    RIS.addprop('AZ');
end


if ~isprop(RIS,'EL')
    RIS.addprop('EL');
end

RIS_Panel = computeElemPos(Params.RIS,Params.RIS.Orientation,'OnlyRotation');

Center = Params.RIS.Center;
% Params.aod_Tx2RIS = atan2(Center(2)-Params.Tx.Center(2), Center(1)-Params.Tx.Center(1)); % Angle of departure
% Params.aoa_RxFromRIS = atan2(Center(2) - Params.Rx.Center(2),  Center(1) - Params.Rx.Center(1)); % Angle of departure
Center = reshape(Center,1,1,1,3);
RIS_Elem_locations = RIS_Panel.ElemPos - Center;

elPos_rx_initial = zeros(1,1 , Params.Rx.Nh*Params.Rx.Nv , 3);
elPos_tx_initial = zeros(1,Params.Tx.Nh*Params.Tx.Nv , 1 , 3);


Genaral_Tx_Orientation_for_RIS = Get_Orientation(Tx,RIS,Angles);
Tx.Panel =  computeElemPos(Tx,Genaral_Tx_Orientation_for_RIS,'RotationAndPosition');
[~,Tx, DoesServe1] = BS_Panel_Selection(RIS,Tx,'RotationAndPosition');
% if isequal(Tx.Device,'BS')
%     elPos_tx_initial(1,:,1,:) = Tx.Selected.ElemPos.';
% elseif isequal(Tx.Device,'UE')
%     elPos_tx_initial(1,:,1,:) = Tx.Panel.ElemPos.';
% end



Genaral_Rx_Orientation_for_RIS = Get_Orientation(Rx,RIS,Angles);
Rx.Panel =  computeElemPos(Rx,Genaral_Rx_Orientation_for_RIS,'RotationAndPosition');
[Rx,~, DoesServe2] = BS_Panel_Selection(Rx,RIS,'RotationAndPosition');
% if isequal(Rx.Device,'BS')
%     elPos_rx_initial(1,1,:,:) = Rx.Selected.ElemPos.';
% elseif isequal(Rx.Device,'UE')
%     elPos_rx_initial(1,1,:,:) = Rx.Panel.ElemPos.';
% end

if (DoesServe1)&&(DoesServe2)

    if isequal(Tx.Device,'BS')
    elPos_tx_initial(1,:,1,:) = Tx.Selected.ElemPos.';
elseif isequal(Tx.Device,'UE')
    elPos_tx_initial(1,:,1,:) = Tx.Panel.ElemPos.';
    end

    if isequal(Rx.Device,'BS')
    elPos_rx_initial(1,1,:,:) = Rx.Selected.ElemPos.';
elseif isequal(Rx.Device,'UE')
    elPos_rx_initial(1,1,:,:) = Rx.Panel.ElemPos.';
end

    RIS_Serves = 'true';
    RIS_Orientation = wrapToPi(Params.RIS.Orientation);
    Rot1 = zeros(1,1 , 1 , 3);
    Rot1(1,1,1,:) = [cos(RIS_Orientation),-sin(RIS_Orientation),0];
    Rot2 = zeros(1,1 , 1 , 3);
    Rot2 (1,1,1,:)= [sin(RIS_Orientation),cos(RIS_Orientation),0];
    
    elPos_rx1 = elPos_rx_initial - Center;
    elPos_rx = elPos_rx1;
    elPos_rx(:,:,:,1) = sum(Rot1 .* elPos_rx1,4);
    elPos_rx(:,:,:,2) = sum(Rot2 .* elPos_rx1,4);
    
    elPos_tx1 = elPos_tx_initial - Center;
    elPos_tx = elPos_tx1;
    elPos_tx(:,:,:,1) = sum(Rot1 .* elPos_tx1,4);
    elPos_tx(:,:,:,2) = sum(Rot2 .* elPos_tx1,4);
    
    TxCenter_Pos1 = reshape(Params.Tx.Center,1,1,1,3) - Center;
    TxCenter_Pos = TxCenter_Pos1;
    TxCenter_Pos(:,:,:,1) = sum(Rot1 .* TxCenter_Pos1,4);
    TxCenter_Pos(:,:,:,2) = sum(Rot2 .* TxCenter_Pos1,4);
    
    RxCenter_Pos1 = reshape(Params.Rx.Center,1,1,1,3) - Center;
    RxCenter_Pos = RxCenter_Pos1;
    RxCenter_Pos(:,:,:,1) = sum(Rot1 .* RxCenter_Pos1,4);
    RxCenter_Pos(:,:,:,2) = sum(Rot2 .* RxCenter_Pos1,4);
    
    RIS_Center = zeros(size(Center));
    
    %% RIS and TX
    % RIS2Tx = elPos_tx - RIS_Elem_locations;
    RISCenter2Tx = elPos_tx - RIS_Center;
    RISCenter2TxCenter =  TxCenter_Pos - RIS_Center;
    
    % RIS.Dis.Tx2RIS_3D = sqrt(sum(RIS2Tx.^2,4));
    % RIS.Dis.Tx2RIS_2D = sqrt(sum(RIS2Tx(:,:,:,[2,3]).^2,4));
    
    RIS.Dis.Tx2RISCenter_3D = sqrt(sum(RISCenter2Tx .^2,4));
    RIS.Dis.Tx2RISCenter_2D = sqrt(sum(RISCenter2Tx (:,:,:,[2,3]).^2,4));
    
    RIS.Dis.TxCenter2RISCenter_3D = sqrt(sum(RISCenter2TxCenter .^2,4));
    RIS.Dis.TxCenter2RISCenter_2D = sqrt(sum(RISCenter2TxCenter (:,:,:,[2,3]).^2,4));
    %% RIS and RX
    
    % RIS2Rx= elPos_rx - RIS_Elem_locations;
    RISCenter2Rx = elPos_rx - RIS_Center;
    RISCenter2RxCenter =  RxCenter_Pos - RIS_Center;
    
    % RIS.Dis.Rx2RIS_3D = sqrt(sum(RIS2Rx.^2,4));
    % RIS.Dis.Rx2RIS_2D = sqrt(sum(RIS2Rx(:,:,:,[2,3]).^2,4));
    
    RIS.Dis.RX2RISCenter_3D = sqrt(sum(RISCenter2Rx.^2,4));
    RIS.Dis.Rx2RISCenter_2D = sqrt(sum(RISCenter2Rx(:,:,:,[2,3]).^2,4));
    
    RIS.Dis.RxCenter2RISCenter_3D = sqrt(sum(RISCenter2RxCenter.^2,4));
    RIS.Dis.RxCenter2RISCenter_2D = sqrt(sum(RISCenter2RxCenter(:,:,:,[2,3]).^2,4));
    
    %% RIS and TX
    % RIS.EL.RIS2Tx =  abs(atan2(RIS.Dis.Tx2RIS_2D, RIS2Tx(:,:,:,1)));
    % RIS.AZ.RIS2Tx =  (atan2(RIS2Tx(:,:,:,3) , RIS2Tx(:,:,:,2)));
    RIS.EL.RISCenter2Tx =  abs(atan2(RIS.Dis.Tx2RISCenter_2D, RISCenter2Tx(:,:,:,1))) ;
    RIS.AZ.RISCenter2Tx =  (atan2(RISCenter2Tx(:,:,:,3), RISCenter2Tx(:,:,:,2)));
    RIS.EL.RISCenter2TxCenter =  abs(atan2(RIS.Dis.TxCenter2RISCenter_2D, RISCenter2TxCenter(:,:,:,1))) ;
    RIS.AZ.RISCenter2TxCenter =  (atan2(RISCenter2TxCenter(:,:,:,3), RISCenter2TxCenter(:,:,:,2)));
    
    %% RIS and RX
    
    % RIS.EL.RIS2Rx =  abs(atan2(RIS.Dis.Rx2RIS_2D, RIS2Rx(:,:,:,1)));
    % RIS.AZ.RIS2Rx = (atan2(RIS2Rx(:,:,:,3), RIS2Rx(:,:,:,2)));
    RIS.EL.RISCenter2Rx =  abs(atan2(RIS.Dis.Rx2RISCenter_2D, RISCenter2Rx(:,:,:,1)) ) ;
    RIS.AZ.RISCenter2Rx = (atan2(RISCenter2Rx(:,:,:,3), RISCenter2Rx(:,:,:,2)));
    RIS.EL.RISCenter2RxCenter =  abs(atan2(RIS.Dis.RxCenter2RISCenter_2D, RISCenter2RxCenter(:,:,:,1)) ) ;
    RIS.AZ.RISCenter2RxCenter = (atan2(RISCenter2RxCenter(:,:,:,3), RISCenter2RxCenter(:,:,:,2)));
    Params.RIS = RIS;
    
    
    if ~isequal(RIS.Config.Policy ,'FF_Assympt')
        RIS2Tx = elPos_tx - RIS_Elem_locations;
        RIS.Dis.Tx2RIS_3D = sqrt(sum(RIS2Tx.^2,4));
        RIS.Dis.Tx2RIS_2D = sqrt(sum(RIS2Tx(:,:,:,[2,3]).^2,4));
        RIS2Rx= elPos_rx - RIS_Elem_locations;
        RIS.Dis.Rx2RIS_3D = sqrt(sum(RIS2Rx.^2,4));
        RIS.Dis.Rx2RIS_2D = sqrt(sum(RIS2Rx(:,:,:,[2,3]).^2,4));
        RIS.EL.RIS2Tx =  abs(atan2(RIS.Dis.Tx2RIS_2D, RIS2Tx(:,:,:,1)));
        RIS.AZ.RIS2Tx =  (atan2(RIS2Tx(:,:,:,3) , RIS2Tx(:,:,:,2)));
        RIS.EL.RIS2Tx =  abs(atan2(RIS.Dis.Tx2RIS_2D, RIS2Tx(:,:,:,1)));
        RIS.AZ.RIS2Tx =  (atan2(RIS2Tx(:,:,:,3) , RIS2Tx(:,:,:,2)));
        RIS.EL.RIS2Rx =  abs(atan2(RIS.Dis.Rx2RIS_2D, RIS2Rx(:,:,:,1)));
        RIS.AZ.RIS2Rx = (atan2(RIS2Rx(:,:,:,3), RIS2Rx(:,:,:,2)));
    end
    
    
else
    RIS_Serves = false;
    warning('RIS cannot serve due to vertical downsteer limitations')
end
end