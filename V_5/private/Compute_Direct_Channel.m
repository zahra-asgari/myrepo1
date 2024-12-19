function [Channel,Blockage] = Compute_Direct_Channel(Params,Angles,Distances,Scenario)

Tx = Params.Tx;
Rx = Params.Rx;
h_Tx = Tx.Center(3);
h_Rx  = Rx.Center(3);

% % % 
% % % lineseg2D_1 =  [Tx.Center(1) ,Tx.Center(2); Rx.Center(1) ,Rx.Center(2)];
% % % Buildings = Params.Blockage.Buildings;
% % % N_BLD = length(Buildings);
% % % for POL = 1:N_BLD
% % %     This_BLD = Buildings{1,POL};
% % %     plot(This_BLD)
% % %     hold on
% % %     [LineSegInside_1,LineSegOutside_1] = intersect(This_BLD,lineseg2D_1);
% % %     if (isempty(LineSegOutside_1)) || (~isempty(LineSegInside_1))
% % %         Blockage.Status = 'Static_Blocked';
% % %         Blockage.Event = 'true';
% % %         Blockage.PB = 1;
% % %         Blockage.Loss = inf;
% % %         H = 0;
% % %         return
% % %     end
% % % end


Genaral_Tx_Orientation_for_Rx = Get_Orientation(Tx,Rx,Angles);
Tx.Panel =  computeElemPos(Tx,Genaral_Tx_Orientation_for_Rx,'OnlyRotation');

Genaral_Rx_Orientation_for_Tx = Get_Orientation(Rx,Tx,Angles);
Rx.Panel =  computeElemPos(Rx,Genaral_Rx_Orientation_for_Tx,'OnlyRotation');

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
    Normalized_Dir_Tx = Dir_Patch(wrapToPi(Angles.Tx.Rx - Tx_Orientation_selected) , wrapToPi(Theta_v_Tx2Rx -  Tx.DownTiltRad));
    
    if isequal(Rx.Device,'BS')
        Rx_Orientation_selected = Rx.Selected.Orientation;
    elseif isequal(Rx.Device,'UE')
        Rx_Orientation_selected = Rx.Panel.Orientation;
    end
    
    Theta_v_Rx2Tx = -Theta_v_Tx2Rx;
    Normalized_Dir_Rx = Dir_Patch(wrapToPi(Angles.Rx.Tx - Rx_Orientation_selected) , wrapToPi(Theta_v_Rx2Tx -  Rx.DownTiltRad));
    PL_dB = PL_calc(Tx.Center,  Rx.Center,  Scenario.Tx2Rx,  Params.comm.fc);
    
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
    
elseif ~DoesServe
    Channel = 0;
    Blockage.Loss = inf;
    Blockage.PB = 1;
    warning('At this distance, direct serving is not possible given the down-steering limitations')
end
% end
end