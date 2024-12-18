function [weights] = get_phaseshifts(doa,FoV,array,fc)
%calculate 2 beams from tx to rx and form rx to tx
if all(abs(doa) <= (FoV))
    sv = phased.SteeringVector('SensorArray',array,'NumPhaseShifterBits',5);
    ang = rad2deg(doa);
    weights = sv(fc,ang');
else
    weights = NaN(size(array.Size));
    warning("Direction mismatch between Tx and Rx");
end
end