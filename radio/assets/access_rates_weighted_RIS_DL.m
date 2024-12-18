function [state_direct_rates, state_ris_rates, avg_rate,ris_rate,state_probabilities,ris_better_mask] = access_rates_weighted_RIS_DL(scen,prm,Scenario,tx_type,iab_positions_3d,ue_positions_3d,ris_positions_3d,cache_found, cache_path)
%ACCESS_RATES Summary of this function goes here
if nargin ==7
    cache_found = false;
    save_to_cache = false;
elseif nargin <7
    error('Not enough input arguments');
else
    save_to_cache = true;
end

if cache_found
    load(cache_path, 'state_direct_rates', 'state_ris_rates');
else
    %   Detailed explanation goes here
    %added local variable to be edited when we have to calculate the channels
    %for the Donor CS (UMa)
    scenario_local = Scenario;

    n_cs = size(iab_positions_3d,1);
    n_tp = size(ue_positions_3d,1);
    avail_factor = scen.sim.rate_ratio;
    min_rate = scen.sim.R_dir_min;

    direct_snr=zeros(n_tp,n_cs);
    ris_snr=zeros(n_tp,n_cs,n_cs);
    %the next two matrices save every computed rate in which the added loss
    %given to obstacle blockage or self-blockage is included (16 different probability combinations)
    %0000 if no blockage whatsoever, 1111 if every possible blockage (both links in sbz and moving obstacles)
    state_probabilities = zeros(n_tp,n_cs,n_cs,16);
    direct_losses = zeros(n_tp,n_cs,16);
    reflected_losses = zeros(n_tp,n_cs,n_cs,16);
    state_direct_rates=  zeros(n_tp,n_cs,16);
    state_ris_rates = zeros(n_tp,n_cs,n_cs,16);
    avg_rate = zeros(n_tp,n_cs,n_cs);
    ris_rate = zeros(n_tp,n_cs,n_cs);
    %The next matrix is a binary mask that is equal to one if for that specific
    %(t,c,r) SRC the blockage state from 1 to 16 the reflected link has a
    %better capacity than the direct link, and 0 otherwise
    ris_better_mask = zeros(n_tp,n_cs,n_cs,16);
    %ris_airtime = zeros(n_tp,n_cs,n_cs);
    %direct_airtime = zeros(n_tp,n_cs,n_cs);
    %access_airtime = zeros(n_tp,n_cs,n_cs);

    prm.RIS = Network_Entity('RIS',[0,0,0], prm.comm,'Orientation','Optimum');

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
                        scenario_local.Tx2Rx = 'UMa';
                        direct_blockage = prm.Blockage.Donor.Handle(pdist2(iab_positions_3d(c,:),ue_positions_3d(t,:)),prm.Blockage.Donor);

                    elseif c == 1
                        %fake RIS position
                        continue;
                        %skip every calculation, fake RIS cannot be a BS
                    else
                        prm.Tx.Type='IAB';
                        prm.Tx.Center=iab_positions_3d(c,:);
                        scenario_local.Tx2Rx = 'UMi';
                        direct_blockage = prm.Blockage.IABNode.Handle(pdist2(iab_positions_3d(c,:),ue_positions_3d(t,:)),prm.Blockage.IABNode);

                    end
                    for r=1:n_cs

                        prm.RIS.Center=ris_positions_3d(r,:); %ris and AF positions and orientations
                        prm.RIS.Orientation=ris_specular_orientation(prm.Tx.Center,prm.Rx.Center,prm.RIS.Center);

                        if c==r %disable self links
                            ris_snr(t,c,r)=0;
                        else

    %This Compute_Channel computes even the AF channels, we don't need them, it
    %should be easier to decompone it and only use the channels we need
                            %[~,SNR]=Compute_Channel(prm,scenario_local);

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

                            [Distances,Angles,prm] = Define_Distances(prm);
                            Pn_at_UE = -174 + 10*log10(prm.comm.BW) + prm.Rx.NF;     % noise power

                            if prm.Config.Check_Static_Blockage
                                if ~prm.Blockage.pruning_dir(c,t)
                                    Static_Blockage_Dir.Event = true;
                                else
                                    Static_Blockage_Dir.Event = false;
                                end
                                if ~prm.Blockage.pruning_ref1(c,r) || ~prm.Blockage.pruning_ref2(r,t)
                                    Static_Blockage_RIS.Event = true;
                                else
                                    Static_Blockage_RIS.Event = false;
                                end

                                
                            elseif ~prm.Config.Check_Static_Blockage
                                Static_Blockage_Dir.Event = false;
                                Static_Blockage_RIS.Event = false;
                            end


                            %% DL Channel

                            if (~Static_Blockage_Dir.Event) 
                                [H_D,Dynamic_Blockage_Dir] = Compute_Direct_Channel(prm,Angles,Distances,Scenario);      % MIMO channel Matrix
                                Phi_Direct = 0;
                                %Blockage.Direct = Dynamic_Blockage_Dir;
                            elseif Static_Blockage_Dir.Event 
                                H_D = 0;
                                Phi_Direct = 0;
                                %Blockage.Direct = Static_Blockage_Dir;
                            else
                                error('Unknown Static Blockage Situation')
                            end

                            %% IRS Channel
                            
                                [prm,RIS_Serves] = Set_RIS(prm,Angles);
                                if (RIS_Serves) && (r~=n_cs) && (r~=1) && (~Static_Blockage_RIS.Event) 
                                    [H_RIS,Dynamic_Blockage_RIS] = Compute_RIS_Channel(Angles,Distances,prm,Phi_Direct);
                                    %Blockage.RIS = Dynamic_Blockage_RIS;
                                else
                                    H_RIS = 0;
                                end



                            %% Assign SNRs
                            Pow_dir = H_D^2;
                            [~,S_ris,~] = svd(H_RIS);
                            P_ris = trace(S_ris(1,1).^2);
                            SNR.DL = 10 .* log10(Pow_dir ./ db2pow(Pn_at_UE));
                            SNR.RIS = 10 .* log10(P_ris ./ db2pow(Pn_at_UE));


                            if r~=1
                                reflected_blockage = prm.Blockage.RIS.Handle(pdist2(ris_positions_3d(r,:),ue_positions_3d(t,:)),prm.Blockage.RIS);
                            else
                                reflected_blockage.PB = 0;
                                reflected_blockage.Loss = 0;
                            end
                            [state_probabilities(t,c,r,:), direct_losses(t,c,:), reflected_losses(t,c,r,:) ] = blockage_states_probs_losses(prm.Blockage.dsbz_prob,prm.Blockage.rsbz_probs(t,c,r),...
                                prm.Blockage.r_nsbz_probs(t,c,r),direct_blockage,reflected_blockage,prm.Blockage.fixed_sbz_loss);
                            direct_snr(t,c)=10^(0.1*SNR.DL);
                            ris_snr(t,c,r)=10^(0.1*SNR.RIS);
                            state_direct_rates(t,c,:)=prm.comm.BW*log2(1+direct_snr(t,c)/(10.^(0.1*direct_losses(t,c,:))))*1e-6;
                            state_ris_rates(t,c,r,:)=prm.comm.BW*log2(1+ris_snr(t,c,r)/(10.^(0.1*reflected_losses(t,c,r,:))))*1e-6;

%                             if r == 1
%                                 %fake RIS
%                                 ris_snr(t,c,r)=0;
%                                 state_ris_rates(t,c,r)=0;
%                             end
                            for s=1:16
                                if state_ris_rates(t,c,r,s) > state_direct_rates(t,c,s)

                                    ris_better_mask(t,c,r,s) = 1;

                                end
                                better_rate = (1 - ris_better_mask(t,c,r,s))*state_direct_rates(t,c,s) + ris_better_mask(t,c,r,s)*state_ris_rates(t,c,r,s);
%                                 if (r~=1) && (r~=n_cs) && (state_ris_rates(t,c,r,s) > 0)
%                                     ris_airtime(t,c,r) = ris_airtime(t,c,r) + (avail_factor*min_rate*ris_better_mask(t,c,r,s)*state_probabilities(t,c,r,s))...
%                                         /(state_ris_rates(t,c,r,s));
%                                 end
%                                 if (r~=n_cs) && (state_direct_rates(t,c,s)>0)
%                                     direct_airtime(t,c,r) = direct_airtime(t,c,r) + (min_rate*(1 - ris_better_mask(t,c,r,s))*state_probabilities(t,c,r,s))...
%                                         /(state_direct_rates(t,c,s));
%                                 end

%I modified the calculation of the airtime by removing the minimum demand
%of 100 mbps since now we calculate it as a variable in the model. I edited
%the constraint of the capacity to be greater than the minimum rate
%100mbps, so that it doesn't skew the average airtime occupation, since it
%wouldn't even work in that case (it would occupy even the slots for the other access and backhaul links)

                                if (r~=1) && (r~=n_cs) && (state_ris_rates(t,c,r,s) >= avail_factor*min_rate)
                                %    ris_airtime(t,c,r) = ris_airtime(t,c,r) + (avail_factor*ris_better_mask(t,c,r,s)*state_probabilities(t,c,r,s))...
                                 %       /(state_ris_rates(t,c,r,s));
                                    ris_rate(t,c,r) = ris_rate(t,c,r) + ris_better_mask(t,c,r,s)*state_probabilities(t,c,r,s)*state_ris_rates(t,c,r,s);
                                end
                               % if (r~=n_cs) && (state_direct_rates(t,c,s)>=min_rate)
                                %    direct_airtime(t,c,r) = direct_airtime(t,c,r) + (1 - ris_better_mask(t,c,r,s))*state_probabilities(t,c,r,s)...
                                 %       /(state_direct_rates(t,c,s));
                               % end
                                if better_rate >= min_rate
                                    avg_rate(t,c,r) = avg_rate(t,c,r) + state_probabilities(t,c,r,s)*better_rate;
                                end
                            end

                        end
                    end    
                end 
            end
       %     access_airtime = direct_airtime + ris_airtime;


        %uplink case not updated as downlink  
        case 'UL'
            prm.Rx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
            prm.Tx = Network_Entity('UE',[0,0,0], prm.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class3');
            for t=1:n_tp
                prm.Tx.Center=ue_positions_3d(t,:);
                for c=1:n_cs
                    if c == n_cs
                        prm.Rx.Type='Donor';
                        prm.Rx.Center=iab_positions_3d(c,:);
                        scenario_local.Tx2Rx = 'UMa';

                    elseif c == 1
                        %fake RIS position
                        continue;
                        %skip every calculation, fake RIS cannot be a BS 

                    else
                        prm.Rx.Type='IAB';
                        prm.Rx.Center=iab_positions_3d(c,:);
                        scenario_local.Tx2Rx = 'UMi';
                    end
                    for r=1:n_cs

                        prm.RIS.Center=ris_positions_3d(r,:); %ris and AF positions and orientations
                        prm.RIS.Orientation=ris_specular_orientation(prm.Tx.Center,prm.Rx.Center,prm.RIS.Center);

                        if c==r %disable self links
                            ris_snr(t,c,r)=0;
                        else

                            Pn_at_UE = -174 + 10*log10(prm.comm.BW) + prm.Rx.NF;     % noise power
                            [~,SNR]=Compute_Channel(prm, scenario_local);
                            direct_snr(t,c)=SNR.DL;
                            ris_snr(t,c,r)=SNR.RIS;
                            for state=1:16



                            end

                            state_direct_rates(t,c)=prm.comm.BW*log2(1+10^(0.1*SNR.DL))*1e-6;
                            state_ris_rates(t,c,r)=prm.comm.BW*log2(1+10^(0.1*SNR.RIS))*1e-6;

                            if r == 1 
                                %fake RIS
                                ris_snr(t,c,r)=0;
                                state_ris_rates(t,c,r)=0;
                            end

                        end
                    end    
                end 
            end

        otherwise
            error('Unrecognized tx type');
    end
    
    if save_to_cache
        save(cache_path, 'state_direct_rates', 'state_ris_rates', '-append');
    end



end
end

