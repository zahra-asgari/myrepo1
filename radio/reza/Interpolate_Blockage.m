function [Blockage] = Interpolate_Blockage(R,Data)


%disp(R)
%disp(Data)
Blockage.PB = interp1(Data.UE_radius_vect,smooth(Data.PB),R,'linear','extrap');
Blockage.PB = min(Blockage.PB,1);
Blockage.PB = max(Blockage.PB,0);
% SEED = Blockage.EstimatedGaussModel{1,ind};
% xAx = linspace(0,Blockage.xAx{1,ind}(end),500);

% disp(This_Blockage_Prob)
% disp('Hello')

Blockage.Loss = Assign_Blockage_Loss(R,Data);





end
