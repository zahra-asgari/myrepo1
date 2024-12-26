+classdef instance_complete_fixedDonor_blockageModel < instance
    %This class describes the environment of the model integrating the
    %probabilistic blockage model developed by Spagnolini's group with
    %Paolo's self-blocking model and Eugenio's fake RIS method
    %   TODO documentation for every function

    methods
        function obj = instance_complete_fixedDonor_blockageModel(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed)
            %IAB_RIS_MULTI_INSTANCE Construct an instance of this class
            obj@instance(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed);
        end

        function [instance_struct, workspace_struct] = generate_inner(obj)
            init;
            use_extra_topology = (contains(obj.model_name,'for_peak')); %check what mean throughput 
            % can be achieved by using the peak trhouput driven topology
            fsi_driven = 1; %select instances with different free space index
            autonomous_refl = (contains(obj.model_name,'_sd_')); %boolean to prune the SRCs which cannot sustain the minimum demand with just the reflected (weaker) links
            load('Blockage_Data/fsi_cell.mat');
            if parallel.internal.pool.isPoolThreadWorker||~isempty(getCurrentJob)
		%disp(instances);
                disjoint_fsi = linspace(min(fsi_cell(find(fsi_filter==0)),[],'all'),50,instances+1);
            end
            % generate if cache non found, else unpack cache
            if obj.site_cache_found
                v2struct(obj.site_cache);
            else                
                %% calculate coordinates [x,y] of the hexagonal site center inside the city of Milan, 
                %% such that the Donor doesn't overlap with a building
                blockedDonor = 1;
                tested_centers = [];
                
                while blockedDonor
                    if parallel.internal.pool.isPoolThreadWorker||~isempty(getCurrentJob)
			disp(['IM IN PARALLEL!!! INSTANCE' num2str(rng_seed)])
                        [tested_centers, prm.Blockage] = freeDonorSite(obj.scenario.site.coord_lim,obj.scenario.site.site_width,obj.scenario.radio.donor_height,tested_centers,fsi_driven,disjoint_fsi);
                    else
                        [tested_centers, prm.Blockage] = freeDonorSite(obj.scenario.site.coord_lim,obj.scenario.site.site_width,obj.scenario.radio.donor_height,tested_centers,fsi_driven);
                    end
                    % blockedDonor = 0;
                    % load("cache/containment_for_tests/70cdb5199bfc131b164dada8792e2990.mat","cs_positions");
                    % prm.Blockage.site_center = cs_positions(27,:);
                    % prm.Blockage.site_center(1) = prm.Blockage.site_center(1) + 150;
                    %% cs and tp generation (THIS IS NOT THE ALL-COMPREHENSIVE GENERATION, ONLY THE SPECIFIC CASE OF HEXAGONAL CELL AND BUILDINGS)
                    [n_tp,n_cs,cs_cs_distance_matrix, cs_tp_distance_matrix,...
                        cs_positions, tp_positions, pruning_struct, blockedDonor] = ...
                        generateFreeCSTPPositions(obj.scenario,obj.PLOT_SITE,prm.Blockage);
                end
                % prm.Blockage.Buildings = tempBuildings;
                prm.Blockage.pruning_bh = pruning_struct.bh;
                prm.Blockage.pruning_dir = pruning_struct.dir;
                prm.Blockage.pruning_ref1 = pruning_struct.ref1;
                prm.Blockage.pruning_ref2 = pruning_struct.ref2;
                

                %% angles computation

                [cs_tp_angles,cs_cs_angles, smallest_angles] ...
                    = compute_angles(cs_positions, tp_positions);
                
            end

            % generate if cache non found, else unpack cache
            if obj.radio_cache_found
                v2struct(obj.radio_cache);
            else
                
                %% Rates computation
                switch obj.scenario.radio.snr_model
                    case 'base'
                        [full_airtimes,ris_airtimes,bh_rates] ...
                            = compute_rates_basemodel(obj.scenario,cs_tp_distance_matrix,cs_cs_distance_matrix);
                    case 'advanced'
                        % Set radio parameters
                        prm.comm = Set_CommParams(28e9,obj.scenario.radio.bandwidth,'NoShadowing');
                        prm.Config.Check_Static_Blockage = true;
                        prm.Config.Check_Dynamic_Blockage = false; 
                        %I have to put false here otherwise it doesn't
                        %work, I generated the dynamic blockage statistics
                        %beforehand, to not slow down everytime the
                        %instance generation and from the version in the
                        %'reza' folder to the V_5 updated folder, reza
                        %apparently changed a lot and some things don't
                        %work anymore since he included the blockage
                        %management
                        prm.Blockage.Donor = Set_BlockageParams(prm.comm.fc,obj.scenario.radio.donor_height,1.6,1.8,4.5,2e-3,'Random','Interpolate');
                        prm.Blockage.IABNode = Set_BlockageParams(prm.comm.fc,obj.scenario.radio.iab_height,1.6,1.8,4.5,2e-3,'Random','Interpolate');
                        prm.Blockage.RIS = Set_BlockageParams(prm.comm.fc,obj.scenario.radio.ris_height,1.6,1.8,4.5,2e-3,'Random','Interpolate');
                        prm.Blockage.NCR = prm.Blockage.RIS;

                        % Scenarios

                        %BS to BS
                        pl_settings.Tx2Rx = 'UMi';
                        pl_settings.Tx2AF = 'UMi';
                        pl_settings.AF2Rx = 'UMi';


                        %% self-blockage zone probabilities computation
                        [rsbz_probs, r_nsbz_probs, d_sbz_prob] = self_blockage_probs(smallest_angles);
                        prm.Blockage.rsbz_probs = rsbz_probs;
                        prm.Blockage.r_nsbz_probs = r_nsbz_probs;
                        prm.Blockage.dsbz_prob = d_sbz_prob;
                        prm.Blockage.fixed_sbz_loss = 20; %fixed additive 20 db loss if in self-blockage zone. This parameter can be adjusted in the future
                        prm.rate_calc = radio.rate_calc;
                        
                        % 3D positions
                        geometry.iab_positions_3d = [cs_positions, repmat(obj.scenario.radio.iab_height,n_cs,1)];
                        geometry.ue_positions_3d = [tp_positions, repmat(obj.scenario.radio.ue_height,n_tp,1)];
                        geometry.ris_positions_3d = [cs_positions, repmat(obj.scenario.radio.ris_height,n_cs,1)];
                        geometry.ncr_positions_3d = geometry.ris_positions_3d;
                        %set Donor position height
                        geometry.iab_positions_3d(n_cs ,3) = obj.scenario.radio.donor_height;
                        geometry.ris_positions_3d(1,3) = 0; %fake ris
                        geometry.ncr_positions_3d(1,3) = 0; %fake ncr; do we need this?
                        %The Donor is the last after n_cs CSs, and the
                        %fake RIS the last in all the set of CS (max 256, pruned by the hexagonal shape)
                        % 
                        [state_rates.DL, avg_rates.DL,sd_rates.DL,state_probs.DL,sd_better_mask.DL,access_snr.DL] = ...
                            access_rates_weighted_complete(obj.scenario, prm,pl_settings,'DL',geometry); %DL access rates
                         [state_rates.UL, avg_rates.UL,sd_rates.UL,state_probs.UL,sd_better_mask.UL,access_snr.UL] = ...
                            access_rates_weighted_complete(obj.scenario, prm,pl_settings,'UL',geometry); %UL access rates

                        [bh_rates,backhaul_snr]=backhaul_rates_high_donor_complete(prm,pl_settings,geometry.iab_positions_3d); %backhaul rates

                        %% Probabilitiy of unsatisfaction:

                        % Combine rates and probabilities
                        state_probabilities = state_probs.DL; % Assuming state_probs.DL and state_probs.UL are identical
                        state_rates_combined.dir_DL = state_rates.DL.dir;
                        state_rates_combined.dir_UL = state_rates.UL.dir;
                        state_rates_combined.ris_DL = state_rates.DL.ris;
                        state_rates_combined.ris_UL = state_rates.UL.ris;
                        state_rates_combined.ncr_DL = state_rates.DL.ncr;
                        state_rates_combined.ncr_UL = state_rates.UL.ncr;

                        % Define minimum capacity thresholds
                        C_min_DL = sim.alpha * sim.R_dir_min;
                        C_min_UL = (1 - sim.alpha) * sim.R_dir_min;

                        % Calculate P_unsatisfied
                        Prob_unsatisfied = calculate_P_unsatisfied(state_probabilities, state_rates_combined, C_min_DL, C_min_UL);


                          
                                                
                    otherwise
                        error('Unrecognized snr model');
                end
            end

            
            %% variable pruning

            %capacity pruning
            if autonomous_refl
                ris_cap_mask = sd_rates.DL.ris >= sim.alpha*sim.R_dir_min & sd_rates.UL.ris >= (1-sim.alpha)*sim.R_dir_min;
                ris_cap_mask(:,:,1) = avg_rates.DL.ris(:,:,1) >= sim.alpha*sim.R_dir_min & avg_rates.UL.ris(:,:,1) >= (1-sim.alpha)*sim.R_dir_min;
                ncr_p_mask = sd_rates.DL.ncr >= sim.alpha*sim.R_dir_min & sd_rates.UL.ncr >= (1-sim.alpha)*sim.R_dir_min;
                ncr_p_mask(:,:,1) = avg_rates.DL.ncr(:,:,1) >= sim.alpha*sim.R_dir_min & avg_rates.UL.ncr(:,:,1) >= (1-sim.alpha)*sim.R_dir_min;
            else
                ris_cap_mask = avg_rates.DL.ris >= sim.alpha*sim.R_dir_min & avg_rates.UL.ris >= (1-sim.alpha)*sim.R_dir_min;
                ncr_p_mask = avg_rates.DL.ncr >= sim.alpha*sim.R_dir_min & avg_rates.UL.ncr >= (1-sim.alpha)*sim.R_dir_min;

            end



            %angles pruning
            angles_mask_ris = true(n_tp,n_cs,n_cs);
            for r=2:n_cs
                for d=1:n_cs
                    for t=1:n_tp
                        angles_mask_ris(t,d,r) = max([cs_tp_angles(r,t) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t) cs_cs_angles(r,d)]) <= 2*sim.max_angle_span;
                    end
                end
            end
            ris_p_mask = angles_mask_ris & ris_cap_mask;
            % put diagonals to 0
            for t=1:n_tp
                for c=1:n_cs
                    ris_p_mask(t,c,c) = 0;
                    ncr_p_mask(t,c,c) = 0;
                end
            end

            bh_p_mask = (ones(n_cs,n_cs) - diag(ones(n_cs,1)));
            
            
            %% generate instance structure
            instance_struct.n_cs=n_cs;
            instance_struct.n_tp=n_tp;

            instance_struct.ris_price = sim.ris_price;
            instance_struct.iab_price = sim.iab_price;
            instance_struct.ncr_price = sim.af_price;
            instance_struct.budget = sim.budget;

            instance_struct.delta_bh = bh_p_mask;
            instance_struct.delta_src(:,:,:,find(sim.SD_list == 'RIS')) = ris_p_mask;
            instance_struct.delta_src(:,:,:,find(sim.SD_list == 'NCR')) = ncr_p_mask;

            %instance_struct.angsep = smallest_angles;
            %instance_struct.linlen = cs_tp_distance_matrix';
            
            % Store the result in the instance structure
            instance_struct.P_unsatisfied = Prob_unsatisfied;

            instance_struct.C_bh = bh_rates;
            instance_struct.C_src_dl(:,:,:,find(sim.SD_list == 'RIS')) = avg_rates.DL.ris;
            instance_struct.C_src_dl(:,:,:,find(sim.SD_list == 'NCR')) = avg_rates.DL.ncr;
            instance_struct.C_src_ul(:,:,:,find(sim.SD_list == 'RIS')) = avg_rates.UL.ris;
            instance_struct.C_src_ul(:,:,:,find(sim.SD_list == 'NCR')) = avg_rates.UL.ncr;
            instance_struct.C_sd_dl(:,:,:,find(sim.SD_list == 'RIS')) = sd_rates.DL.ris;
            instance_struct.C_sd_dl(:,:,:,find(sim.SD_list == 'NCR')) = sd_rates.DL.ncr;
            instance_struct.C_sd_ul(:,:,:,find(sim.SD_list == 'RIS')) = sd_rates.UL.ris;
            instance_struct.C_sd_ul(:,:,:,find(sim.SD_list == 'NCR')) = sd_rates.UL.ncr;
            instance_struct.min_rate_dl = sim.alpha*sim.R_dir_min;
            instance_struct.min_rate_ul = (1-sim.alpha)*sim.R_dir_min;
	        instance_struct.alpha = sim.alpha;

            instance_struct.cs_tp_angles = cs_tp_angles;
            instance_struct.cs_cs_angles = cs_cs_angles;
            ncr_minangle=mod(cs_cs_angles+90,360);
            instance_struct.ncr_minangle=ncr_minangle-diag(diag(ncr_minangle));

            ncr_maxangle=mod(cs_cs_angles-90,360);
            instance_struct.ncr_maxangle=ncr_maxangle-diag(diag(ncr_maxangle))
            instance_struct.max_angle_span = sim.max_angle_span;

            %instance_struct.angsep_norm = 180;
            %instance_struct.linlen_norm = max(cs_tp_distance_matrix(:));
            %instance_struct.angsep_emphasis = sim.OF_weight;

            instance_struct.output_filename = [num2str(obj.dataname) '.m'];
            big_M = max(sim.alpha*bh_rates(n_cs,:) + (1-sim.alpha)*bh_rates(:,n_cs)');
            %risolto con 256QAM e 400 MHz di banda
            % dl_big_M = big_M_bottleneck(bh_rates,avg_rates.DL,'DL');
            % final_big_M = big_M_bottleneck_final(bh_rates,avg_rates,sim.alpha);
            % dl_big_M = big_M_bottleneck_tree(bh_rates,avg_rates.DL,'DL');
            % ul_big_M = big_M_bottleneck(bh_rates,avg_rates.UL,'UL');
            % ul_big_M = big_M_bottleneck_tree(bh_rates,avg_rates.UL,'UL');
            %ho provato a scrivere un metodo per ridurre il big_M ma è
            %inconsistente, per ora usiamo ancora l'euristica
            instance_struct.M = big_M;

            %FORCED BOTTLENECK TECHNIQUE!!
            instance_struct.M = instance_struct.M/10;

            instance_struct.donor_cs_id = n_cs;
            instance_struct.fakeris_cs_id = 1;
            instance_struct.ris_id = find(sim.SD_list == 'RIS');
            instance_struct.ncr_id = find(sim.SD_list == 'NCR');

            if use_extra_topology
               disp(obj.model_name)
               if   autonomous_refl
                    vv = '_sd';
                    modd = erase(obj.model_name,'_sd'); 
                    %temporary fix for the previous state of the model nomenclature
                    %using obj.model_name works only if I have a single model I think, not verified, i have to fix this 
               else
                   vv = '';
                   modd = obj.model_name;
               end
               
               solution_name = ['remote_campaigns/blockagecampaign_peak_sbz_journal' vv '_UL_NCR_100/hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel' num2str(instance_struct.budget) ...
               '_100runs/solutions/peak_' erase(modd,'_for_peak') '_run' num2str(rng_seed) '.m'];
               disp(solution_name)
               if isfile(solution_name)
                 disp('SOLUTION EXISTS!');
              	 run(solution_name);
                 instance_struct.y_iab_par = y_iab;
              	 instance_struct.y_ris_par = y_ris;
                 instance_struct.y_ncr_par = y_ncr;
                 instance_struct.z_par = z;
                 instance_struct.x_par = x;

              	 % instance_struct.y_iab_par = (sum(f)>1);
                 % instance_struct.y_iab_par(end) = 1;
              	 % instance_struct.y_ris_par = squeeze(sum(x.*ris_rates,[1,2]) >1)';
                 % instance_struct.y_ris_par(1) = 1;
                 % instance_struct.z_par = f>1;
                 % instance_struct.x_par = x;
               else
               	disp('SOLUTION NOT FOUND');
               end
            end

            %% generate workspace structure
            workspace_struct=ws2struct();

        end

        function plot_solution(obj)
            if ~obj.is_solved
                warning('Planning instance not yet solved, cannot plot')
            else
            plot_iab_ris_multi_final(obj.workspace_struct,obj.solution_struct,obj.FIGURE_EXPORT_STYLE);
            end
        end

        function [var_list]=get_site_cache_var_list(obj)
            var_list = {
                'n_tp';
                'n_cs';
                'cs_cs_distance_matrix';
                'cs_tp_distance_matrix';
                'cs_positions';
                'tp_positions';
                'cs_tp_angles';
                'cs_cs_angles';
                'smallest_angles';
                'pruning_struct';
                };
        end

        function [var_list]=get_radio_cache_var_list(obj)
            var_list = {
                'bh_rates';
                'avg_rates';
                'sd_rates';
                'rsbz_probs';
                'r_nsbz_probs'; %probability of self-blockage given the min angle between two CS from a TP's PoV
                'state_probs'; %overall probability for the 16 blockage states
                'state_rates';
                'sd_better_mask';
                'ris_p_mask';
                'ncr_p_mask';
                'access_snr';
                'backhaul_snr';
                %'old_big_M';
                'big_M';
                };
        end
    end
end
