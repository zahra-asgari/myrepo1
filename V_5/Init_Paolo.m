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

