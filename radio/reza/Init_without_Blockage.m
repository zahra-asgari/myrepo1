clc; clear all; %#ok<*CLALL>


% Define Communication medium
Params.comm = Set_CommParams(28e9,200e6,'NoShadowing');

% Define Tx
% Params.Tx = Network_Entity('UE',[0,-20,1.5], Params.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class2');
Params.Tx = Network_Entity('BS',[0,-20,7],Params.comm,'Type','IAB','Orientation',0);
% Params.Tx = Network_Entity('BS',[0,-20,7],Params.comm,'Type','Donor','Orientation',0);

% Define Rx

% Params.Rx = Network_Entity('BS',[0,+20,7],Params.comm,'Type','Donor','Orientation',0);
% Params.Rx = Network_Entity('BS',[0,+20,7],Params.comm,'Type','IAB','Orientation',0);
Params.Rx = Network_Entity('UE',[0,+20,1.5], Params.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class2');



% Define RIS
% prm.RIS = Network_Entity('RIS',[+40,0,2],prm.comm,'Orientation',-pi);
% prm.RIS = Network_Entity('RIS',[0,0,0], prm.comm,'Orientation',-pi);
% Params.RIS = Network_Entity('RIS',[0,0,0], Params.comm,'Orientation',-pi,'Dir','true');
Params.RIS = Network_Entity('RIS',[0,0,0], Params.comm,'Orientation',-pi,'Dir','true','Policy','Anomalous','Nh',100,'Nv',100);


% Define AF
Params.AF = Network_Entity('AF',[0,0,0], Params.comm,'Orientation','Optimum','Type','Option2');


% Scenarios
Scenario.Tx2Rx = 'UMi';
Scenario.Tx2AF = 'UMi';
Scenario.AF2Rx = 'UMi';

%% Simulation

RIS_y_vect = -80:1:100;
% RIS_y_vect = -20;
SNR_RIS = zeros(1,length(RIS_y_vect));
SNR_AF_max = zeros(1,length(RIS_y_vect));
SNR_AF_min = zeros(1,length(RIS_y_vect));
SNR_DL = zeros(1,length(RIS_y_vect));

for yy = 1:length(RIS_y_vect)
    Relay_Y = RIS_y_vect(yy);
    Params.RIS.Center = [+40,Relay_Y, +3];
    Params.AF.Center = [+40,Relay_Y, +3];
    disp(['The Y axis iteration ',num2str(yy),' out of ',num2str(length(RIS_y_vect))])

    [H_D,SNR] = Compute_Channel(Params,Scenario);
    SNR_RIS(yy) = SNR.RIS;
    SNR_AF_min(yy) = SNR.AF_min;
    SNR_AF_max(yy) = SNR.AF_max;
    SNR_DL(yy) = SNR.DL;
end
% disp(SNR_RIS(yy))
%%
plot(RIS_y_vect,SNR_DL,'LineWidth',1.5,'color',[255, 102, 0]/255)
hold on
plot(RIS_y_vect,SNR_RIS,'LineWidth',1,'color',[0, 190, 0]/255)
plot(RIS_y_vect,SNR_AF_min,'LineWidth',1,'color',[ 252  163  198]/255)
plot(RIS_y_vect,SNR_AF_max,'LineWidth',1,'color',[255, 51, 153]/255)
PicturePos = [287    51   750   560];
set(gcf,'Position',PicturePos)
A = findobj('Type','Line');
set(A,'MarkerIndices',1:ceil(length(RIS_y_vect)/10):length(RIS_y_vect));

% plot(RIS_y_vect,SNR_DF)
% legend({'RIS SNR','Direct SNR','Total SNR'})
