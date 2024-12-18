function [RE] = radio_entity_par(re_type,radio_prm)
%RADIO_ENTITY_PAR This function stores the parmeters of all known radio
%entities - used when constructing a radio entity class

switch re_type
    case 'ue_omni'
        RE.Rx.Nh = 1;
        RE.Rx.Nv = 1;
        RE.Rx.NF = 10;
        RE.Rx.ArrSize = RE.Rx.Nh * RE.Rx.Nv;
        RE.Rx.d = radio_prm.lambda/2;    % inter-element spacing
        RE.Rx.Orientation = 'Optimum';
        RE.Rx.AperGain = 0;
        
        RE.Tx.NF =9;
        RE.Tx.EIRP = 20;
        RE.Tx.Ptx = 20;
        RE.Tx.Tilt = 0;
        RE.Tx.MaxDownSteerElevDegree = 15;
        RE.Tx.DownTiltDegree = 0;
        RE.Tx.Nh = 1;
        RE.Tx.Nv = 1;
        
    case 'donor'
        RE.Tx.NF = 8.5;                     % [dB] noise figure
        RE.Tx.EIRP = 58;
        RE.Tx.Ptx = 35;
        RE.Tx.Tilt = -7;
        RE.Tx.MaxDownSteerElevDegree = 30;
        RE.Tx.d = radio_prm.lambda/2;    % inter-element spacing
        RE.Tx.DownTiltDegree = -7;
        RE.Tx.Nh = 16;
        RE.Tx.Nv = 12;
        
        RE.Rx.Nh = 16;
        RE.Rx.Nv = 12;
        RE.Rx.NF = 8.5;
        RE.Rx.ArrSize = RE.Rx.Nh * RE.Rx.Nv;
        RE.Rx.d = radio_prm.lambda/2;    % inter-element spacing
        RE.Rx.Orientation = 'Optimum';
        RE.Rx.AperGain = 30;
        
        
    case 'iab'
        RE.Tx.NF = 9;                     % [dB] noise figure
        RE.Tx.EIRP = 51;
        RE.Tx.Ptx = 31;
        RE.Tx.MaxDownSteerElevDegree = 30;
        RE.Tx.DownTiltDegree = -7;
        RE.Tx.Nh = 12;
        RE.Tx.Nv = 8;
        RE.Tx.d = radio_prm.lambda/2;    % inter-element spacing
        
        RE.Rx.Nh = 12;
        RE.Rx.Nv = 8;
        RE.Rx.NF = 9;
        RE.Rx.ArrSize = RE.Rx.Nh * RE.Rx.Nv;
        RE.Rx.d = radio_prm.lambda/2;    % inter-element spacing
        RE.Rx.Orientation = 'Optimum';
        RE.Rx.AperGain = 24;
        
    case 'ris'
        RE.RIS.M = 50;
        RE.RIS.N = 50;
        RE.RIS.Nris = RE.RIS.M * RE.RIS.N ;
        RE.RIS.dx =  radio_prm.lambda/2;
        RE.RIS.dy = radio_prm.lambda/2;
        RE.RIS.d = radio_prm.lambda/2; 
        RE.RIS.Size = [sqrt(RE.RIS.Nris), sqrt(RE.RIS.Nris)] .* (radio_prm.lambda/2);
        RE.RIS.Orientation  = 'Optimum';
        %RE.RIS.Orientation = -180;
        %RE.RIS.reconf_policy = 'Focus';
        RE.RIS.reconf_policy = 'FF_Anamolous';
        %         RE.RIS.reconf_policy = 'FF_Assympt';
        %         RE.RIS.reconf_policy = 'SmSk';
        
    case 'af_type_1'
        RE.AF.NF = 8;
        RE.AF.Type = 'Option1';
        RE.AF.MaxDownSteerElevDegree = 30;
        RE.AF.Pan2DownTiltDegree = -5;
        % RE.AF.Pan2DownTiltDegree = 'Optimum';
        RE.AF.Orientation = 'Optimum';
        % RE.AF.Orientation = 'Random';
        % RE.AF.Orientation = 120;
        RE.AF.EIRP_min = 40;
        RE.AF.EIRP_max = 55;
        RE.AF.AppGain = 20;
        
    case 'af_type_2'
        RE.AF.NF = 8;
        RE.AF.Type = 'Option2';
        RE.AF.MaxDownSteerElevDegree = 30;
        RE.AF.Pan2DownTiltDegree = -5;
        % RE.AF.Pan2DownTiltDegree = 'Optimum';
        RE.AF.Orientation = 'Optimum';
        % RE.AF.Orientation = 'Random';
        % RE.AF.Orientation = 120;
        RE.AF.EIRP_min = 40;
        RE.AF.EIRP_max = 58;
        RE.AF.AppGain = 26;
    otherwise
        error('Radio entity type not recognized');
end

end

