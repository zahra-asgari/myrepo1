function BlockageLoss = Assign_Blockage_Loss(R,Data)
if length(Data.EstimatedMixtureModel)>1
    [~,ind]= min(abs(R - Data.UE_radius_vect));
    SEED = Data.EstimatedMixtureModel{1,ind};
else
    SEED = Data.EstimatedMixtureModel{1,1};
end
switch Data.LossCriteria
    case  'Mean'
        BlockageLoss = Data.Mu_vs_R(ind);
    case  'Median'
        xAx = linspace(0,70,500);
        This_CDF = cdf(SEED,xAx.');
        [C, ia, ~] = unique(This_CDF);
        BlockageLoss = interp1(C,xAx(ia),0.5);
%         BlockageLoss = interp1(This_CDF,xAx,0.5);
        
    case  'Percentile'
        xAx = linspace(0,70,500);
        This_CDF = cdf(SEED,xAx.');
        [C, ia, ~] = unique(This_CDF);
        BlockageLoss = interp1(C,xAx(ia),Data.Percentile/100,'linear','extrap');
        
    case  'Random'
        BlockageLoss = max(random(SEED),0);
end




end