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

RIS_Panel = computeElemPos(RIS,RIS.Orientation,'');
RIS_Elem_locations = RIS_Panel.ElemPos;

prob1 = false;
if prob1
    AA = squeeze(RIS_Elem_locations); %#ok<*UNRCH>
    size(AA)
    figure
    plot3(AA(:,1),AA(:,2),AA(:,3),'O')
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    hold on
end


elPos_rx = zeros(1,1 , Rx.Nh * Rx.Nv , 3);
elPos_tx = zeros(1, Tx.Nh * Tx.Nv , 1 , 3);


Tx_Orientation_toward_RIS = Get_Orientation(Tx,RIS,Angles);
Tx.Panel =  computeElemPos(Tx,Tx_Orientation_toward_RIS,'');
[~,Tx, DoesServe1] = BS_Panel_Selection(RIS,Tx,'');
% elPos_tx(1,:,1,:) = Tx.Panel.ElemPos.';
TxC_Pos = reshape(Params.Tx.Center,1,1,1,3);


Genaral_Rx_Orientation_for_RIS = Get_Orientation(Rx,RIS,Angles);
Rx.Panel =  computeElemPos(Rx,Genaral_Rx_Orientation_for_RIS,'');
[Rx,~, DoesServe2] = BS_Panel_Selection(Rx,RIS,'');
% elPos_rx(1,1,:,:) = Rx.Panel.ElemPos.';
RxC_Pos = reshape(Params.Rx.Center,1,1,1,3);


RIS_C = reshape(RIS.Center,1,1,1,3);


if (DoesServe1)&&(DoesServe2)
    
    if isequal(Tx.Device,'BS')
        elPos_tx(1,:,1,:) = Tx.Selected.ElemPos.';
    elseif isequal(Tx.Device,'UE')
        elPos_tx(1,:,1,:) = Tx.Panel.ElemPos.';
    end
    
    if isequal(Rx.Device,'BS')
        elPos_rx(1,1,:,:) = Rx.Selected.ElemPos.';
    elseif isequal(Rx.Device,'UE')
        elPos_rx(1,1,:,:) = Rx.Panel.ElemPos.';
    end
    
    RIS_Serves = true;
    
    prob2 = false;
    if prob2
        AA = squeeze(elPos_tx); %#ok<*UNRCH>
        size(AA)
        %         figure
        plot3(AA(:,1),AA(:,2),AA(:,3),'O','MarkerSize',20)
        xlabel('X')
        ylabel('Y')
        zlabel('Z')
        hold on
    end
    %%
    RISC2Tx = elPos_tx - RIS_C;
    RISC2TxC =  TxC_Pos - RIS_C;
    RIS.Dis.Tx2RISC = sqrt(sum(RISC2Tx .^2,4));
    RIS.Dis.TxC2RISC = sqrt(sum(RISC2TxC .^2,4));
    RIS.EL.RISC2TxC =  acos(RISC2TxC(:,:,:,3) ./ RIS.Dis.TxC2RISC);
    RIS.AZ.RISC2TxC = (atan2(RISC2TxC(:,:,:,2), RISC2TxC(:,:,:,1)));
    RISC2Rx = elPos_rx - RIS_C;
    RISC2RxC =  RxC_Pos - RIS_C;
    RIS.Dis.RX2RISC = sqrt(sum(RISC2Rx.^2,4));
    RIS.Dis.RxC2RISC = sqrt(sum(RISC2RxC.^2,4));
    RIS.EL.RISC2RxC =  acos(RISC2RxC(:,:,:,3) ./ RIS.Dis.RxC2RISC);
    RIS.AZ.RISC2RxC = (atan2(RISC2RxC(:,:,:,2), RISC2RxC(:,:,:,1)));
    if (~isequal(RIS.Type,'Flat')) || (~isequal(RIS.Config.Policy,'FF_Assympt'))
        RIS2Tx = elPos_tx - RIS_Elem_locations;
        RIS.Dis.Tx2RIS = sqrt(sum(RIS2Tx.^2,4));
        RIS.EL.RIS2Tx =   acos(RIS2Tx(:,:,:,3) ./ RIS.Dis.Tx2RIS);
        RIS.AZ.RIS2Tx = (atan2(RIS2Tx(:,:,:,2), RIS2Tx(:,:,:,1)));
        RIS2Rx= elPos_rx - RIS_Elem_locations;
        RIS.Dis.Rx2RIS = sqrt(sum(RIS2Rx.^2,4));
        RIS.EL.RIS2Rx =   acos(RIS2Rx(:,:,:,3) ./ RIS.Dis.Rx2RIS);
        RIS.AZ.RIS2Rx = (atan2(RIS2Rx(:,:,:,2), RIS2Rx(:,:,:,1)));
    end
    
else
    RIS_Serves = false;
    warning('RIS cannot serve due to vertical downsteer limitations')
end
end