classdef iab_ris_fixedDonor_multi_instance < instance
    %IAB_RIS_MULTI_INSTANCE Summary of this class goes here
    %   Detailed explanation goes here

    methods
        function obj = iab_ris_fixedDonor_multi_instance(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed)
            %IAB_RIS_MULTI_INSTANCE Construct an instance of this class
            obj@instance(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed);
        end

        function [instance_struct, workspace_struct] = generate_inner(obj)
            init;

            % generate if cache non found, else unpack cache
            if obj.site_cache_found
                v2struct(obj.site_cache);
            else
                %% cs and tp generation
                [n_tp,n_cs,cs_cs_distance_matrix, cs_tp_distance_matrix,...
                    cs_positions, tp_positions] = ...
                    generate_cs_tp_positions(obj.scenario,obj.PLOT_SITE,obj.FIGURE_EXPORT_STYLE);

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
                        [max_airtime,reflected_airtime,bh_rates] ...
                            = compute_rates_basemodel(obj.scenario,cs_tp_distance_matrix,cs_cs_distance_matrix);
                    case 'advanced'
                        % Set radio parameters
                        prm.comm = Set_CommParams(28e9,200e6,'NoShadowing');
                        %prm.Blockage = Set_BlockageParams(28e9,6,3,2,2,2e-3,'Median','Interpolate');
                        prm.Config.Check_Static_Blockage = false;
                        prm.Config.Check_Dynamic_Blockage = false;
                        

                        % Scenarios
                        pl_settings.Tx2Rx = 'UMi';
                        pl_settings.Tx2AF = 'UMi';
                        pl_settings.AF2Rx = 'UMi';

                        % 3D positions
                        iab_positions_3d = [cs_positions, repmat(obj.scenario.radio.iab_height,n_cs,1)];
                        ue_positions_3d = [tp_positions, repmat(obj.scenario.radio.ue_height,n_tp,1)];
                        ris_positions_3d = [cs_positions, repmat(obj.scenario.radio.ris_height,n_cs,1)];
                        af_positions_3d = ris_positions_3d;
                        [~,direct_rates_dl,~,ris_rates_dl,~,af_rates_dl] = ...
                            access_rates_fixed(prm,pl_settings,'DL',iab_positions_3d,ue_positions_3d,ris_positions_3d,af_positions_3d); %DL access rates
                        [~,direct_rates_ul,~,ris_rates_ul,~,af_rates_ul] = ...
                            access_rates_fixed(prm,pl_settings,'UL',iab_positions_3d,ue_positions_3d,ris_positions_3d,af_positions_3d); %UL access rates

                        [bh_rates,~]=backhaul_rates_fixed(prm,pl_settings,iab_positions_3d); %backhaul rates

                        %airtimes
                        direct_airtime_dl = repmat(obj.scenario.sim.R_dir_min./direct_rates_dl, 1,1,n_cs);
                        direct_airtime_ul = repmat(obj.scenario.sim.uplink_ratio*obj.scenario.sim.R_dir_min./direct_rates_ul, 1,1,n_cs);

                        ris_airtime_dl = (obj.scenario.sim.R_dir_min*obj.scenario.sim.rate_ratio)./ris_rates_dl;
                        ris_airtime_ul = (obj.scenario.sim.uplink_ratio*obj.scenario.sim.R_dir_min*obj.scenario.sim.rate_ratio)./ris_rates_ul;

                        sr_airtime_dl = (obj.scenario.sim.R_dir_min*obj.scenario.sim.rate_ratio)./af_rates_dl;
                        sr_airtime_ul = (obj.scenario.sim.uplink_ratio*obj.scenario.sim.R_dir_min*obj.scenario.sim.rate_ratio)./af_rates_ul;

                        direct_airtime_dl(direct_airtime_dl == Inf)=1; %if any of the airtimes is infinite it means that channel does not exists
                        direct_airtime_ul(direct_airtime_ul == Inf)=1; %we set them to 1 so that the link won't be considered

                        ris_airtime_dl(ris_airtime_dl == Inf)=1;
                        ris_airtime_ul(ris_airtime_ul == Inf)=1;

                        sr_airtime_dl(sr_airtime_dl == Inf)=1;
                        sr_airtime_ul(sr_airtime_ul == Inf)=1;

                        max_airtime_ris_dl = max(direct_airtime_dl, ris_airtime_dl); %maximum airtimes
                        max_airtime_sr_dl = max(direct_airtime_dl, sr_airtime_dl);
                        max_airtime_ris_ul = max(direct_airtime_ul, ris_airtime_ul);
                        max_airtime_sr_ul = max(direct_airtime_ul, sr_airtime_ul);

                        % this is specific to this instance
                        max_airtime = max_airtime_ris_dl;
                        reflected_airtime = ris_airtime_dl;
                        %                     % build entities
                        %                     ue_entity = Network_Entity('UE',[0,+20,2], obj.scenario.radio.radio_prm,'Orientation','Optimum');
                        %                     donor_entity = Network_Entity('BS',[0,-30,7],obj.scenario.radio.radio_prm,'Type','Donor','Orientation',0);
                        %                     iab_entity =  Network_Entity('BS',[0,-20,7],obj.scenario.radio.radio_prm,'Type','IAB','Orientation',0);
                        %                     ris_entity = Network_Entity('RIS',[0,0,0], obj.scenario.radio.radio_prm,'Orientation',-pi,'Dir','true','Policy',obj.scenario.radio.radio_prm.RIS_policy);
                        %                     % the following iab entity will be used when 2 iabs are
                        %                     % involved in communication
                        %                     iab_entity_copy =  Network_Entity('BS',[0,-20,7],obj.scenario.radio.radio_prm,'Type','IAB','Orientation',0);
                        %
                        %                     ue_entity.Center = [0,0,obj.scenario.radio.ue_height];
                        %                     donor_entity.Center = [0,0,obj.scenario.radio.donor_height];
                        %                     iab_entity.Center = [0,0,obj.scenario.radio.iab_height];
                        %                     ris_entity.Center = [0,0,obj.scenario.radio.ris_height];
                        %                     ris_entity.Orientation = 'Specular';
                        %                     donor_entity.Orientation = 0; % oriented towards the centeer of the cell
                        %
                        %                     direct_rates = ones(n_tp,n_cs);
                        %                     reflected_rates = ones(n_tp,n_cs,n_cs);
                        %                     bh_rates = ones(n_cs,n_cs);
                        %
                        %                     % compute optimal angles for iab nodes, such that for
                        %                     % each there is always a panel pointing to the donor
                        %                     relative_donor_positions = cs_positions(end,:) - cs_positions(1:end-1,:);
                        %                     iab_nodes_orientation = wrapTo360(atan2d(relative_donor_positions(:,2),relative_donor_positions(:,1)));
                        %                     %iab_nodes_orientation = zeros(size(iab_nodes_orientation));%§focidf
                        %                     tot=n_cs^2*n_tp;
                        %                     it=1;
                        %                     obj.debug_msg('Generating advanced RIS snr...',obj.VERBOSE)
                        %                     % direct and access rates
                        %                     for t = 1:n_tp
                        %                         for d = 1:n_cs
                        %                             obj.delete_then_debug_msg([num2str((it/tot)*1e2) ' % done'],obj.VERBOSE);
                        %
                        %                             % direct rates
                        %                             if d==n_cs % this is the donor
                        %                                 direct_rates(t,d) = compute_direct_rates_advanced(obj.scenario,cs_positions(d,:),tp_positions(t,:),donor_entity,ue_entity,ris_entity);
                        %                             else % this is an iab node
                        %                                 iab_entity.Orientation = iab_nodes_orientation(d);
                        %                                 direct_rates(t,d) = compute_direct_rates_advanced(obj.scenario,cs_positions(d,:),tp_positions(t,:),iab_entity,ue_entity,ris_entity);
                        %                             end
                        %
                        %                             % reflected rates
                        %                             for r = 1:n_cs
                        %                                 it=it+1;
                        %                                 if d == r
                        %                                     reflected_rates(t,d,r) = 1;
                        %                                     continue;
                        %                                 end
                        %                                 if d == n_cs % this is the donor
                        %                                     reflected_rates(t,d,r) = ...
                        %                                         compute_ris_rates_advanced(obj.scenario,cs_positions(d,:),tp_positions(t,:),cs_positions(r,:),donor_entity,ue_entity,ris_entity);
                        %                                 else %this is an iab node
                        %                                     iab_entity.Orientation = iab_nodes_orientation(d);
                        %                                     reflected_rates(t,d,r) = ...
                        %                                         compute_ris_rates_advanced(obj.scenario,cs_positions(d,:),tp_positions(t,:),cs_positions(r,:),iab_entity,ue_entity,ris_entity);
                        %                                 end
                        %                             end
                        %                         end
                        %                     end
                        %                     obj.delete_then_debug_msg('100 % done',obj.VERBOSE);
                        %
                        %                     % backhaul rates
                        %                     for c=1:n_cs
                        %                         for d=1:n_cs
                        %                             if d==c
                        %                                 continue;
                        %                             end
                        %                             if c==n_cs
                        %                                 % this is the donor transmitting
                        %                                 iab_entity.Orientation = iab_nodes_orientation(d);
                        %                                 bh_rates(c,d)=...
                        %                                     compute_direct_rates_advanced(obj.scenario,cs_positions(c,:),cs_positions(d,:),donor_entity,iab_entity,ris_entity);
                        %                             elseif d==n_cs
                        %                                 % this is the donor receiving
                        %                                 iab_entity.Orientation = iab_nodes_orientation(c);
                        %                                 bh_rates(c,d)=...
                        %                                     compute_direct_rates_advanced(obj.scenario,cs_positions(c,:),cs_positions(d,:),iab_entity,donor_entity,ris_entity);
                        %                             else % none is the donor
                        %                                 iab_entity.Orientation = iab_nodes_orientation(c);
                        %                                 iab_entity_copy.Orientation = iab_nodes_orientation(d);
                        %                                 bh_rates(c,d)=...
                        %                                     compute_direct_rates_advanced(obj.scenario,cs_positions(c,:),cs_positions(d,:),iab_entity,iab_entity_copy,ris_entity);
                        %                             end
                        %                         end
                        %                     end
                        %
                        %                     direct_airtime = repmat(obj.scenario.sim.R_dir_min./direct_rates, 1,1,n_cs);
                        %                     reflected_airtime = (obj.scenario.sim.R_dir_min*obj.scenario.sim.rate_ratio)./reflected_rates;
                        %                     max_airtime = max(direct_airtime, reflected_airtime);
                        %
                        %                     max_airtime(max_airtime == Inf) = 0;
                        %                     reflected_airtime(reflected_airtime == Inf) = 0;

                    otherwise
                        errror('Unrecognized snr model');
                end
            end
            %% variable pruning

            ris_p_mask = true(n_tp,n_cs,n_cs);

            %capacity pruning
            temp_mask = max_airtime <= 1 & reflected_airtime <= 1;

            %angles pruning
            angles_mask_ris = zeros(n_tp,n_cs,n_cs);
            for r=1:n_cs
                for d=1:n_cs
                    for t=1:n_tp
                        angles_mask_ris(t,d,r) = max([cs_tp_angles(r,t) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t) cs_cs_angles(r,d)]) <= 2*sim.max_angle_span;
                    end
                end
            end

            ris_p_mask = ris_p_mask & angles_mask_ris & temp_mask;

            % put diagonals to 0
            for t=1:n_tp
                for c=1:n_cs
                    ris_p_mask(t,c,c) = 0;
                end
            end

            bh_p_mask = ones(n_cs,n_cs) - diag(ones(n_cs,1));

            %% generate instance structure
            instance_struct.n_cs=n_cs;
            instance_struct.n_tp=n_tp;

            instance_struct.donor_price = sim.donor_price;
            instance_struct.ris_price = sim.ris_price;
            instance_struct.iab_price = sim.iab_price;
            instance_struct.budget = sim.budget;

            instance_struct.bh_p_mask = bh_p_mask;
            instance_struct.src_p_mask = ris_p_mask;

            instance_struct.angsep = smallest_angles;
            instance_struct.linlen = cs_tp_distance_matrix';

            instance_struct.C_bh = bh_rates;
            instance_struct.min_rate = sim.R_dir_min;
            instance_struct.max_airtime = max_airtime;
            instance_struct.ris_airtime = reflected_airtime;

            instance_struct.cs_tp_angles = cs_tp_angles;
            instance_struct.cs_cs_angles = cs_cs_angles;

            instance_struct.ris_angle_span = sim.max_angle_span;

            instance_struct.angsep_norm = 180;
            instance_struct.linlen_norm = max(cs_tp_distance_matrix(:));
            instance_struct.angsep_emphasis = sim.OF_weight;

            instance_struct.output_filename = [num2str(obj.dataname) '.m'];

            instance_struct.donor_cs_id = n_cs;

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
            var_list = {'n_tp';
                'n_cs';
                'cs_cs_distance_matrix';
                'cs_tp_distance_matrix';
                'cs_positions';
                'tp_positions';
                'cs_tp_angles';
                'cs_cs_angles';
                'smallest_angles'};
        end

        function [var_list]=get_radio_cache_var_list(obj)
            var_list = {
                'max_airtime';
                'reflected_airtime';
                'bh_rates';
                };
%             var_list = {
%                 'direct_rates_dl';
%                 'ris_rates_dl';
%                 'af_rates_dl';
%                 'direct_rates_ul';
%                 'ris_rates_ul';
%                 'af_rates_ul';
%                 'bh_rates';
%                 };
        end
    end
end
