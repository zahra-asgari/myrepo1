function [Dis,Vec,Params] = Define_Distances(Params)

RIS_Panel = computeElemPos(Params.RIS,Params.RIS.Orientation,'OnlyRotation');

Center = Params.RIS.Center;
Params.aod_Tx2RIS = atan2(Center(2)-Params.Tx.Center(2), Center(1)-Params.Tx.Center(1)); % Angle of departure
Params.aoa_RxFromRIS = atan2(Center(2) - Params.Rx.Center(2),  Center(1) - Params.Rx.Center(1)); % Angle of departure
Center = reshape(Center,1,1,1,3);
RIS_Elem_locations = RIS_Panel.ElemPos - Center;

elPos_rx_initial = zeros(1,1 , Params.Rx.Nh*Params.Rx.Nv , 3);
elPos_tx_initial = zeros(1,Params.Tx.Nh*Params.Tx.Nv , 1 , 3);

switch Params.Rx.Orientation
    case {'Optimum' , 'Relay'}
        RxOrientation_rad = Params.aoa_RxFromRIS;
    case 'Random'
        RxOrientation_rad = 2 * pi * rand;
    case 'Tx'
        if ~isempty(Params.aoa_dir_Rx )
            RxOrientation_rad = Params.aoa_dir_Rx;
        else
            Params.aoa_dir_Rx = atan2(Params.Tx.Center(2)-Params.Rx.Center(2), Params.Tx.Center(1)-Params.Rx.Center(1));
            RxOrientation_rad = Params.aoa_dir_Rx;
        end
    otherwise
        if isnumeric(Params.Rx.Orientation)
            RxOrientation_rad = Params.Rx.Orientation;
        else
            error('Undefined Orientation of Rx')
        end
end
Rx_Panel = computeElemPos(Params.Rx,RxOrientation_rad,'PositionAndRotation');
TxRotation = Params.Tx.Orientation;
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
[Tx_Panels]= computeElemPos(Params.Tx,TxRotation,'PositionAndRotation');
[Params.Tx,~, DoesServe] = Fetch(Params.RIS, Params.Tx, Tx_Panels, 'PositionAndRotation');
% [Params.Tx.ElemPos,Params.Tx.Rot] = computeElemPos('BS',Params,'Tx', TxRotation,'PositionAndRotation');
% [Params.Tx,~, DoesServe] = Fetch(Params.RIS, Params.Tx, 'PositionAndRotation');


% [Panels]= computeElemPos(prm.Tx,TxRotation,'OnlyRotation');



if DoesServe
    elPos_tx_initial(1,:,1,:) = Params.Tx.Selected.ElemPos.';
    elPos_rx_initial(1,1,:,:) = Rx_Panel.ElemPos.';
end

if isequal(Params.RIS.Orientation,'Optimum')
    aoa_Rel_rad = atan2(Params.Tx.Center(2)- Params.RIS.Center(2), Params.Tx.Center(1)- Params.RIS.Center(1));
    aod_Rel_rad = atan2(Params.Rx.Center(2)- Params.RIS.Center(2), Params.Rx.Center(1)- Params.RIS.Center(1));
    PHI_rad =  wrapToPi(-pi + ((aoa_Rel_rad) + (aod_Rel_rad))./2);
else
    PHI_rad = wrapToPi(Params.RIS.Orientation);
end


Rot1 = zeros(1,1 , 1 , 3);
Rot1(1,1,1,:) = [cos(PHI_rad),-sin(PHI_rad),0];
Rot2 = zeros(1,1 , 1 , 3);
Rot2 (1,1,1,:)= [sin(PHI_rad),cos(PHI_rad),0];

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
Vec.RIS2Tx = elPos_tx - RIS_Elem_locations;
Vec.RISCenter2Tx = elPos_tx - RIS_Center;
Vec.RISCenter2TxCenter =  TxCenter_Pos - RIS_Center;

Dis.Tx2RIS_3D = sqrt(sum(Vec.RIS2Tx.^2,4));
Dis.Tx2RIS_2D = sqrt(sum(Vec.RIS2Tx(:,:,:,[2,3]).^2,4));


Dis.Tx2RISCenter_3D = sqrt(sum(Vec.RISCenter2Tx .^2,4));
Dis.Tx2RISCenter_2D = sqrt(sum(Vec.RISCenter2Tx (:,:,:,[2,3]).^2,4));


Dis.TxCenter2RISCenter_3D = sqrt(sum(Vec.RISCenter2TxCenter .^2,4));
Dis.TxCenter2RISCenter_2D = sqrt(sum(Vec.RISCenter2TxCenter (:,:,:,[2,3]).^2,4));
%% RIS and RX

Vec.RIS2Rx= elPos_rx - RIS_Elem_locations;
Vec.RISCenter2Rx = elPos_rx - RIS_Center;
Vec.RISCenter2RxCenter =  RxCenter_Pos - RIS_Center;

Dis.RX2RIS_3D = sqrt(sum(Vec.RIS2Rx.^2,4));
Dis.Rx2RIS_2D = sqrt(sum(Vec.RIS2Rx(:,:,:,[2,3]).^2,4));

Dis.RX2RISCenter_3D = sqrt(sum(Vec.RISCenter2Rx.^2,4));
Dis.Rx2RISCenter_2D = sqrt(sum(Vec.RISCenter2Rx(:,:,:,[2,3]).^2,4));

Dis.RxCenter2RISCenter_3D = sqrt(sum(Vec.RISCenter2RxCenter.^2,4));
Dis.RxCenter2RISCenter_2D = sqrt(sum(Vec.RISCenter2RxCenter(:,:,:,[2,3]).^2,4));
end