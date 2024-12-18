function [ElementPattern_dB,DirrV_dB,DirrH_dB] = Dir_Patch(theta_h,theta_v,Device)

% max\min angles are given by H for relay
% if isequal(Entity,'BS') 
%     H_shield = deg2rad(60);
% elseif isequal(Entity,'AF') || isequal(Entity,'UE')
%     H_shield = deg2rad(80);
% else
%     error('Undefined Use of Patch Directivity');
% end
H_shield = Device.Horizontal_FOV/2;
if (theta_h > H_shield) || (theta_h < -H_shield)
    DirrH_dB = -inf;
    DirrV_dB = -inf;
    ElementPattern_dB  = -inf;
else
    % I take it normalized here, because Ge is already counted inside the
    %apperture gain by H
    NormalizedFlag = 1;
    
    if NormalizedFlag == 1
        Ge = 0; %% I remove the gain from here to add later on
    else
        Ge = 5;
    end
    SLAv = 30;
    Am = 30;
    phi3dB = deg2rad(100);
    theta3dB =  deg2rad(100);
    DirrV_dB = - min(12*(theta_v./theta3dB)^2,SLAv);
    
    DirrH_dB = - min(12.*(theta_h./phi3dB).^2,Am);
    
    ElementPattern_dB = Ge - min(-(DirrV_dB+DirrH_dB),Am);
end



end