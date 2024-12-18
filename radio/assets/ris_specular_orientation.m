function [ris_or] = ris_specular_orientation(tx_pos,rx_pos,ris_pos)
%RIS_SPECULAR_ORIENTATION This function returns the ris orientation such
%that the rs is the specular position (see documentation).This function
%can accept vectors. Positions are defined on the 2D plane

% reference the plane to the ris position
relative_rx_pos = rx_pos - ris_pos;
relative_tx_pos = tx_pos - ris_pos;

normal_surface = relative_rx_pos + relative_tx_pos;
ris_or = atan2d(normal_surface(2),normal_surface(1));
if ris_or < 0
    ris_or = 360 + ris_or;
end
%BUGFIX: ORIENTATION MUST BE OUTPUTTED IN RADIANS, NOT DEGREES!!
ris_or = deg2rad(ris_or);
ris_or = wrapToPi(ris_or);
end

