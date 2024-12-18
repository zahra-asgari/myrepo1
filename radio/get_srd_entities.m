function [RE] = get_srd_entities(re_type,radio_prm)
%GET_RE.Tx_ENTITIES This function returns the  parameters of a choosen
%smart radio device entiry (provided as a string input) - Author: Eugenio Moro
%   Supported srd entities: AF Type 1
%   'af_type_1' - AF Type 2 'af_type_2' - RIS 'ris'
RE.type = re_type;              % inter-element spacing
switch re_type
    case 'ris'
        RE.RIS.M = 100;
        RE.RIS.N = 100;
        RE.RIS.Nris = RE.RIS.M * RE.RIS.N ;
        RE.RIS.dx =  radio_prm.lambda/2;
        RE.RIS.dy = radio_prm.lambda/2;
        RE.RIS.Size = [sqrt(RE.RIS.Nris), sqrt(RE.RIS.Nris)] .* (radio_prm.lambda/2);
        %RE.RIS.Orientation  = 'Optimum';
        RE.RIS.Orientation = -180;
        %RE.RIS.reconf_policy = 'Focus';
         RE.RIS.reconf_policy = 'FF_Anamolous';
%         RE.RIS.reconf_policy = 'FF_Assympt';
%         RE.RIS.reconf_policy = 'SmSk';
    case 'af_type_1'
        RE.AF.NF = 8;
        % RE.AF.Type = 'Option1';
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
        % RE.AF.Type = 'Option1';
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
        error('RE.Tx entity not recognized');
end
end

