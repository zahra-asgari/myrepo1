function [RE] = get_rx_entities(re_type,radio_prm)
%GET_RE.Tx_ENTITIES This function returns the parameters of a choosen
%receiver entity (provided as a string) - Author: Eugenio Moro
%   Supported entities: Omnidirectional UE 'omni_ue'
RE.type = re_type;
switch re_type
    case 'omni_ue'
        RE.Rx.Nh = 1;
        RE.Rx.Nv = 1;
        RE.Rx.NF = 10;
        RE.Rx.ArrSize = RE.Rx.Nh * RE.Rx.Nv;
        RE.Rx.d = radio_prm.lambda/2;    % inter-element spacing
        RE.Rx.Orientation = 'Optimum';
        RE.Rx.
    otherwise
        error('RX entity not recognized');
end

% aperture gain = array_gain + max_directivity + 10log10 effciency  

end

