classdef ris_sr_iab_fixeddonor_instance < instance
%This class generates the instance for the RIS+SR planning model
    methods
        function obj = ris_sr_iab_fixeddonor_instance(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed)
            %RIS_SR_IAB_DONOR_INSTANCE Construct an instance of this class
            obj@instance(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed);
        end

        function [instance_struct, workspace_struct]=generate_inner(obj)
            init;
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
            %% Radio channels computation
                        % generate if cache non found, else unpack cache
            if obj.radio_cache_found
                v2struct(obj.radio_cache);
            else
                switch obj.scenario.radio.snr_model
                    case 'base'
                        [max_airtime,reflected_airtime,bh_rate] ...
                            = compute_rates_basemodel(obj.scenario,cs_tp_distance_matrix,cs_cs_distance_matrix);
                    case 'advanced'
                        % Set radio parameters
                        prm.comm = Set_CommParams(28e9,200e6,'NoShadowing');
                        %prm.Blockage = Set_BlockageParams(28e9,6,3,2,2,2e-3,'Median','Interpolate');

                        % Scenarios
                        Scenario.Tx2Rx = 'UMi';
                        Scenario.Tx2AF = 'UMi';
                        Scenario.AF2Rx = 'UMi';

                        % 3D positions
                        iab_positions_3d = [cs_positions, repmat(radio.iab_height,n_cs,1)];
                        ue_positions_3d = [tp_positions, repmat(radio.ue_height,n_tp,1)];
                        ris_positions_3d = [cs_positions, repmat(radio.ris_height,n_cs,1)];
                        af_positions_3d = ris_positions_3d;


                        %% Channel calculations
                        [~,direct_rates_dl,~,ris_rates_dl,~,af_rates_dl] = ...
                            access_rates_fixed(prm,Scenario,'DL',iab_positions_3d,ue_positions_3d,ris_positions_3d,af_positions_3d); %DL access rates 
                        [~,direct_rates_ul,~,ris_rates_ul,~,af_rates_ul] = ...
                           access_rates_fixed(prm,Scenario,'UL',iab_positions_3d,ue_positions_3d,ris_positions_3d,af_positions_3d); %UL access rates

                        [bh_rates,~]=backhaul_rates_fixed(prm,Scenario,iab_positions_3d); %backhaul rates

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
                        sr_airtime_dl(isnan(sr_airtime_dl))=1;
                        sr_airtime_ul(isnan(sr_airtime_ul))=1;

                        max_airtime_ris_dl = max(direct_airtime_dl, ris_airtime_dl); %maximum airtimes
                        max_airtime_sr_dl = max(direct_airtime_dl, sr_airtime_dl);
                        max_airtime_ris_ul = max(direct_airtime_ul, ris_airtime_ul);
                        max_airtime_sr_ul = max(direct_airtime_ul, sr_airtime_ul);

    %                     max_airtime_ris_dl(max_airtime_ris_dl == Inf) = 0; %set infinite airtimes to zero
    %                     max_airtime_sr_dl(max_airtime_sr_dl == Inf) = 0;
    %                     max_airtime_ris_ul(max_airtime_ris_ul == Inf) = 0;
    %                     max_airtime_sr_ul(max_airtime_sr_ul == Inf) = 0;
    %                     
                    otherwise
                        error('Unrecognized snr model');
                end
            end
            
            % variable pruning
            
            ris_p_mask = true(n_tp,n_cs,n_cs);
            af_p_mask = true(n_tp,n_cs,n_cs);
            %capacity pruning
            temp_mask_ris = max_airtime_ris_dl < 1 & ris_airtime_dl < 1;
            temp_mask_sr = max_airtime_sr_dl < 1 & sr_airtime_dl < 1;
            
            %angles pruning
            angles_mask_ris = zeros(n_tp,n_cs,n_cs);
            for r=1:n_cs
                for d=1:n_cs
                    for t=1:n_tp
                        angles_mask_ris(t,d,r) = max([cs_tp_angles(r,t) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t) cs_cs_angles(r,d)]) <= 2*sim.max_angle_span;
                    end
                end
            end
            
            ris_p_mask = ris_p_mask & angles_mask_ris & temp_mask_ris;
            af_p_mask = af_p_mask & temp_mask_sr;
            %put diagonals to 0
            for t=1:n_tp
                for c=1:n_cs
                    ris_p_mask(t,c,c) = 0;
                    af_p_mask(t,c,c)=0;
                end
            end
            
            bh_p_mask = ones(n_cs,n_cs) - diag(ones(n_cs,1));

            %% generate instance structure

            %candidate sites and test points
            instance_struct.n_cs=n_cs;
            instance_struct.n_tp=n_tp;

            %budgeting
            instance_struct.ris_budget = sim.ris_budget;

            instance_struct.ris_price = sim.ris_price;
            instance_struct.iab_price = sim.iab_price;
            instance_struct.sr_price = sim.af_price;

            %access and backhaul masks
            instance_struct.bh_p_mask = bh_p_mask;
            instance_struct.acc_p_mask = ris_p_mask;
            instance_struct.sr_p_mask = af_p_mask;

            %downlink and uplink demands
            instance_struct.d = ones(n_tp,1).*sim.R_dir_min;
            instance_struct.d_ul = ones(n_tp,1).*sim.R_dir_min*0.1;

            %distances
            instance_struct.cs_tp_dist = cs_tp_distance_matrix';

            %angle section
            instance_struct.cs_tp_angles = cs_tp_angles;
            instance_struct.cs_cs_angles = cs_cs_angles;
            instance_struct.smallest_angles = smallest_angles;
            instance_struct.angle_span = sim.max_angle_span;

            %sr bs panel orientation
            sr_minangle=mod(cs_cs_angles+90,360);
            instance_struct.sr_minangle=sr_minangle-diag(diag(sr_minangle));

            sr_maxangle=mod(cs_cs_angles-90,360);
            instance_struct.sr_maxangle=sr_maxangle-diag(diag(sr_maxangle));
            %OF weight and degradation factor
            instance_struct.OF_weight = sim.OF_weight;
            instance_struct.rate_ratio = sim.rate_ratio;

            %OF normalization constraints
            instance_struct.angle_norm = 180;
            instance_struct.length_norm = max(cs_tp_distance_matrix(:));

            %max airtimes for halfduplex
            
            instance_struct.max_airtime_dl_ris = max_airtime_ris_dl;
            instance_struct.max_airtime_dl_sr = max_airtime_sr_dl;
            instance_struct.max_airtime_ul_ris = max_airtime_ris_ul;
            instance_struct.max_airtime_ul_sr = max_airtime_sr_ul;

            %airtimes for RIS/SR sharing
            instance_struct.direct_airtime_dl = direct_airtime_dl;
            instance_struct.ris_airtime_dl = ris_airtime_dl;
            instance_struct.sr_airtime_dl = sr_airtime_dl;

            instance_struct.direct_airtime_ul = direct_airtime_ul;
            instance_struct.ris_airtime_ul = ris_airtime_ul;
            instance_struct.sr_airtime_ul = sr_airtime_ul;

            instance_struct.c_bh = bh_rates;

            instance_struct.output_filename = [num2str(obj.dataname) '.m'];
            %% generate workspace structure
            workspace_struct=ws2struct();

        end
        function plot_solution(obj)
            if ~obj.is_solved
<<<<<<< HEAD
                obj.solve();
            end
            plot_ris_sr_multi_final(obj.workspace_struct,obj.solution_struct,obj.FIGURE_EXPORT_STYLE);
=======
                warning('Planning instance not yet solved, cannot plot')
            else
            plot_iab_ris_multi_final(obj.workspace_struct,obj.solution_struct,obj.FIGURE_EXPORT_STYLE);
            end
>>>>>>> 6af470cb62a1556d164ef5c04984acc8291a6441
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
                'direct_airtime_dl';
                'direct_airtime_ul';
                'max_airtime_ris_dl';
                'max_airtime_ris_ul';
                'max_airtime_sr_dl';
                'max_airtime_sr_ul';
                'ris_airtime_dl';
                'ris_airtime_ul';
                'sr_airtime_dl';
                'sr_airtime_ul';
                'bh_rates';
                };
        end
    end
end