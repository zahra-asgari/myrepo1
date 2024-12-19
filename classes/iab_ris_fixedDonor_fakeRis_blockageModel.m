classdef iab_ris_fixedDonor_fakeRis_blockageModel < instance
    %This class describes the environment of the model integrating the
    %probabilistic blockage model developed by Spagnolini's group with
    %Paolo's self-blocking model and Eugenio's fake RIS method
    %   TODO documentation for every function

    methods
        function obj = iab_ris_fixedDonor_fakeRis_blockageModel(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed)
            %IAB_RIS_MULTI_INSTANCE Construct an instance of this class
            obj@instance(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed);
        end

        function [instance_struct, workspace_struct] = generate_inner(obj)
            init;
            use_extra_topology = 0;
            load('Blockage_Data/fsi_cell.mat');
            if parallel.internal.pool.isPoolThreadWorker||~isempty(getCurrentJob)
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
                        [tested_centers, prm.Blockage] = freeDonorSite(obj.scenario.site.coord_lim,obj.scenario.site.site_width,obj.scenario.radio.donor_height,tested_centers,disjoint_fsi);
                    else
                        [tested_centers, prm.Blockage] = freeDonorSite(obj.scenario.site.coord_lim,obj.scenario.site.site_width,obj.scenario.radio.donor_height,tested_centers);
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
                        prm.comm = Set_CommParams(28e9,200e6,'NoShadowing');
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
                        prm.Blockage.Donor = Set_BlockageParams(28e9,25,1.6,1.8,4.5,2e-3,'Random','Interpolate');
                        prm.Blockage.IABNode = Set_BlockageParams(28e9,6,1.6,1.8,4.5,2e-3,'Random','Interpolate');
                        prm.Blockage.RIS = Set_BlockageParams(28e9,3,1.6,1.8,4.5,2e-3,'Random','Interpolate');

                        % Scenarios

                        %BS to BS
                        pl_settings.Tx2Rx = 'UMi';


                        %% self-blockage zone probabilities computation
                        [rsbz_probs, r_nsbz_probs] = self_blockage_probs(smallest_angles);
                        prm.Blockage.rsbz_probs = rsbz_probs;
                        prm.Blockage.r_nsbz_probs = r_nsbz_probs;
                        prm.Blockage.dsbz_prob = 7/18;
                        prm.Blockage.fixed_sbz_loss = 40; %fixed additive 40 db loss if in self-blockage zone. This parameter can be adjusted in the future
                        
                        % 3D positions
                        iab_positions_3d = [cs_positions, repmat(obj.scenario.radio.iab_height,n_cs,1)];
                        ue_positions_3d = [tp_positions, repmat(obj.scenario.radio.ue_height,n_tp,1)];
                        ris_positions_3d = [cs_positions, repmat(obj.scenario.radio.ris_height,n_cs,1)];
                        %set Donor position height
                        iab_positions_3d(n_cs ,3) = obj.scenario.radio.donor_height;
                        ris_positions_3d(1,3) = 0; %fake ris
                        %The Donor is the last after n_cs CSs, and the
                        %fake RIS the last in all the set of CS (max 256, pruned by the hexagonal shape)
                        
                        [direct_rates, reflected_rates, weighted_rates,ris_rates,state_probs,ris_better_mask] = ...
                            access_rates_weighted_RIS_DL(obj.scenario, prm,pl_settings,'DL',iab_positions_3d,ue_positions_3d,ris_positions_3d); %DL access rates


                        [bh_rates]=backhaul_rates_high_donor(obj.scenario,prm,pl_settings,iab_positions_3d); %backhaul rates
                        

                        
                    otherwise
                        error('Unrecognized snr model');
                end
            end

            
            %% variable pruning

            ris_p_mask = true(n_tp,n_cs,n_cs);

            %capacity pruning
           % temp_mask = full_airtimes <= 1 & full_airtimes > 0;
             cap_mask = ris_rates >= sim.R_dir_min & weighted_rates >= sim.R_dir_min;
             cap_mask(:,:,1) = weighted_rates(:,:,1) >= sim.R_dir_min;

            %angles pruning
            angles_mask_ris = true(n_tp,n_cs,n_cs);
            for r=2:n_cs
                for d=1:n_cs
                    for t=1:n_tp
                        angles_mask_ris(t,d,r) = max([cs_tp_angles(r,t) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t) cs_cs_angles(r,d)]) <= 2*sim.max_angle_span;
                    end
                end
            end
            %ris_p_mask = ris_p_mask & angles_mask_ris & temp_mask;
            ris_p_mask = ris_p_mask & angles_mask_ris & cap_mask;

            % put diagonals to 0
            for t=1:n_tp
                for c=1:n_cs
                    ris_p_mask(t,c,c) = 0;
                end
            end

            bh_p_mask = (ones(n_cs,n_cs) - diag(ones(n_cs,1))) & bh_rates >= sim.R_dir_min;
            
            
            %% generate instance structure
            instance_struct.n_cs=n_cs;
            instance_struct.n_tp=n_tp;

            instance_struct.ris_price = sim.ris_price;
            instance_struct.iab_price = sim.iab_price;
            instance_struct.budget = sim.budget;

            instance_struct.bh_p_mask = bh_p_mask;
            instance_struct.src_p_mask = ris_p_mask;

            %instance_struct.angsep = smallest_angles;
            instance_struct.linlen = cs_tp_distance_matrix';

            
            
            
            instance_struct.C_bh = bh_rates;
            instance_struct.C_src = weighted_rates;
            instance_struct.C_ris = ris_rates;
            instance_struct.C_fullris = sum(reflected_rates.*state_probs,4);
            instance_struct.min_rate = sim.R_dir_min;
           % instance_struct.max_airtime = full_airtimes;
           % instance_struct.ris_airtime = ris_airtimes;

            instance_struct.cs_tp_angles = cs_tp_angles;
            instance_struct.cs_cs_angles = cs_cs_angles;

            instance_struct.ris_angle_span = sim.max_angle_span;

            %instance_struct.angsep_norm = 180;
            %instance_struct.linlen_norm = max(cs_tp_distance_matrix(:));
            %instance_struct.angsep_emphasis = sim.OF_weight;

            instance_struct.output_filename = [num2str(obj.dataname) '.m'];

            instance_struct.M_max = max(max(bh_rates(n_cs,:)),max(weighted_rates(:,n_cs,:),[],'all'));
            %FORCED BOTTLENECK TECHNIQUE!!
%            instance_struct.M_max = instance_struct.M_max/10;

            instance_struct.donor_cs_id = n_cs;
            instance_struct.fakeris_cs_id = 1;

            if use_extra_topology
               solution_name = ['remote_campaigns/blockagecampaign_extra_ris_100/tolocal/hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel' num2str(instance_struct.budget) ...
               '_100runs/solutions/iab_ris_fixedDonor_fakeRis_blockageModel_sumextra_run' num2str(rng_seed) '.m'];
               if isfile(solution_name)
                 disp('SOLUTION EXISTS!');
              	 run(solution_name);
              	 instance_struct.y_iab_par = (sum(f)>1);
                 instance_struct.y_iab_par(end) = 1;
              	 instance_struct.y_ris_par = squeeze(sum(x.*ris_rates,[1,2]) >1)';
                 instance_struct.y_ris_par(1) = 1;
                 instance_struct.z_par = f>1;
                 instance_struct.x_par = x;
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
                };
        end

        function [var_list]=get_radio_cache_var_list(obj)
            var_list = {
                %'full_airtimes';
                %'ris_airtimes';
                'bh_rates';
                'weighted_rates';
                'ris_rates';
                'rsbz_probs';
                'r_nsbz_probs'; %probability of self-blockage given the min angle between two CS from a TP's PoV
                'state_probs'; %overall probability for the 16 blockage states
                'direct_rates';
                'reflected_rates';
                'ris_better_mask';
                'ris_p_mask';
                };
        end
    end
end
