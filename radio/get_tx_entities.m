function [RE] = get_tx_entities(re_type,radio_prm)
%GET_RE.Tx_ENTITIES This function returns the RE.Tx parameters of a choosen RE.Tx
%entity (provided as a string) - Author: Eugenio Moro
%   Supported RE.Tx entities: Donors 'donor' - IAB Nodes 'iab'
RE.type = re_type;
RE.Tx.d = radio_prm.lambda/2;                     % inter-element spacing
switch re_type
    case 'donor'
        RE.Tx.NF = 8.5;                     % [dB] noise figure
        RE.Tx.EIRP = 58;
        RE.Tx.Ptx = 35;
        RE.Tx.Tilt = -7;
        RE.Tx.MaxDownSteerElevDegree = 15;
        RE.Tx.DownTiltDegree = -7;
        RE.Tx.Nh = 16;
        RE.Tx.Nv = 12;
    case 'iab'
        RE.Tx.NF = 9;                     % [dB] noise figure
        RE.Tx.EIRP = 51;
        RE.Tx.Ptx = 31;
        RE.Tx.MaxDownSteerElevDegree = 30;
        RE.Tx.DownTiltDegree = -7;
        RE.Tx.Nh = 12;
        RE.Tx.Nv = 8;
    otherwise
        error('TX entity not recognized');
end

RE.Tx.ArrSize = RE.Tx.Nh * RE.Tx.Nv;

end

