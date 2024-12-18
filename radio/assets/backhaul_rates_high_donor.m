function [backhaul_rates] = backhaul_rates_high_donor(scenario,prm,Scenario,iab_positions_3d)
%BACKHAUL_RATES Summary of this function goes here
%   Detailed explanation goes here

n_cs = size(iab_positions_3d,1);
scenario_local = Scenario;


prm.Tx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
prm.Rx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
prm.RIS = Network_Entity('RIS',[0,0,0], prm.comm,'Orientation','Optimum'); %irrelevant in backhaul, it's here because define_distances needs also a relay


backhaul_snr=zeros(n_cs,n_cs);
backhaul_rates=zeros(n_cs,n_cs);

for c=1:n_cs
    if (c==1) 
    %if fake ris is transmitting, skip iteration
            continue;
    end
    for d=1:n_cs
        %if self-link, donor receiving or fak ris receiving, skip iteration
        if (d==c)||(d==n_cs)||(d==1) 
            continue;
        end
        if c==n_cs
            % this is the donor transmitting
            prm.Tx.Type='Donor';
            scenario_local.Tx2Rx = 'UMa';
        else % none is the donor
            prm.Tx.Type='IAB';
            scenario_local.Tx2Rx = 'UMi';
        end
        prm.Tx.Center=iab_positions_3d(c,:);
        prm.Rx.Center=iab_positions_3d(d,:);
        Pn_at_UE = -174 + 10*log10(prm.comm.BW) + prm.Rx.NF;     % noise power
        
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
      
        
        [Distances,Angles,prm] = Define_Distances(prm); %NEW ADDITION!!!!!1
        
        if prm.Config.Check_Static_Blockage
            if ~prm.Blockage.pruning_bh(c,d)
                Static_Blockage_Dir.Event = true;
            else
                Static_Blockage_Dir.Event = false;
            end
            
            
        elseif ~prm.Config.Check_Static_Blockage
            Static_Blockage_Dir.Event = false;
        end
        
        
        
        if (~Static_Blockage_Dir.Event)
            [H_D,~] = Compute_Direct_Channel(prm,Angles,Distances,scenario_local); %MODIFICATIONS!!1
        elseif Static_Blockage_Dir.Event
            H_D = 0;
        else
            error('Unknown Static Blockage Situation')
        end



        P_dir = H_D^2;
        snr_temp = 10 .* log10(P_dir ./ db2pow(Pn_at_UE));
        backhaul_snr(c,d)=snr_temp;
        backhaul_rates(c,d)=prm.comm.BW*log2(1+10^(0.1*snr_temp));
    end
end

backhaul_rates=backhaul_rates.*1e-6;

end
            
            
            
            
