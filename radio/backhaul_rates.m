function [backhaul_rates,backhaul_snr] = backhaul_rates(prm,Scenario,linktype,iab_positions_3d)
%BACKHAUL_RATES Summary of this function goes here
%   Detailed explanation goes here

n_cs = size(iab_positions_3d,1);

switch linktype
    case 'IAB'
        prm.Tx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
        prm.Rx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
        prm.RIS = Network_Entity('RIS',[0,0,0], prm.comm,'Orientation','Optimum');
        prm.AF = Network_Entity('AF',[0,0,0], prm.comm,'Orientation','Optimum','Type','Option1');
    case 'donor_tx'
        prm.Tx = Network_Entity('BS',[0,0,0],prm.comm,'Type','Donor','Orientation','Optimum');
        prm.Rx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
        prm.RIS = Network_Entity('RIS',[0,0,0], prm.comm,'Orientation','Optimum');
        prm.AF = Network_Entity('AF',[0,0,0], prm.comm,'Orientation','Optimum','Type','Option1');
    case 'donor_rx'
        prm.Tx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
        prm.Rx = Network_Entity('BS',[0,0,0],prm.comm,'Type','Donor','Orientation','Optimum');
        prm.RIS = Network_Entity('RIS',[0,0,0], prm.comm,'Orientation','Optimum');
        prm.AF = Network_Entity('AF',[0,0,0], prm.comm,'Orientation','Optimum','Type','Option1');
    otherwise
        error('Unrecognized link type');
end

backhaul_snr=zeros(n_cs,n_cs);
backhaul_rates=zeros(n_cs,n_cs);
for t=1:n_cs
    for c=1:n_cs
        if c==t
            backhaul_snr(t,c)=0;
            backhaul_rates(t,c)=0;
        else
            prm.Tx.Center=iab_positions_3d(t,:);
            prm.Rx.Center=iab_positions_3d(c,:);
            Pn_at_UE = -174 + 10*log10(prm.comm.BW) + prm.Rx.NF;     % noise power
            [Distances,Angles,prm] = Define_Distances(prm); %NEW ADDITION!!!!!1
            H_D = Compute_Direct_Channel(prm,Angles,Distances,Scenario); %MODIFICATIONS!!1
            P_dir = H_D^2;
            snr_temp = 10 .* log10(P_dir ./ db2pow(Pn_at_UE));
            backhaul_snr(t,c)=snr_temp;
            backhaul_rates(t,c)=prm.comm.BW*log2(1+10^(0.1*snr_temp));
        end
    end
end

backhaul_rates=backhaul_rates.*1e-6;

end
            
            
            
            