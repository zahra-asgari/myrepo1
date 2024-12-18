function [pl] = pathloss(d,varargin)
%PATHLOSS Compute average pathloss in dB given distance in meters and LOS/NLOS conditions
%
% [pl] = PATHLOSS(d,isLOS) This function returns the LOS or NLOS pathloss
% in db for 28GHz transmissions according to akdeniz2014
%
% $Author: Eugenio Moro $	$Date: 2020/11/27 13:17:52 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020
minArgs=3;
maxArgs=3;
narginchk(minArgs,maxArgs);



if strcmp(varargin{2}, 'los') || strcmp(varargin{1}, 'los')
    isLOS = 1;
else
    isLOS = 0;
end

if strcmp(varargin{2}, 'linear') || strcmp(varargin{1}, 'linear')
    isLinear = 1;
else
    isLinear = 0;
end



%LoS pathloss constants taken from akdeniz2014
a_los = 61.4;
b_los = 2;
%NLoS pathloss constants taken from akdeniz2014
a_nlos = 72;
b_nlos = 2.92;

if isLOS
    if isLinear
        pl = 10.^(-0.1*(a_los+10*b_los*log10(d)));
    else
        pl = a_los+10*b_los*log10(d);
    end
else
    if isLinear
        pl = 10.^(-0.1*(a_nlos+10*b_nlos*log10(d)));
    else
        pl = a_nlos+10*b_nlos*log10(d);
    end
end


end
