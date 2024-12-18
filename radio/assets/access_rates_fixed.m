function [direct_snr,direct_rates,ris_snr,ris_rates,...
    af_snr,af_rates] = access_rates_fixed(prm,Scenario,tx_type,iab_positions_3d,ue_positions_3d,ris_positions_3d,af_positions_3d)
%ACCESS_RATES Summary of this function goes here
%   Detailed explanation goes here

n_cs = size(iab_positions_3d,1);
n_tp = size(ue_positions_3d,1);

direct_snr=zeros(n_tp,n_cs);
ris_snr=zeros(n_tp,n_cs,n_cs);
af_snr=zeros(n_tp,n_cs,n_cs);

prm.RIS = Network_Entity('RIS',[0,0,0], prm.comm,'Orientation','Optimum');
prm.AF = Network_Entity('AF',[0,0,0], prm.comm,'Orientation','Optimum','Type','Option1');


switch tx_type
    case 'DL'
        prm.Tx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
        prm.Rx = Network_Entity('UE',[0,0,0], prm.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class3');
        
        for t=1:n_tp
            prm.Rx.Center=ue_positions_3d(t,:);
            for c=1:n_cs
                if c == n_cs
                    prm.Tx.Type='Donor';
                    prm.Tx.Center=iab_positions_3d(c,:);
                else
                    prm.Tx.Type='IAB';
                    prm.Tx.Center=iab_positions_3d(c,:);
                end
                for r=1:n_cs
            
                    prm.RIS.Center=ris_positions_3d(r,:); %ris and AF positions and orientations
                    prm.RIS.Orientation=ris_specular_orientation(prm.Tx.Center,prm.Rx.Center,prm.RIS.Center);
                    prm.AF.Center=af_positions_3d(r,:);

                    if c==r %disable self links
                        ris_snr(t,c,r)=0;
                        af_snr(t,c,r)=0;
                    else

                    Pn_at_UE = -174 + 10*log10(prm.comm.BW) + prm.Rx.NF;     % noise power
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

    case 'UL'
        prm.Rx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
        prm.Tx = Network_Entity('UE',[0,0,0], prm.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class3');
        for t=1:n_tp
            prm.Tx.Center=ue_positions_3d(t,:);
            for c=1:n_cs
                if c == n_cs
                    prm.Rx.Type='Donor';
                    prm.Rx.Center=iab_positions_3d(c,:);
                else
                    prm.Rx.Type='IAB';
                    prm.Rx.Center=iab_positions_3d(c,:);
                end
                for r=1:n_cs
            
                    prm.RIS.Center=ris_positions_3d(r,:); %ris and AF positions and orientations
                    prm.RIS.Orientation=ris_specular_orientation(prm.Tx.Center,prm.Rx.Center,prm.RIS.Center);
                    prm.AF.Center=af_positions_3d(r,:);

                    if c==r %disable self links
                        ris_snr(t,c,r)=0;
                        af_snr(t,c,r)=0;
                    else

                    Pn_at_UE = -174 + 10*log10(prm.comm.BW) + prm.Rx.NF;     % noise power
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

    otherwise
        error('Unrecognized tx type');
end



end

