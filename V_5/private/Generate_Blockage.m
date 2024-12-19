function Blockage = Generate_Blockage(UE_radius_vect,Data)
BlockerHeightAvg = Data.BlockerHeightAvg;
h_BS = Data.h_BS;
Lambda_Blocker_Per_m2 = Data.Lambda_Blocker_Per_m2;
h_UE = Data.h_UE;
BlockageAvgWidth = Data.BlockageAvgWidth;
BlockageAvgLen = Data.BlockageAvgLen;
% h_UE = Blockage.h_UE;
Fc = Data.Fc;
% h_BS = 6; %% BSs height
% Lambda_Blocker_Per_m2 = 5e-3;
% BlockerHeightAvg = 3;
% BlockageAvgWidth = 2;
% BlockageAvgLen = 2;
WhatToDo = Data.Task;
GaussModel = makedist('Normal','mu',BlockerHeightAvg ,'sigma',0.1);
BlockageStat.HeighDist = truncate(GaussModel,h_UE,h_BS);
GaussModel = makedist('Normal','mu',BlockageAvgWidth ,'sigma',0.2);
BlockageStat.WidthDist = truncate(GaussModel,0,inf);
GaussModel = makedist('Normal','mu',BlockageAvgLen ,'sigma',0.2);
BlockageStat.LenDist = truncate(GaussModel,0,inf);
% MaxRadius = 100; %% meters
BSPos2D = [0,0];

% UE_radius_vect = 100;
% UE_radius_vect = linspace(10,100,20);
PB = zeros(1,length(UE_radius_vect));
% MC_iters = 1e3;
% MC_iters_vec = ceil(5e5 ./ UE_radius_vect);
%This function reduces progressively the number of MonteCarlo trials as the
%length of the link increases, to speed up calculations, but it reduces
%accuracy
%MC_iters_vec = ceil(2e5 ./ UE_radius_vect);
MC_iters = 1e4;
EstimatedMixtureModel = cell(1,length(UE_radius_vect));
EstimatedGaussModel = cell(1,length(UE_radius_vect));
ECDFs = cell(1,length(UE_radius_vect));
xAx = cell(1,length(UE_radius_vect));
Mu_vs_R = zeros(1,length(UE_radius_vect));
Sig_vs_R = zeros(1,length(UE_radius_vect));

% Mu1_vs_R = zeros(1,length(UE_radius_vect));
% Mu2_vs_R = zeros(1,length(UE_radius_vect));

% Sig_vs_R = zeros(1,length(UE_radius_vect));
% Sig1_vs_R = zeros(1,length(UE_radius_vect));
% Sig2_vs_R = zeros(1,length(UE_radius_vect));

% Prop1_vs_R = zeros(1,length(UE_radius_vect));
% Prop2_vs_R = zeros(1,length(UE_radius_vect));

for rad_iter = 1:length(UE_radius_vect)
    %MC_iters = MC_iters_vec(rad_iter);
    GivenRadius = UE_radius_vect(1,rad_iter);
    disp(['radius = ',num2str(GivenRadius )])
    
    Lambda_B_tot = Lambda_Blocker_Per_m2 * pi * (GivenRadius^2);
    N_BLs = max(ceil(poissrnd(Lambda_B_tot)),1);
    AllLosses = zeros(MC_iters,N_BLs);
    Total_Loss = zeros(1,MC_iters);
    
    
    Blockages = zeros(1,MC_iters);
    parfor MC = 1:MC_iters
        %         tic
        disp(['MC iteration ',num2str(MC),' for radius = ',num2str(GivenRadius)])
        %         UE_Pos_temp = (GivenRadius*sqrt(rand(1,1))).*exp(1j*2*pi*(rand(1,1)));
        UE_Pos_temp = (GivenRadius/sqrt(2)) + (1j*GivenRadius/sqrt(2));
        UEPos2D = [real(UE_Pos_temp),imag(UE_Pos_temp)];
        Blockage_temp = zeros(1,N_BLs);
        OtherBlockers = {};
        
        for k = 1:N_BLs
            ThisBlocker = Blocker(BlockageStat);
            [ThisBlocker,AllBlockers] = ThisBlocker.SetBlocker(OtherBlockers,max(GivenRadius,10));
            [Blockage_temp(1,k),ThisBlocker] = ThisBlocker.CheckIndicdence([BSPos2D,h_BS],[UEPos2D,h_UE]);
            %             [AllLosses(MC,k),ThisBlocker] = ThisBlocker.BlockageLoss(Fc);
            [AllLosses(MC,k),~] = ThisBlocker.BlockageLoss(Fc);
            OtherBlockers = AllBlockers;
            
            %                         plot(ThisBlocker.Polygon2D)
            %                         hold on
        end
        if ~isempty(Blockage_temp)
            Blockages(1,MC) = max(Blockage_temp);
        else
            Blockages(1,MC) = nan;
        end
        %         toc
    end
    Total_Loss(1,:) = sum(AllLosses,2);
    PB(1,rad_iter) = sum(Blockages) / MC_iters;
    
    
    %     if isequal(WhatToDo,'Save')
    %     disp(PB(1,rad_iter))
    %     xAx = linspace(0,80,200);
    A = Total_Loss(Total_Loss~=0);
    %     A(A<=0.27) = [];
    [ECDFs{1,rad_iter} ,xAx{1,rad_iter} ] = ecdf(A);
    %     ecdf(A)
    
    EstimatedGaussModel{1,rad_iter}  = fitdist(A.','Normal');
    Mu_vs_R(1,rad_iter) = EstimatedGaussModel{1,rad_iter} .mu;
    Sig_vs_R(1,rad_iter) = EstimatedGaussModel{1,rad_iter} .sigma;
    
    %     B = cdf(EstimatedGaussModel,xAx);
    %     hold on
    %     plot(xAx,B)
    %I added a regularization value of 0.01 to avoid the Ill-conditioned
    %covariance matrix error, this should fix it hopefully
    %EstimatedMixtureModel{1,rad_iter} = fitgmdist(A.',2,'RegularizationValue',0.01);
    EstimatedMixtureModel{1,rad_iter} = fitgmdist(A.',2);

    %     end
    
    %     Mu1_vs_R(1,rad_iter) = EstimatedMixtureModel{1,rad_iter}.mu(1,1);
    %     Mu2_vs_R(1,rad_iter) = EstimatedMixtureModel{1,rad_iter}.mu(2,1);
    
    
    %     Sig1_vs_R(1,rad_iter) = sqrt(EstimatedMixtureModel{1,rad_iter}.Sigma(1,1,1));
    %     Sig2_vs_R(1,rad_iter) = sqrt(EstimatedMixtureModel{1,rad_iter}.Sigma(1,1,2));
    
    %     Prop1_vs_R(1,rad_iter) = EstimatedMixtureModel{1,rad_iter}.ComponentProportion(1,1);
    %     Prop2_vs_R(1,rad_iter) = EstimatedMixtureModel{1,rad_iter}.ComponentProportion(1,2);
    
    
    %     pd1 = makedist('Normal','mu',EstimatedMixtureModel{1,rad_iter}.mu(1,1) ,'sigma',sqrt(EstimatedMixtureModel{1,rad_iter}.Sigma(1,1,1)));
    %     pd2 = makedist('Normal','mu',EstimatedMixtureModel{1,rad_iter}.mu(2,1) ,'sigma',sqrt(EstimatedMixtureModel{1,rad_iter}.Sigma(1,1,2)));
    
    %     cdf1 = EstimatedMixtureModel{1,rad_iter}.ComponentProportion(1,1) .* cdf(pd1,xAx);
    %     cdf2 = EstimatedMixtureModel{1,rad_iter}.ComponentProportion(1,2) .* cdf(pd2,xAx);
    %     plot(xAx,cdf1 + cdf2)
end
% plot(radius_vect,smooth(PB))

info = ['Fc_',num2str(ceil(Fc/1e9)),'_Hbs_',num2str(h_BS),'_HB_',num2str(BlockerHeightAvg),...
    '_WB_',num2str(BlockageAvgWidth),'_LB_',num2str(BlockageAvgLen),...
    '_LambdaB_',num2str(Lambda_Blocker_Per_m2)];


if isequal(WhatToDo,'Save')
    save(['Blockage_Data/',info,'.mat'],'PB','Total_Loss','ECDFs','xAx','EstimatedGaussModel','EstimatedMixtureModel','Mu_vs_R','Sig_vs_R','Fc','h_UE','h_BS','BlockageStat',...
        'Lambda_Blocker_Per_m2','Lambda_B_tot','MC_iters','UE_radius_vect','BSPos2D');
    Blockage = [];
elseif isequal(WhatToDo,'Return')
    %     Data.PB = PB;
    Data.ECDFs = ECDFs;
    Data.xAx = xAx;
    Data.Mu_vs_R = Mu_vs_R;
    %     Data.Fc = Fc;
    %     Data.h_UE = h_UE;
    %     Data.h_BS = h_BS;
    Blockage.UE_radius_vect = UE_radius_vect;
    %     Data.BlockageStat = BlockageStat;
    %         Data.EstimatedGaussModel = EstimatedGaussModel;
    Data.EstimatedMixtureModel = EstimatedMixtureModel;
    %     Data.Total_Loss = Total_Loss;
    %     Data.Lambda_Blocker_Per_m2 = Lambda_Blocker_Per_m2;
    Blockage.PB = PB;
    
    Blockage.Loss = Assign_Blockage_Loss(UE_radius_vect,Data);
    
end

