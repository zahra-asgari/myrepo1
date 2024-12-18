function [direct_snr,direct_rates,ris_snr,ris_rates,...
    af_snr,af_rates] = access_rates(prm,Scenario,iab_type,tx_type,iab_positions_3d,ue_positions_3d,ris_positions_3d,af_positions_3d)
%ACCESS_RATES Summary of this function goes here
%   Detailed explanation goes here

n_cs = size(iab_positions_3d,1);
n_tp = size(ue_positions_3d,1);

prm.RIS = Network_Entity('RIS',[0,0,0], prm.comm,'Orientation','Optimum');
prm.AF = Network_Entity('AF',[0,0,0], prm.comm,'Orientation','Optimum','Type','Option1');

switch iab_type
    case 'IAB'
        if tx_type=='DL' 
            prm.Tx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
            prm.Rx = Network_Entity('UE',[0,0,0], prm.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class3');
        elseif tx_type=='UL'
            prm.Rx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
            prm.Tx = Network_Entity('UE',[0,0,0], prm.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class3');
        end
    case 'Donor'
        if tx_type=='DL'
            prm.Tx = Network_Entity('BS',[0,0,0],prm.comm,'Type','Donor','Orientation','Optimum');
            prm.Rx = Network_Entity('UE',[0,0,0], prm.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class3');
        elseif tx_type=='UL'
            prm.Rx = Network_Entity('BS',[0,0,0],prm.comm,'Type','Donor','Orientation','Optimum');
            prm.Tx = Network_Entity('UE',[0,0,0], prm.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class3');
        end
    otherwise
        error('Unrecognized iab type');
end

direct_snr=zeros(n_tp,n_cs);
ris_snr=zeros(n_tp,n_cs,n_cs);
af_snr=zeros(n_tp,n_cs,n_cs);

for t=1:n_tp
    for c=1:n_cs
        for r=1:n_cs
            if c==r
                ris_snr(t,c,r)=0;
                af_snr(t,c,r)=0;
            else
                Pn_at_UE = -174 + 10*log10(prm.comm.BW) + prm.Rx.NF;     % noise power
                prm.RIS.Center=ris_positions_3d(r,:);
                prm.RIS.Orientation=ris_specular_orientation(prm.Tx.Center,prm.Rx.Center,prm.RIS.Center);
                prm.AF.Center=af_positions_3d(r,:);
                if tx_type=='DL'
                    prm.Tx.Center=iab_positions_3d(c,:);
                    prm.Rx.Center=ue_positions_3d(t,:);
                elseif tx_type=='UL'
                    prm.Rx.Center=iab_positions_3d(c,:);
                    prm.Tx.Center=ue_positions_3d(t,:);
                end
                
                [H_D,SNR]=Compute_Channel(prm,Scenario);
                direct_snr(t,c)=SNR.DL;
                ris_snr(t,c,r)=SNR.RIS;
                af_snr(t,c,r)=SNR.AF_max;
                direct_rates(t,c)=prm.comm.BW*log2(1+10^(0.1*SNR.DL))*1e-6;
                ris_rates(t,c,r)=prm.comm.BW*log2(1+10^(0.1*SNR.RIS))*1e-6;
                af_rates(t,c,r)=prm.comm.BW*log2(1+10^(0.1*SNR.AF_max))*1e-6;
            end
        end
    end
end
  



end

