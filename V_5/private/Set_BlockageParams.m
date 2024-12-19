function Blockage = Set_BlockageParams(Fc,h_BS,BlockerHeightAvg,...
    BlockageAvgWidth,BlockageAvgLen,Lambda_Blocker_Per_m2,LossCriteria,WhatToDO)
h_UE = 1.5;
% LossCriteria = 'Median';
% LossCriteria = 'Random';
% LossCriteria = 'Percentile';
% LossCriteria = 'Mean';
Percentile = 90;

Info = ['Fc_',num2str(ceil(Fc/1e9)),'_Hbs_',num2str(h_BS),'_HB_',num2str(BlockerHeightAvg),...
    '_WB_',num2str(BlockageAvgWidth),'_LB_',num2str(BlockageAvgLen),...
    '_LambdaB_',num2str(Lambda_Blocker_Per_m2)];


if exist(['Blockage_Data/',Info,'.mat']) %#ok<*EXIST>
    disp("File .mat found")
    Blockage = load(['Blockage_Data/',Info,'.mat']);
    %     BlockageData = ;
    %     Blockage.Handle = @(R) Interpolate_Blockage(R,Data);
    Blockage.Handle = @Interpolate_Blockage;
    Blockage.LossCriteria = LossCriteria;
    Blockage.Percentile = Percentile;
elseif ~exist (['Blockage_Data/',Info,'.mat']) && isequal(WhatToDO,'Interpolate')
    %     BlockageData = Generate_Blockage(BlockageData);
    
    Input.Fc = Fc;
    Input.h_BS = h_BS;
    Input.h_UE = h_UE;
    Input.Lambda_Blocker_Per_m2 = Lambda_Blocker_Per_m2;
    Input.BlockerHeightAvg = BlockerHeightAvg;
    Input.BlockageAvgWidth = BlockageAvgWidth;
    Input.BlockageAvgLen = BlockageAvgLen;
    Input.Task = 'Save';
    UE_radius_vect = linspace(10,200,40);
    %UE_radius_vect = linspace(10,400,391);
    %da 10 a 100 in 19 intervalli: 10000 MonteCarlo ogni circa 4.73 m
    %UE_radius_vect = [10,20];
    Generate_Blockage(UE_radius_vect,Input);
    Blockage =  load(['Blockage_Data/',Info,'.mat']);
%     Blockage = load(['Blockage_Data/',Info,'.mat']);
    
    %     Blockage.Handle = @Interpolate_Blockage(R,Data);
    Blockage.Handle = @Interpolate_Blockage;
    Blockage.LossCriteria = LossCriteria;
    Blockage.Percentile = Percentile;
elseif ~exist (['Blockage_Data/',Info,'.mat']) && isequal(WhatToDO,'RunOnDemand')
     
    Blockage.Fc = Fc;
    Blockage.h_BS = h_BS;
    Blockage.h_UE = h_UE;
    Blockage.Lambda_Blocker_Per_m2 = Lambda_Blocker_Per_m2;
    Blockage.BlockerHeightAvg = BlockerHeightAvg;
    Blockage.BlockageAvgWidth = BlockageAvgWidth;
    Blockage.BlockageAvgLen = BlockageAvgLen;
    Blockage.Task = 'Return';
    
%     Blockage.Handle = @(R) Generate_Blockage(R,Blockage,'Return');
    Blockage.Handle = @Generate_Blockage;
    Blockage.LossCriteria = LossCriteria;
    Blockage.Percentile = Percentile;
end


end

