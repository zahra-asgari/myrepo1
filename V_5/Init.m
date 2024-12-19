clc; clear all; %#ok<*CLALL>
RelX = 20;
TxY = -40;
RxY = 40;
run = 1;
switch run
    %RIS size
    case 1
        N = 100;
        M = 100;
    case 2
        N = 200;
        M = 200;
end
% Params.Config.Check_Static_Blockage = true;
Params.Config.Check_Static_Blockage = false;
Params.Config.Check_Dynamic_Blockage = true;
% Params.Config.Check_Dynamic_Blockage = false;

% Define Communication medium
Params.comm = Set_CommParams(28e9,200e6,'NoShadowing');


% Define Blockage params
% prm.Blockage = Set_BlockageParams(28e9,3,3,2,2,2e-3,'RunOnDemand');
% Params.Blockage = Set_BlockageParams(28e9,6,3,2,2,2e-3,'Median','Interpolate')
%I have to run this 3 times for the different link heights (Donor H = 25 m, IAB H = 6 m,
%RIS H = 3)
%Obstacle size has been calculated to be (4.5,1.8,1.6)[L,W,H]
%but the order in here is (H,W,L)
%Random should give a random value from the distribution, I don't know if I
%will extract the values like this or in another way
Params.Blockage = Set_BlockageParams(28e9,25,1.6,1.8,4.5,2e-3,'Random','Interpolate');
%Params.Blockage = Set_BlockageParams(28e9,6,3,2,2,5e-3,'Random','Interpolate');
% AA = prm.Blockage.Handle(100,prm.Blockage);
% disp(prm.Blockage.Handle(50,prm.Blockage))

% Address = [pwd,'/Blockage_Data'];
% Name = 'leonardoBuildings.mat';
% [Params.Blockage]= Set_Buildings(Address,Name,Params.Blockage);

% Map_Center = [5.177e5,5.0362e6,0];
Map_Center = [0,0,0];

% Define Tx
% Params.Tx = Network_Entity('UE',[0,-20,1.5], Params.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class2');
Params.Tx = Network_Entity('BS',[0,TxY,7]+Map_Center,Params.comm,'Type','IAB','Orientation',0);
% Params.Tx = Network_Entity('BS',[0,-20,7],Params.comm,'Type','Donor','Orientation',0);



% Define Rx
% Params.Rx = Network_Entity('BS',[0,+20,7],Params.comm,'Type','Donor','Orientation',0);
% Params.Rx = Network_Entity('BS',[0,+20,7],Params.comm,'Type','IAB','Orientation',0);
Params.Rx = Network_Entity('UE',[0,RxY,1.5]+ Map_Center, Params.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class2');



% Define RIS
% prm.RIS = Network_Entity('RIS',[+40,0,2],prm.comm,'Orientation',-pi);
% prm.RIS = Network_Entity('RIS',[0,0,0], prm.comm,'Orientation',-pi);
% Params.RIS = Network_Entity('RIS',[0,0,0], Params.comm,'Orientation',-pi,'Dir','true');
% Params.RIS = Network_Entity('RIS',[0,0,0], Params.comm,'Orientation',-pi,'Dir','true','Policy','FF_Assympt','Nh',100,'Nv',100);
Params.RIS = Network_Entity('RIS',[0,0,0]+Map_Center, Params.comm,'Orientation',-pi,'Dir','true','Policy','Anomalous','Nh',N,'Nv',M);

% Define AF
Params.AF = Network_Entity('AF',[0,0,0]+Map_Center, Params.comm,'Orientation','Optimum','Type','Option2');

% plot(Params.Tx.Center(1),Params.Tx.Center(2),'O','MarkerSize',6)
% hold on
% plot(Params.Rx.Center(1),Params.Rx.Center(2),'*','MarkerSize',6)
% plot(Params.AF.Center(1),Params.AF.Center(2),'D','MarkerSize',8)
% % %


% Scenarios
Scenario.Tx2Rx = 'UMi';
Scenario.Tx2AF = 'UMi';
Scenario.AF2Rx = 'UMi';

%% Simulation

RIS_y_vect = -80:1:80;
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

for yy = 1:length(RIS_y_vect)
    Relay_Y = RIS_y_vect(yy);
    Params.RIS.Center = [RelX,Relay_Y, +3] + Map_Center;
    Params.AF.Center = [RelX,Relay_Y, +3] + Map_Center;
    disp(['The Y axis iteration ',num2str(yy),' out of ',num2str(length(RIS_y_vect))])
    %     prm.Relay.Center = [40,RIS_y_vect(yy),2];
    %     [H_D,H_RIS,SNR] = Compute_Channel(prm,Scenario);
    [~,SNR,Blockage] = Compute_Channel(Params,Scenario);
    %     disp(SNR.RIS)
    SNR_RIS(yy) = SNR.RIS;
    SNR_AF_min(yy) = SNR.AF_min;
    SNR_AF_max(yy) = SNR.AF_max;
    %     SNR_DF(yy) = SNR.DF;
    SNR_DL(yy) = SNR.DL;
    
    
    PB_Direct(yy) = Blockage.Direct.PB;
    PB_Relay(yy) = Blockage.AF.PB;
    
    LB_Direct(yy) = Blockage.Direct.Loss;
    LB_Relay(yy) = Blockage.AF.Loss;
end
% disp(SNR_RIS(yy))
%%
% MyMarker = 'none';

switch run
    case 1
        plot(RIS_y_vect,SNR_DL,'LineWidth',2,'color',[255, 102, 0]/255)
        hold on
        plot(RIS_y_vect,SNR_AF_max,'LineWidth',2,'color',[255, 51, 153]/255)
        plot(RIS_y_vect,SNR_AF_min,'LineWidth',2,'color',[ 252  163  198]/255,'LineStyle','--')
        plot(RIS_y_vect,SNR_RIS,'LineWidth',2,'color',[0, 190, 0]/255)
        
    case 2
        plot(RIS_y_vect,SNR_RIS,'LineWidth',2,'color',[0, 190, 0]/255,'LineStyle','--')
end
set(gca,'FontSize',14)
PicturePos = [287    51   750   560];
set(gcf,'Position',PicturePos)
A = findobj('Type','Line');
set(A,'MarkerIndices',1:ceil(length(RIS_y_vect)/10):length(RIS_y_vect));
xlabel('$Y_{relay}$ (m)','FontSize',20,'Interpreter','Latex')
ylabel('SNR (dB)','FontSize',20,'Interpreter','Latex')
% plot(RIS_y_vect,SNR_DF)
% legend({'RIS SNR','Direct SNR','Total SNR'})

% % % figure(2)
% % % plot(RIS_y_vect,PB_Direct,'LineWidth',1.5,'color',[255, 102, 0]/255)
% % % hold on
% % % plot(RIS_y_vect,PB_Relay,'LineWidth',1,'color',[0, 190, 0]/255)
% % %
% % %
% % %
% % % figure(3)
% % % plot(RIS_y_vect,LB_Direct,'LineWidth',1.5,'color',[255, 102, 0]/255)
% % % hold on
% % % plot(RIS_y_vect,LB_Relay,'LineWidth',1,'color',[0, 190, 0]/255)

if run == 2
    LGD1 = {'Direct Link','Smart Repeater, Option2','Smart Repeater, Option1','RIS, $100 \times 100$','RIS, $200 \times 200$'};
legend(LGD1,'Location','Southwest','FontSize',14,'Interpreter','Latex')
Adress = [pwd,'\Results\'];

Information = ['XRel',num2str(RelX),'_TxY_',num2str(TxY),'_RxY_',num2str(RxY),'AF_Lim',num2str(20)];
FileName = [Information,'.fig'];
savefig([Adress,FileName])
close 

end


