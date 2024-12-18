clearvars;
addpath('simulation_scenarios','classes');
addpath('radio/assets');
%addpath('radio/reza');
addpath('radio/funct/');
addpath('radio');
scenario = default_scenario();
clc; clear all; %#ok<*CLALL>

prm.comm = Set_CommParams(28e9,200e6,'NoShadowing');

% Define Tx
% prm.Tx = Network_Entity('BS',[0,-20,2],prm.comm,'Type','IAB','Orientation',0);
% 
% % Define Rx
% % prm.Rx = Network_Entity('UE',[0,+20,2], prm.comm,'Orientation','Optimum');
% prm.Rx = Network_Entity('UE',[0,+20,2], prm.comm,'Orientation','Optimum','Nh',1,'Nv',1,'Type','Class3');
% 
% 
% % Define RIS
% % prm.RIS = Network_Entity('RIS',[+40,0,2],prm.comm,'Orientation',-pi);
% prm.RIS = Network_Entity('RIS',[10,0,0], prm.comm,'Orientation',-pi);
% 
% 
% % Define AF
% prm.AF = Network_Entity('AF',[0,0,0], prm.comm,'Orientation','Optimum','Type','Option1');

% Configurations
% Config.Structure = SetArrayConf(prm);
% Scenarios
Scenario.Tx2Rx = 'UMi';
Scenario.Tx2AF = 'UMi';
Scenario.AF2Rx = 'UMi';

bs_pos=[[0,-20,2]; [20,0,2]]
tp_pos=[[0,20,2] ;[10,10,2]]
ris_pos=[[10,0,1] ;[15 5 1]]
SNR_direct=zeros(2,1);
SNR_RIS=zeros(2,1);
SNR_AF_max=zeros(2,1);
SNR_AF_min=zeros(2,1);
for i = 1:2
    % Define Tx
prm.Tx = Network_Entity('BS',bs_pos(i,:),prm.comm,'Type','IAB','Orientation','Optimum');

% Define Rx
% prm.Rx = Network_Entity('UE',[0,+20,2], prm.comm,'Orientation','Optimum');
prm.Rx = Network_Entity('UE',tp_pos(i,:), prm.comm,'Orientation','Optimum','Nh',1,'Nv',1,'Type','Class3');


% Define RIS
% prm.RIS = Network_Entity('RIS',[+40,0,2],prm.comm,'Orientation',-pi);
prm.RIS = Network_Entity('RIS',ris_pos(i,:), prm.comm,'Orientation','Optimum');


% Define AF
prm.AF = Network_Entity('AF',ris_pos(i,:), prm.comm,'Orientation','Optimum','Type','Option1');


%% Simulation
% prm.Tx.Center = [0,-20,6];
% prm.Rx.Center = [0,20,1.5];
% prm.Relay.Center = [10, 0, 3];

% prm.Tx.Center = [0,-20,2];
% prm.Rx.Center = [0, 20,2];
% RIS_y_vect = -40:1:40;
% % RIS_y_vect = 0;
% SNR_RIS = zeros(1,length(RIS_y_vect));
% SNR_AF_max = zeros(1,length(RIS_y_vect));
% SNR_AF_min = zeros(1,length(RIS_y_vect));
% SNR_DF = zeros(1,length(RIS_y_vect));
% SNR_DL = zeros(1,length(RIS_y_vect));
[SNR] = Compute_Channel(prm,Scenario);
    %     disp(SNR.RIS)
    SNR_direct(i)=SNR.DL;
    SNR_RIS(i) = SNR.RIS;
    SNR_AF_min(i) = SNR.AF_min;
    SNR_AF_max(i) = SNR.AF_max;
end
% RIS_y_vect = 0; mk
% for yy = 1:length(RIS_y_vect)
%     disp(['The Y axis iteration ',num2str(yy),' out of ',num2str(length(RIS_y_vect))])
%     prm.Relay.Center = [40,RIS_y_vect(yy),2];
%     [H_D,H_RIS,SNR] = Compute_Channel(prm,Config,Scenario);
%     %     disp(SNR.RIS)
%     SNR_RIS(yy) = SNR.RIS;
%     SNR_AF_min(yy) = SNR.AF_min;
%     SNR_AF_max(yy) = SNR.AF_max;
%     %     SNR_DF(yy) = SNR.DF;
%     SNR_DL(yy) = SNR.DL;
% end
% % disp(SNR_RIS(yy))
% %%
% % MyMarker = 'none';
% plot(RIS_y_vect,SNR_DL,'LineWidth',1.5,'color',[255, 102, 0]/255)
% hold on
% plot(RIS_y_vect,SNR_RIS,'LineWidth',1,'color',[0, 190, 0]/255)
% plot(RIS_y_vect,SNR_AF_min,'LineWidth',1,'color',[ 252  163  198]/255)
% plot(RIS_y_vect,SNR_AF_max,'LineWidth',1,'color',[255, 51, 153]/255)
% PicturePos = [287    51   750   560];
% set(gcf,'Position',PicturePos)
% A = findobj('Type','Line');
% set(A,'MarkerIndices',1:ceil(length(RIS_y_vect)/10):length(RIS_y_vect));
% 
% % plot(RIS_y_vect,SNR_DF)
% % legend({'RIS SNR','Direct SNR','Total SNR'})

% %%
% function [Params] = Set_CommParams(Fc,BW,ShadowingFlag)
% % propagation parameters
% Params.BW = BW;
% Params.fc = Fc;                   % [Hz] carrier frequency
% Params.a =1;                        % reflection amplitude at irs
% c = physconst('lightspeed');     % lightspeed
% Params.lambda = c / Params.fc;         % [m] wavelength
% if isequal(ShadowingFlag,'Shadowing')
%     Params.ShadowingSTD = 4;
% elseif isequal(ShadowingFlag,'NoShadowing')
%     Params.ShadowingSTD = 0;
% else
%     error('Define shadowing status')
% end
% end
% 
% 
% function [BS] = Define_BS(Type,prm,BSRotation)
% BS.d = prm.lambda/2;                     % inter-element spacing
% BS.Efficiency = 0.8;
% switch Type
%     case  'Donor'
%         BS.NF = 8.5;                     % [dB] noise figure
%         BS.EIRP = 58;
%         BS.Ptx = 35;
%         BS.Tilt = -7;
%         BS.MaxDownSteerElevDegree = 15;
%         BS.DownTiltDegree = -7;
%         BS.Nh = 16;
%         BS.Nv = 12;
%     case  'IAB'
%         BS.NF = 9;                     % [dB] noise figure
%         BS.EIRP = 51;
%         BS.Ptx = 31;
%         BS.MaxDownSteerElevDegree = 30;
%         BS.DownTiltDegree = -7;
%         BS.Nh = 12;
%         BS.Nv = 8;
% 
% end
% BS.ArrSize = BS.Nh * BS.Nv;
% if isnumeric(BSRotation)
%     BS.Orientation = deg2rad(BSRotation);
% else
%     BS.Orientation = BSRotation;
% end
% end
% 
% 
% 
% function [UE] = Define_UE(Nh,Nv,Type,band,prm)
% UE.Orientation =  'Optimum';
% % UE.Orientation =  'Random';
% % UE.Orientation =  'BS';
% % UE.Orientation =  'Relay';
% UE.Pt = 23;
% UE.Nh = Nh;
% UE.Nv = Nv;
% UE.NF = 10;
% UE.Efficiency = 1;
% UE.ArrSize = UE.Nh * UE.Nv;
% UE.EIRP = UE.Pt + 10*log10(UE.ArrSize) + 10*log10(UE.Efficiency);
% UE.d = prm.lambda/2;    % inter-element spacing
% % UE.Orientation = 'Optimum';
% % UE.Orientation = 'Tx';
% % UE.Orientation = 'Relay';
% % UE.Orientation = 'Random';
% % UE.Orientation = 30;
% 
% switch Type
%     case  'class1'
%         switch band
%             case  'n257'
%                 MinPeak_EIRP = 40; %#ok<*NASGU>
%                 Max_TRP = 35;
%                 Max_EIRP = 55;
%             case  'n258'
%                 MinPeak_EIRP = 40;
%                 Max_TRP = 35;
%                 Max_EIRP = 55;
%             case  'n260'
%                 MinPeak_EIRP = 38;
%                 Max_TRP = 35;
%                 Max_EIRP = 55;
%             case  'n261'
%                 MinPeak_EIRP = 40;
%                 Max_TRP = 35;
%                 Max_EIRP = 55;
%         end
%         
%         
%     case  'class2'
%         switch band
%             case  'n257'
%                 MinPeak_EIRP = 29;
%                 Max_TRP = 23;
%                 Max_EIRP = 43;
%             case  'n258'
%                 MinPeak_EIRP = 29;
%                 Max_TRP = 23;
%                 Max_EIRP = 43;
%             case  'n260'
%                 MinPeak_EIRP = [];
%                 Max_TRP = [];
%                 Max_EIRP = [];
%             case  'n261'
%                 MinPeak_EIRP = 29;
%                 Max_TRP = 23;
%                 Max_EIRP = 43;
%         end
%         
%         
%     case  'class3'
%         switch band
%             case  'n257'
%                 MinPeak_EIRP = 22.4;
%                 Max_TRP = 23;
%                 Max_EIRP = 43;
%             case  'n258'
%                 MinPeak_EIRP = 22.4;
%                 Max_TRP = 23;
%                 Max_EIRP = 43;
%             case  'n260'
%                 MinPeak_EIRP = 20.6;
%                 Max_TRP = 23;
%                 Max_EIRP = 43;
%             case  'n261'
%                 MinPeak_EIRP = 22.4;
%                 Max_TRP = 23;
%                 Max_EIRP = 43;
%         end
%         
%     case  'class4'
%         switch band
%             case  'n257'
%                 MinPeak_EIRP = 34;
%                 Max_TRP = 23;
%                 Max_EIRP = 43;
%             case  'n258'
%                 MinPeak_EIRP = 34;
%                 Max_TRP = 23;
%                 Max_EIRP = 43;
%             case  'n260'
%                 MinPeak_EIRP = 31;
%                 Max_TRP = 23;
%                 Max_EIRP = 43;
%             case  'n261'
%                 MinPeak_EIRP = 34;
%                 Max_TRP = 23;
%                 Max_EIRP = 43;
%         end
% end
% 
% if UE.Pt > Max_TRP
%     error('Transmit power cannot exceed the TRP at this band for this class of UE amplifier')
% elseif UE.EIRP < MinPeak_EIRP
%     error('EIRP is less than minimum possible EIRP at this band for this class of UE amplifier, if the transmit power cannot be increases, probabely a larger array is required')
% elseif  UE.EIRP > Max_EIRP
%     error('EIRP is more than allowed maximum EIRP at this band for this class of UE amplifier')
% end
% end
% 
% 
% function [Config,RIS] = Define_RIS(M,N, Orientation,prm)
% RIS.M = M;
% RIS.N = N;
% RIS.Nris = RIS.M * RIS.N ;
% RIS.dx =  prm.lambda/2;
% RIS.dy = prm.lambda/2;
% RIS.Size = [sqrt(RIS.Nris), sqrt(RIS.Nris)] .* (prm.lambda/2);
% % RIS.Orientation  = 'Optimum';
% RIS.Orientation = Orientation;
% 
% % Config.Policy = 'Specular'; % 'FF' for RIS with far field assumption, 'SmSk' for smart skin, 'Focus' for optimum RIS
% Config.Policy = 'Anamolous'; % 'FF' for RIS with far field assumption, 'SmSk' for smart skin, 'Focus' for optimum RIS
% % Config.Policy = 'Focus'; % 'FF' for RIS with far field assumption, 'SmSk' for smart skin, 'Focus' for optimum RIS
% % Config.Policy = 'FF_Assympt';
% Config.ElementDirectivity = 'true';
% % Config.ElementDirectivity = 'false';
% 
% end
% 
% 
% 
% 
% 
% 
% function AF = Define_AF(Type)
% AF.NF = 8;
% % prm.AF.Type = 'Option1';
% 
% AF.MaxDownSteerElevDegree = 30;
% AF.Pan2DownTiltDegree = -5;
% % prm.AF.Pan2DownTiltDegree = 'Optimum';
% AF.Orientation = 'Optimum';
% % AF.Orientation = 'Random';
% % AF.Orientation = 120;
% switch Type
%     case  'Option1'
%         AF.EIRP_min = 40;
%         AF.EIRP_max = 55;
%         AF.AppGain = 20;
%     case  'Option2'
%         AF.EIRP_min = 40;
%         AF.EIRP_max = 58;
%         AF.AppGain = 26;
% end
% end
% 
% % rx_entity = get_rx_entities('omni_ue',scenario.radio_prm);
% % tx_entity = get_tx_entities('donor',scenario.radio_prm);
% % ris_entity = get_srd_entities('ris',scenario.radio_prm);
% % af_entity = get_srd_entities('af_type_1',scenario.radio_prm);
% % 
% % tx_entity.pos = [0,-20,6];
% % % rx_entity.pos = [0,20,1.5];
% % % ris_entity.pos = [10, 0, 3];
% % % af_entity.pos = ris_entity.pos;
% % 
% % rx_entity = radio_entity('ue_omni',scenario.radio_prm);
% % tx_entity = radio_entity('donor',scenario.radio_prm);
% % ris_entity = radio_entity('ris',scenario.radio_prm);
% % 
% % ris_entity.orientation = 'Specular';
% % 
% % tx_entity.position = [0,-20,6];
% % rx_entity.position = [0,20,1.5];
% % ris_entity.position = [10, 0, 3];
% % 
% % %%
% % 
% % direct_snr = direct_channel_snr(tx_entity, rx_entity, ris_entity, scenario.radio_prm);
% % ris_snr = ris_channel_snr(tx_entity, rx_entity, ris_entity, scenario.radio_prm);
% % %af_snr = af_channel_snr(tx_entity, rx_entity, af_entity, scenario.radio_prm);