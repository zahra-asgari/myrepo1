function [ElementPattern_dB,DirrV_dB,DirrH_dB] = Dir_Patch(theta_h,theta_v)

% max\min angles are given by H for relay
% if theta_h > 60 || theta_h < -60 || theta_v>30 || theta_v<-30
%     DirrH_dB = -inf;
%     DirrV_dB = -inf;
%     ElementPattern_dB  = -inf;
% else
    % I take it normalized here, because Ge is already counted inside the 
    %apperture gain by H
    NormalizedFlag = 1;
    
    if NormalizedFlag == 1
        Ge = 0; %% I remove the gain from here to add later on
    else
        Ge = 5;
    end
    % GeLin = 10^(Ge/10);
    SLAv = 30;
    Am = 30;
    phi3dB = pi/2;
    % theta3dB = 78.15;
    theta3dB = pi/2;
    DirrV_dB = - min(12*(theta_v./theta3dB)^2,SLAv);

    DirrH_dB = - min(12.*(theta_h./phi3dB).^2,Am);

    ElementPattern_dB = Ge - min(-(DirrV_dB+DirrH_dB),Am);
%     disp(ElementPattern_dB)
% end



end