function [rates_per_state,avg_rates,sd_rates,state_probabilities,sd_better_mask,access_snr] = access_rates_weighted_complete(sim_scenario,prm,radio_scenario,tx_type,geometry,cache_found, cache_path)
%ACCESS_RATES Summary of this function goes here
if nargin ==5
    cache_found = false;
    save_to_cache = false;
elseif nargin <5
    error('Not enough input arguments');
else
    save_to_cache = true;
end

if cache_found
    load(cache_path, 'state_direct_rates', 'state_ris_rates','state_ncr_rates');
else
    %   Detailed explanation goes here
    %added local variable to be edited when we have to calculate the channels
    %for the Donor CS (UMa)
    radio_scenario_local = radio_scenario;

    n_cs = size(geometry.iab_positions_3d,1);
    n_tp = size(geometry.ue_positions_3d,1);
    avail_factor = sim_scenario.sim.rate_ratio;

    direct_snr=zeros(n_tp,n_cs,16);
    ris_snr=zeros(n_tp,n_cs,n_cs,16);
    ncr_snr=zeros(n_tp,n_cs,n_cs,16);
    %the next two matrices save every computed rate in which the added loss
    %given to obstacle blockage or self-blockage is included (16 different probability combinations)
    %0000 if no blockage whatsoever, 1111 if every possible blockage (both links in sbz and moving obstacles)
    state_probabilities = zeros(n_tp,n_cs,n_cs,16);
    direct_losses = zeros(n_tp,n_cs,16);
    reflected_losses = zeros(n_tp,n_cs,n_cs,16);
    state_direct_rates =  zeros(n_tp,n_cs,16);
    state_ris_rates = zeros(n_tp,n_cs,n_cs,16);
    state_ncr_rates = zeros(n_tp,n_cs,n_cs,16);
    ris_avg_rate = zeros(n_tp,n_cs,n_cs);
    ncr_avg_rate = zeros(n_tp,n_cs,n_cs);
    ris_rates = zeros(n_tp,n_cs,n_cs); %weighted capacity of only the states in which the SD is used
    ncr_rates = zeros(n_tp,n_cs,n_cs);
    %The next matrix is a binary mask that is equal to one if for that specific
    %(t,c,r) SRC the blockage state from 1 to 16 the reflected link has a
    %better capacity than the direct link, and 0 otherwise
    ris_better_mask = zeros(n_tp,n_cs,n_cs,16);
    ncr_better_mask = zeros(n_tp,n_cs,n_cs,16);
    %ris_airtime = zeros(n_tp,n_cs,n_cs);
    %direct_airtime = zeros(n_tp,n_cs,n_cs);
    %access_airtime = zeros(n_tp,n_cs,n_cs);

    prm.RIS = Network_Entity('RIS',[0,0,0], prm.comm,'Orientation','Optimum');
    prm.AF = Network_Entity('AF',[0,0,0], prm.comm,'Orientation','Optimum','Type','Option1');
    prm.AF.EIRP_max = 50; % it was 55 but it is the absolut maximum, this is more like an average value
    switch tx_type
        case 'DL'
            min_rate = sim_scenario.sim.alpha*sim_scenario.sim.R_dir_min;
            prm.Rx = Network_Entity('UE',[0,0,0], prm.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class3');

            for t=1:n_tp
                prm.Rx.Center=geometry.ue_positions_3d(t,:);
                for c=1:n_cs
                    if c == n_cs
                        prm.Tx = Network_Entity('BS',[0,0,0],prm.comm,'Type','Donor','Orientation','Optimum');
                        prm.Tx.Center=geometry.iab_positions_3d(c,:);
                        radio_scenario_local.Tx2Rx = 'UMa';
                        direct_blockage = prm.Blockage.Donor.Handle(pdist2(geometry.iab_positions_3d(c,:),geometry.ue_positions_3d(t,:)),prm.Blockage.Donor);

                    elseif c == 1
                        %fake RIS position
                        continue;
                        %skip every calculation, fake RIS cannot be a BS
                    else
                        prm.Tx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
                        prm.Tx.Center=geometry.iab_positions_3d(c,:);
                        radio_scenario_local.Tx2Rx = 'UMi';
                        direct_blockage = prm.Blockage.IABNode.Handle(pdist2(geometry.iab_positions_3d(c,:),geometry.ue_positions_3d(t,:)),prm.Blockage.IABNode);
                    end
                    for r=1:n_cs

                        prm.RIS.Center=geometry.ris_positions_3d(r,:); %ris and AF positions and orientations
                        prm.RIS.Orientation=ris_specular_orientation(prm.Tx.Center,prm.Rx.Center,prm.RIS.Center);
                        prm.AF.Center=geometry.ncr_positions_3d(r,:);

                        if c==r %disable self links
                            ris_snr(t,c,r,:)=0;
                            ncr_snr(t,c,r,:)=0;
                        else

    %Earlier I extracted parts of the Compute_Channel function because it
    %calculated also NCR channel, but now it's ok, I have to use it again
    %to simplify. (future expansion: how to feed it different kinds of RISs
    %and NCRs? Maybe it's better to keep it separated and treat them as
    %different devices outside of Compute_Channel anyway

                            if ~isprop(prm.Rx,'Role')
                                prm.Rx.addprop('Role');
                                prm.Rx.Role = 'Rx';
                            end
                            if ~isprop(prm.Tx,'Role')
                                prm.Tx.addprop('Role');
                                prm.Tx.Role = 'Tx';
                            end
                            %Since RIS and NCR are colocated, you can call
                            %the Define_Distances once with prm.RIS, if they weren't we
                            %would have to call them for every SD
                            [Distances,Angles,prm] = Define_Distances(prm,prm.RIS);
                            Pn_at_UE = -174 + 10*log10(prm.comm.BW) + prm.Rx.NF;     % noise power

                            if prm.Config.Check_Static_Blockage
                                if ~prm.Blockage.pruning_dir(c,t)
                                    Static_Blockage_Dir.Event = true;
                                else
                                    Static_Blockage_Dir.Event = false;
                                end
                                if ~prm.Blockage.pruning_ref1(c,r) || ~prm.Blockage.pruning_ref2(r,t)
                                    Static_Blockage_Relay.Event = true;
                                else
                                    Static_Blockage_Relay.Event = false;
                                end

                                
                            elseif ~prm.Config.Check_Static_Blockage
                                Static_Blockage_Dir.Event = false;
                                Static_Blockage_Relay.Event = false;
                            end


                            %% DL Channel

                            if (~Static_Blockage_Dir.Event) 
                                [H_D,Dynamic_Blockage_Dir] = Compute_Direct_Channel(prm,Angles,Distances,radio_scenario_local);      % MIMO channel Matrix
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
                            if (RIS_Serves) && (r~=n_cs) && (r~=1) && (~Static_Blockage_Relay.Event)
                                % [H_RIS,Dynamic_Blockage_RIS] = Compute_RIS_Channel(Angles,Distances,prm,Phi_Direct);
                                [H_RIS,~] = Compute_RIS_Channel(prm,prm.RIS,Phi_Direct);
                                %Blockage.RIS = Dynamic_Blockage_RIS;
                            else
                                H_RIS = 0;
                            end

                            %% NCR Channel
                            Panel2Tilt = 0;
                            Panel2Rot = 0;
                            epsilon = 1e-10;
                            if (r~=n_cs) && (r~=1) && (~Static_Blockage_Relay.Event)
                                % % % [H_AF, NoisePower_AF, ~, ~] = AF_Channel(prm ,'UMa', 'UMi', 'Option1',Panel2Rot,Panel2Tilt);
                                [H_AF_max, NoisePower_AF_max,H_AF_min, NoisePower_AF_min,Dynamic_Blockage_AF] = Compute_AF_Channel(prm,Angles, Distances ,'UMa', 'UMi', 'Option1',Panel2Rot,Panel2Tilt);
                                %Blockage.AF = Dynamic_Blockage_AF;
                            else
                                H_AF_max = 0;
                                NoisePower_AF_max = epsilon;
                                H_AF_min = 0;
                                NoisePower_AF_min = epsilon;
                            end

                            %% Assign SNRs
                            Pow_dir = H_D^2;
                            Pow_AF_min = H_AF_min^2;
                            Pow_AF_max = H_AF_max^2;
                            [~,S_ris,~] = svd(H_RIS);
                            P_ris = trace(S_ris(1,1).^2);
                            SNR.DL = 10 .* log10(Pow_dir ./ db2pow(Pn_at_UE));
                            SNR.RIS = 10 .* log10(P_ris ./ db2pow(Pn_at_UE));
                            SNR.AF_min = 10 .* log10(Pow_AF_min ./ NoisePower_AF_min);
                            SNR.AF_max = 10 .* log10(Pow_AF_max ./ NoisePower_AF_max);


                            if r~=1
                                reflected_blockage = prm.Blockage.RIS.Handle(pdist2(geometry.ris_positions_3d(r,:),geometry.ue_positions_3d(t,:)),prm.Blockage.RIS);
                            else
                                reflected_blockage.PB = 0;
                                reflected_blockage.Loss = 0;
                            end
                            [state_probabilities(t,c,r,:), direct_losses(t,c,:), reflected_losses(t,c,r,:) ] = blockage_states_probs_losses(prm.Blockage.dsbz_prob,prm.Blockage.rsbz_probs(t,c,r),...
                                prm.Blockage.r_nsbz_probs(t,c,r),direct_blockage,reflected_blockage,prm.Blockage.fixed_sbz_loss);
                            direct_snr(t,c,:)=SNR.DL - squeeze(direct_losses(t,c,:));
                            ris_snr(t,c,r,:)=SNR.RIS - squeeze(reflected_losses(t,c,r,:));
                            ncr_snr(t,c,r,:)=SNR.AF_max - squeeze(reflected_losses(t,c,r,:));

                            switch prm.rate_calc
                                case 'shannon'
                                    state_direct_rates(t,c,:)=prm.comm.BW*log2(1+10.^(0.1*direct_snr(t,c,:)))*1e-6;
                                    state_ris_rates(t,c,r,:)=prm.comm.BW*log2(1+10.^(0.1*ris_snr(t,c,r,:)))*1e-6;
                                    state_ncr_rates(t,c,r,:)=prm.comm.BW*log2(1+10.^(0.1*ncr_snr(t,c,r,:)))*1e-6;
                                case '3GPP'
                                    state_direct_rates(t,c,:)=table_rate_calc(prm.comm.BW,direct_snr(t,c,:));
                                    state_ris_rates(t,c,r,:)=table_rate_calc(prm.comm.BW,ris_snr(t,c,r,:));
                                    state_ncr_rates(t,c,r,:)=table_rate_calc(prm.comm.BW,ncr_snr(t,c,r,:));
                            end

                            for s=1:16
                                if state_ris_rates(t,c,r,s) > state_direct_rates(t,c,s)

                                    ris_better_mask(t,c,r,s) = 1;

                                end
                                if state_ncr_rates(t,c,r,s) > state_direct_rates(t,c,s)

                                    ncr_better_mask(t,c,r,s) = 1;

                                end
                                ris_better_rate = (1 - ris_better_mask(t,c,r,s))*state_direct_rates(t,c,s) + ris_better_mask(t,c,r,s)*state_ris_rates(t,c,r,s);
                                ncr_better_rate = (1 - ncr_better_mask(t,c,r,s))*state_direct_rates(t,c,s) + ncr_better_mask(t,c,r,s)*state_ncr_rates(t,c,r,s);

                                ris_avg_rate(t,c,r) = ris_avg_rate(t,c,r) + state_probabilities(t,c,r,s)*ris_better_rate;
                                ncr_avg_rate(t,c,r) = ncr_avg_rate(t,c,r) + state_probabilities(t,c,r,s)*ncr_better_rate;

                            end
                            ris_time_fraction = sum(ris_better_mask(t,c,r,:).*state_probabilities(t,c,r,:));
                            ncr_time_fraction = sum(ncr_better_mask(t,c,r,:).*state_probabilities(t,c,r,:));
                            if ris_time_fraction > 0
                                ris_rates(t,c,r) = sum(ris_better_mask(t,c,r,:).*state_probabilities(t,c,r,:).*state_ris_rates(t,c,r,:))/ris_time_fraction; %weighted rate considering only the states in which the SD is actually used
                                ris_rates(t,c,r) = ris_rates(t,c,r)/ris_time_fraction; %divide again by the time fraction to obtain the relative bitrate compared to the total frame

                            end
                            if ncr_time_fraction > 0
                                ncr_rates(t,c,r) = sum(ncr_better_mask(t,c,r,:).*state_probabilities(t,c,r,:).*state_ncr_rates(t,c,r,:))/ncr_time_fraction;
                                ncr_rates(t,c,r) = ncr_rates(t,c,r)/ncr_time_fraction;
                            end

                        end
                    end    
                end 
            end
            avg_rates.ris = ris_avg_rate;
            avg_rates.ncr = ncr_avg_rate;
            ris_rates(~isfinite(ris_rates)) = 0;
            ncr_rates(~isfinite(ncr_rates)) = 0;
            sd_rates.ris = ris_rates;
            sd_rates.ncr = ncr_rates;
            sd_better_mask.ris = ris_better_mask;
            sd_better_mask.ncr = ncr_better_mask;
            rates_per_state.dir = state_direct_rates;
            rates_per_state.ris = state_ris_rates;
            rates_per_state.ncr = state_ncr_rates;
            access_snr.dir = direct_snr;
            access_snr.ris = ris_snr;
            access_snr.ncr = ncr_snr;

        case 'UL'
            min_rate = (1-sim_scenario.sim.alpha)*sim_scenario.sim.R_dir_min;
            prm.Tx = Network_Entity('UE',[0,0,0], prm.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class3');

            for t=1:n_tp
                prm.Tx.Center=geometry.ue_positions_3d(t,:);
                for c=1:n_cs
                    if c == n_cs
                        prm.Rx = Network_Entity('BS',[0,0,0],prm.comm,'Type','Donor','Orientation','Optimum');
                        prm.Rx.Center=geometry.iab_positions_3d(c,:);
                        radio_scenario_local.Tx2Rx = 'UMa';
                        direct_blockage = prm.Blockage.Donor.Handle(pdist2(geometry.iab_positions_3d(c,:),geometry.ue_positions_3d(t,:)),prm.Blockage.Donor);

                    elseif c == 1
                        %fake RIS position
                        continue;
                        %skip every calculation, fake RIS cannot be a BS
                    else
                        prm.Rx = Network_Entity('BS',[0,0,0],prm.comm,'Type','IAB','Orientation','Optimum');
                        prm.Rx.Center=geometry.iab_positions_3d(c,:);
                        radio_scenario_local.Tx2Rx = 'UMi';
                        direct_blockage = prm.Blockage.IABNode.Handle(pdist2(geometry.iab_positions_3d(c,:),geometry.ue_positions_3d(t,:)),prm.Blockage.IABNode);
                    end
                    for r=1:n_cs

                        prm.RIS.Center=geometry.ris_positions_3d(r,:); %ris and AF positions and orientations
                        prm.RIS.Orientation=ris_specular_orientation(prm.Tx.Center,prm.Rx.Center,prm.RIS.Center);
                        prm.AF.Center=geometry.ncr_positions_3d(r,:);

                        if c==r %disable self links
                            ris_snr(t,c,r,:)=0;
                            ncr_snr(t,c,r,:)=0;
                        else

    %Earlier I extracted parts of the Compute_Channel function because it
    %calculated also NCR channel, but now it's ok, I have to use it again
    %to simplify. (future expansion: how to feed it different kinds of RISs
    %and NCRs? Maybe it's better to keep it separated and treat them as
    %different devices outside of Compute_Channel anyway

                            if ~isprop(prm.Rx,'Role')
                                prm.Rx.addprop('Role');
                                prm.Rx.Role = 'Rx';
                            end
                            if ~isprop(prm.Tx,'Role')
                                prm.Tx.addprop('Role');
                                prm.Tx.Role = 'Tx';
                            end
                            %Since RIS and NCR are colocated, you can call
                            %the Define_Distances once with prm.RIS, if they weren't we
                            %would have to call them for every SD
                            [Distances,Angles,prm] = Define_Distances(prm,prm.RIS);
                            Pn_at_UE = -174 + 10*log10(prm.comm.BW) + prm.Rx.NF;     % noise power

                            if prm.Config.Check_Static_Blockage
                                if ~prm.Blockage.pruning_dir(c,t)
                                    Static_Blockage_Dir.Event = true;
                                else
                                    Static_Blockage_Dir.Event = false;
                                end
                                if ~prm.Blockage.pruning_ref1(c,r) || ~prm.Blockage.pruning_ref2(r,t)
                                    Static_Blockage_Relay.Event = true;
                                else
                                    Static_Blockage_Relay.Event = false;
                                end

                                
                            elseif ~prm.Config.Check_Static_Blockage
                                Static_Blockage_Dir.Event = false;
                                Static_Blockage_Relay.Event = false;
                            end


                            %% UL Channel

                            if (~Static_Blockage_Dir.Event) 
                                [H_D,Dynamic_Blockage_Dir] = Compute_Direct_Channel(prm,Angles,Distances,radio_scenario_local);      % MIMO channel Matrix
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
                            if (RIS_Serves) && (r~=n_cs) && (r~=1) && (~Static_Blockage_Relay.Event)
                                % [H_RIS,Dynamic_Blockage_RIS] = Compute_RIS_Channel(Angles,Distances,prm,Phi_Direct);
                                [H_RIS,~] = Compute_RIS_Channel(prm,prm.RIS,Phi_Direct);
                                %Blockage.RIS = Dynamic_Blockage_RIS;
                            else
                                H_RIS = 0;
                            end

                            %% NCR Channel
                            Panel2Tilt = 0;
                            Panel2Rot = 0;
                            epsilon = 1e-10;
                            if (r~=n_cs) && (r~=1) && (~Static_Blockage_Relay.Event)
                                % % % [H_AF, NoisePower_AF, ~, ~] = AF_Channel(prm ,'UMa', 'UMi', 'Option1',Panel2Rot,Panel2Tilt);
                                [H_AF_max, NoisePower_AF_max,H_AF_min, NoisePower_AF_min,Dynamic_Blockage_AF] = Compute_AF_Channel(prm,Angles, Distances ,'UMa', 'UMi', 'Option1',Panel2Rot,Panel2Tilt);
                                %Blockage.AF = Dynamic_Blockage_AF;
                            else
                                H_AF_max = 0;
                                NoisePower_AF_max = epsilon;
                                H_AF_min = 0;
                                NoisePower_AF_min = epsilon;
                            end

                            %% Assign SNRs
                            Pow_dir = H_D^2;
                            Pow_AF_min = H_AF_min^2;
                            Pow_AF_max = H_AF_max^2;
                            [~,S_ris,~] = svd(H_RIS);
                            P_ris = trace(S_ris(1,1).^2);
                            SNR.DL = 10 .* log10(Pow_dir ./ db2pow(Pn_at_UE));
                            SNR.RIS = 10 .* log10(P_ris ./ db2pow(Pn_at_UE));
                            SNR.AF_min = 10 .* log10(Pow_AF_min ./ NoisePower_AF_min);
                            SNR.AF_max = 10 .* log10(Pow_AF_max ./ NoisePower_AF_max);


                            if r~=1
                                reflected_blockage = prm.Blockage.RIS.Handle(pdist2(geometry.ris_positions_3d(r,:),geometry.ue_positions_3d(t,:)),prm.Blockage.RIS);
                            else
                                reflected_blockage.PB = 0;
                                reflected_blockage.Loss = 0;
                            end
                            [state_probabilities(t,c,r,:), direct_losses(t,c,:), reflected_losses(t,c,r,:) ] = blockage_states_probs_losses(prm.Blockage.dsbz_prob,prm.Blockage.rsbz_probs(t,c,r),...
                                prm.Blockage.r_nsbz_probs(t,c,r),direct_blockage,reflected_blockage,prm.Blockage.fixed_sbz_loss);

                            direct_snr(t,c,:)=SNR.DL - squeeze(direct_losses(t,c,:));
                            ris_snr(t,c,r,:)=SNR.RIS - squeeze(reflected_losses(t,c,r,:));
                            ncr_snr(t,c,r,:)=SNR.AF_max - squeeze(reflected_losses(t,c,r,:));

                            switch prm.rate_calc
                                case 'shannon'
                                    state_direct_rates(t,c,:)=prm.comm.BW*log2(1+10.^(0.1*direct_snr(t,c,:)))*1e-6;
                                    state_ris_rates(t,c,r,:)=prm.comm.BW*log2(1+10.^(0.1*ris_snr(t,c,r,:)))*1e-6;
                                    state_ncr_rates(t,c,r,:)=prm.comm.BW*log2(1+10.^(0.1*ncr_snr(t,c,r,:)))*1e-6;
                                case '3GPP'
                                    state_direct_rates(t,c,:)=table_rate_calc(prm.comm.BW,direct_snr(t,c,:));
                                    state_ris_rates(t,c,r,:)=table_rate_calc(prm.comm.BW,ris_snr(t,c,r,:));
                                    state_ncr_rates(t,c,r,:)=table_rate_calc(prm.comm.BW,ncr_snr(t,c,r,:));
                            end
         
                            for s=1:16
                                if state_ris_rates(t,c,r,s) > state_direct_rates(t,c,s)

                                    ris_better_mask(t,c,r,s) = 1;

                                end
                                if state_ncr_rates(t,c,r,s) > state_direct_rates(t,c,s)

                                    ncr_better_mask(t,c,r,s) = 1;

                                end
                                ris_better_rate = (1 - ris_better_mask(t,c,r,s))*state_direct_rates(t,c,s) + ris_better_mask(t,c,r,s)*state_ris_rates(t,c,r,s);
                                ncr_better_rate = (1 - ncr_better_mask(t,c,r,s))*state_direct_rates(t,c,s) + ncr_better_mask(t,c,r,s)*state_ncr_rates(t,c,r,s);
                                ris_avg_rate(t,c,r) = ris_avg_rate(t,c,r) + state_probabilities(t,c,r,s)*ris_better_rate;
                                ncr_avg_rate(t,c,r) = ncr_avg_rate(t,c,r) + state_probabilities(t,c,r,s)*ncr_better_rate;
                            end
                            ris_time_fraction = sum(ris_better_mask(t,c,r,:).*state_probabilities(t,c,r,:));
                            ncr_time_fraction = sum(ncr_better_mask(t,c,r,:).*state_probabilities(t,c,r,:));
                            if ris_time_fraction > 0
                                ris_rates(t,c,r) = sum(ris_better_mask(t,c,r,:).*state_probabilities(t,c,r,:).*state_ris_rates(t,c,r,:))/ris_time_fraction; %weighted rate considering only the states in which the SD is actually used
                                ris_rates(t,c,r) = ris_rates(t,c,r)/ris_time_fraction; %divide again by the time fraction to obtain the relative bitrate compared to the total frame

                            end
                            if ncr_time_fraction > 0
                                ncr_rates(t,c,r) = sum(ncr_better_mask(t,c,r,:).*state_probabilities(t,c,r,:).*state_ncr_rates(t,c,r,:))/ncr_time_fraction;
                                ncr_rates(t,c,r) = ncr_rates(t,c,r)/ncr_time_fraction;
                            end


                        end
                    end
                end 
            end
            avg_rates.ris = ris_avg_rate;
            avg_rates.ncr = ncr_avg_rate;
            ris_rates(~isfinite(ris_rates)) = 0;
            ncr_rates(~isfinite(ncr_rates)) = 0;
            sd_rates.ris = ris_rates;
            sd_rates.ncr = ncr_rates;
            sd_better_mask.ris = ris_better_mask;
            sd_better_mask.ncr = ncr_better_mask;
            rates_per_state.dir = state_direct_rates;
            rates_per_state.ris = state_ris_rates;
            rates_per_state.ncr = state_ncr_rates;
            access_snr.dir = direct_snr;
            access_snr.ris = ris_snr;
            access_snr.ncr = ncr_snr;

        otherwise
            error('Unrecognized tx type');
    end
    
    if save_to_cache
        save(cache_path, 'state_direct_rates', 'state_ris_rates', 'state_ncr_rates','-append');
    end



end
end

