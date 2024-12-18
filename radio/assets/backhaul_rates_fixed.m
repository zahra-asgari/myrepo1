function [backhaul_rates,backhaul_snr] = backhaul_rates_fixed(prm,Scenario,iab_positions_3d)
%BACKHAUL_RATES Summary of this function goes here
%   Detailed explanation goes here

n_cs = size(iab_positions_3d,1);

prm.Tx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
prm.Rx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
prm.RIS = Network_Entity('RIS',[0,0,0], prm.comm,'Orientation','Optimum'); %fictitious
prm.AF = Network_Entity('AF',[0,0,0], prm.comm,'Orientation','Optimum','Type','Option1');

backhaul_snr=zeros(n_cs,n_cs);
backhaul_rates=zeros(n_cs,n_cs);

for c=1:n_cs
    for d=1:n_cs
        if d==c
            continue;
        end
        if c==n_cs
            % this is the donor transmitting
            prm.Tx.Type='Donor';
            prm.Rx.Type='IAB';        
        elseif d==n_cs
            % this is the donor receiving
            prm.Rx.Type='Donor';
            prm.Tx.Type='IAB';
        else % none is the donor
            prm.Tx.Type='IAB';
            prm.Rx.Type='IAB';
        end
        prm.Tx.Center=iab_positions_3d(c,:);
        prm.Rx.Center=iab_positions_3d(d,:);
        
        if ~isprop(prm.Rx,'Role')
            prm.Rx.addprop('Role');
            prm.Rx.Role = 'Rx';
        end

        if ~isprop(prm.Tx,'Role')
            prm.Tx.addprop('Role');
            prm.Tx.Role = 'Tx';
        end
                        
        if ~isprop(prm.RIS,'Role')
            prm.RIS.addprop('Role');
            prm.RIS.Role = 'Relay';
        end
        
        Pn_at_UE = -174 + 10*log10(prm.comm.BW) + prm.Rx.NF;     % noise power
        [Distances,Angles,prm] = Define_Distances(prm,[]); %NEW ADDITION!!!!!1
        H_D = Compute_Direct_Channel(prm,Angles,Distances,Scenario); %MODIFICATIONS!!1
        P_dir = H_D^2;
        snr_temp = 10 .* log10(P_dir ./ db2pow(Pn_at_UE));
        backhaul_snr(c,d)=snr_temp;
        backhaul_rates(c,d)=prm.comm.BW*log2(1+10^(0.1*snr_temp));
    end
end

backhaul_rates=backhaul_rates.*1e-6;

end
            
            
            
            