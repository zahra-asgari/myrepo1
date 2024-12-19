function [Params] = Set_CommParams(Fc,BW,ShadowingFlag)
% propagation parameters
Params.BW = BW;
Params.fc = Fc;                   % [Hz] carrier frequency
Params.a =1;                        % reflection amplitude at irs
c = physconst('lightspeed');     % lightspeed
Params.lambda = c / Params.fc;         % [m] wavelength
if isequal(ShadowingFlag,'Shadowing')
    Params.ShadowingSTD = 4;
elseif isequal(ShadowingFlag,'NoShadowing')
    Params.ShadowingSTD = 0;
else
    error('Define shadowing status')
end
end

