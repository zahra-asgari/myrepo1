clear all;   clc

%%
addpath('scenarios','utils','gen_functions','gen_scripts',...
    'model_builder','site_plot_functions','radio','radio/functions','classes');

Par.comm = Set_CommParams(28e9,200e6,'NoShadowing');
Scenario.Tx2Rx = 'UMi';
Scenario.Tx2AF = 'UMi';
Scenario.AF2Rx = 'UMi';


Par.Tx = Network_Entity('BS',[0,-40,6],Par.comm,'Type','IAB','Orientation',0);
% Par.Tx = Network_Entity('UE',[0,-40,3], Par.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class3');

Par.Rx = Network_Entity('UE',[0,+40,3], Par.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class3');
% % % Par.TIS = Network_Entity('RIS',[0,0,0], Par.comm,'Orientation',-pi/2,...
% % %     'Dir','true','Policy','Anomalous','Nh',200,'Nv',200,'Mode','T');


 
% Par.RIS= Network_Entity('RIS',[0,0,0], Par.comm,'Orientation',pi+pi/4,'Dir','true',...
%     'Policy','An_Flat','Nh',100,'Nv',100,'Type','Curved','CurveRadius',100,...
%     'Mode','Conventional');


% % Par.RIS= Network_Entity('RIS',[0,0,0], Par.comm,'Orientation',pi+pi/4,'Dir','true',...
% %     'Policy','An_Curved','Nh',100,'Nv',100,'Type','Curved','CurveRadius',1,...
% %     'Mode','Conventional');


% Par.RIS= Network_Entity('RIS',[0,0,0], Par.comm,'Orientation',pi-pi/4,'Dir','true',...
%     'Policy','An_Flat','Nh',100,'Nv',100,'Type','Flat','Mode','Star_R');

Par.RIS= Network_Entity('RIS',[0,0,0], Par.comm,'Orientation',pi+pi/10,'Dir','true',...
    'Policy','FF_Assympt','Nh',100,'Nv',100);


Par.Config.Check_Static_Blockage = false;
Par.Config.Check_Dynamic_Blockage = false;
% Par.RIS = Network_Entity('RIS',[0,0,3], Par.comm,'Orientation',-pi,'Dir','true','Policy','Specular','Nh',200,'Nv',200);




Par.comm = Set_CommParams(28e9,200e6,'NoShadowing');
Par.Blockage = Set_BlockageParams(28e9,6,3,2,2,4e-3,'Median','Interpolate');
% Scenarios
Scenario.Tx2Rx = 'UMi';
Scenario.Tx2AF = 'UMi';
Scenario.AF2Rx = 'UMi';

%% Simulation

RIS_y_vect = -40:2:40;
% RIS_y_vect = 0;
RIS_x_vect = linspace(20,50,length(RIS_y_vect));
RIS_z_vect = linspace(0.5,5,length(RIS_y_vect));
% RIS_y_vect = -20;
SNR_RIS = zeros(1,length(RIS_y_vect));
SNR_AF_max = zeros(1,length(RIS_y_vect));
SNR_AF_min = zeros(1,length(RIS_y_vect));
% SNR_DF = zeros(1,length(RIS_y_vect));
SNR_DL = zeros(1,length(RIS_y_vect));
PB_Direct = zeros(1,length(RIS_y_vect));
PB_Relay = zeros(1,length(RIS_y_vect));
LB_Direct = zeros(1,length(RIS_y_vect));
LB_Relay = zeros(1,length(RIS_y_vect));

% RIS_y_vect = 0; mk
for iteration = 1:length(RIS_y_vect)
%     Relay_X = RIS_x_vect(iteration);
    Relay_X = 40;
    Relay_Y = RIS_y_vect(iteration);
%     Relay_Z = RIS_z_vect(iteration);
    Relay_Z = 3;
    Par.RIS.Center = [Relay_X,Relay_Y, Relay_Z];
    disp(['The Y axis iteration ',num2str(iteration),' out of ',num2str(length(RIS_y_vect))])

    [~,SNR,Blockage] = Compute_Channel_for_fun(Par,Scenario);
    SNR_RIS(iteration) = SNR.RIS;
    SNR_DL(iteration) = SNR.DL;
end
% disp(SNR_RIS(yy))
%%
% MyMarker = 'none';
plot(RIS_y_vect,SNR_DL,'LineWidth',1.5,'color',[255, 102, 0]/255)
hold on
plot(RIS_y_vect,SNR_RIS,'LineWidth',1,'color',[0, 190, 0]/255)

PicturePos = [287    51   750   560];
set(gcf,'Position',PicturePos)
A = findobj('Type','Line');
set(A,'MarkerIndices',1:ceil(length(RIS_y_vect)/10):length(RIS_y_vect));


