classdef ris_sr_iab_donor_instance < instance
%This class generates the instance for the RIS+SR planning model
    methods
        function obj = ris_sr_iab_donor_instance(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed)
            %RIS_SR_IAB_DONOR_INSTANCE Construct an instance of this class
            obj@instance(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed);
        end

        function [instance_struct, workspace_struct]=generate_inner(obj)
            init;

            %% cs and tp generation
            [n_tp,n_cs,cs_cs_distance_matrix, cs_tp_distance_matrix,...
                cs_positions, tp_positions] = ...
                generate_cs_tp_positions(obj.scenario,obj.PLOT_SITE,obj.FIGURE_EXPORT_STYLE);

            %% angles computation
            [cs_tp_angles,cs_cs_angles, smallest_angles] ...
                = compute_angles(cs_positions, tp_positions);

            %% Radio channels computation
            switch obj.scenario.snr_model
                case 'base'
                    [max_airtime,reflected_airtime,bh_rate] ...
                        = compute_rates_basemodel(obj.scenario,cs_tp_distance_matrix,cs_cs_distance_matrix);
                case 'advanced'
                    % Set radio parameters
                    prm.comm = Set_CommParams(28e9,200e6,'NoShadowing');
                    
                    % Scenarios
                    Scenario.Tx2Rx = 'UMi';
                    Scenario.Tx2AF = 'UMi';
                    Scenario.AF2Rx = 'UMi';
                    
                    % 3D positions
                    iab_positions_3d = [cs_positions, repmat(iab_height,n_cs,1)];
                    ue_positions_3d = [tp_positions, repmat(ue_height,n_tp,1)];
                    ris_positions_3d = [cs_positions, repmat(ris_height,n_cs,1)];
                    af_positions_3d = ris_positions_3d;
                    
                    %% Channel calculations
                    [direct_snr_iab_dl,direct_rates_iab_dl,ris_snr_iab_dl,ris_rates_iab_dl,af_snr_iab_dl,af_rates_iab_dl] = ...
                        access_rates(prm,Scenario,'IAB','DL',iab_positions_3d,ue_positions_3d,ris_positions_3d,af_positions_3d); %DL access rates for IAB
                    [direct_snr_iab_ul,direct_rates_iab_ul,ris_snr_iab_ul,ris_rates_iab_ul,af_snr_iab_ul,af_rates_iab_ul] = ...
                       access_rates(prm,Scenario,'IAB','UL',iab_positions_3d,ue_positions_3d,ris_positions_3d,af_positions_3d); %UL access rates for IAB
                    [direct_snr_donor_dl,direct_rates_donor_dl,ris_snr_donor_dl,ris_rates_donor_dl,af_snr_donor_dl,af_rates_donor_dl] = ...
                       access_rates(prm,Scenario,'Donor','DL',iab_positions_3d,ue_positions_3d,ris_positions_3d,af_positions_3d); %DL access rates for Donor
                    [direct_snr_donor_ul,direct_rates_donor_ul,ris_snr_donor_ul,ris_rates_donor_ul,af_snr_donor_ul,af_rates_donor_ul] = ...
                      access_rates(prm,Scenario,'Donor','UL',iab_positions_3d,ue_positions_3d,ris_positions_3d,af_positions_3d); %UL access rates for Donor
                    
                    [bh_rates_iab,bh_snr_iab]=backhaul_rates(prm,Scenario,'IAB',iab_positions_3d); %IAB-IAB backhaul rates
                    [bh_rates_donor_tx,bh_snr_donor_tx]=backhaul_rates(prm,Scenario,'donor_tx',iab_positions_3d); %Donor-IAB backhaul rates
                    [bh_rates_donor_rx,bh_snr_donor_rx]=backhaul_rates(prm,Scenario,'donor_rx',iab_positions_3d); %IAB-Donor backhaul rates
                    
                    %airtimes
                    direct_airtime_donor_dl = repmat(obj.scenario.R_dir_min./direct_rates_donor_dl, 1,1,n_cs);
                    direct_airtime_donor_ul = repmat(obj.scenario.uplink_ratio*obj.scenario.R_dir_min./direct_rates_donor_ul, 1,1,n_cs);
                    direct_airtime_iab_dl = repmat(obj.scenario.R_dir_min./direct_rates_donor_dl, 1,1,n_cs);
                    direct_airtime_iab_ul = repmat(obj.scenario.uplink_ratio*obj.scenario.R_dir_min./direct_rates_donor_ul, 1,1,n_cs);
                    
                    ris_airtime_donor_dl = (obj.scenario.R_dir_min*obj.scenario.rate_ratio)./ris_rates_donor_dl;
                    ris_airtime_donor_ul = (obj.scenario.uplink_ratio*obj.scenario.R_dir_min*obj.scenario.rate_ratio)./ris_rates_donor_ul;
                    ris_airtime_iab_dl = (obj.scenario.R_dir_min*obj.scenario.rate_ratio)./ris_rates_iab_dl;
                    ris_airtime_iab_ul = (obj.scenario.uplink_ratio*obj.scenario.R_dir_min*obj.scenario.rate_ratio)./ris_rates_iab_ul;
                    
                    sr_airtime_donor_dl = (obj.scenario.R_dir_min*obj.scenario.rate_ratio)./af_rates_donor_dl;
                    sr_airtime_donor_ul = (obj.scenario.uplink_ratio*obj.scenario.R_dir_min*obj.scenario.rate_ratio)./af_rates_donor_ul;
                    sr_airtime_iab_dl = (obj.scenario.R_dir_min*obj.scenario.rate_ratio)./af_rates_iab_dl;
                    sr_airtime_iab_ul = (obj.scenario.uplink_ratio*obj.scenario.R_dir_min*obj.scenario.rate_ratio)./af_rates_iab_ul;
                    
                    max_airtime_ris_donor_dl = max(direct_airtime_donor_dl, ris_airtime_donor_dl);
                    max_airtime_ris_iab_dl = max(direct_airtime_iab_dl, ris_airtime_iab_dl);
                    max_airtime_sr_donor_dl = max(direct_airtime_donor_dl, sr_airtime_donor_dl);
                    max_airtime_sr_iab_dl = max(direct_airtime_iab_dl, sr_airtime_iab_dl);
                    
                    max_airtime_ris_donor_ul = max(direct_airtime_donor_ul, ris_airtime_donor_ul);
                    max_airtime_ris_iab_ul = max(direct_airtime_iab_ul, ris_airtime_iab_ul);
                    max_airtime_sr_donor_ul = max(direct_airtime_donor_ul, sr_airtime_donor_ul);
                    max_airtime_sr_iab_ul = max(direct_airtime_iab_ul, sr_airtime_iab_ul);
                                        
                    max_airtime_ris_donor_dl(max_airtime_ris_donor_dl == Inf) = 0;
                    max_airtime_ris_iab_dl(max_airtime_ris_iab_dl == Inf) = 0;
                    max_airtime_sr_donor_dl(max_airtime_sr_donor_dl == Inf) = 0;
                    max_airtime_sr_iab_dl(max_airtime_sr_iab_dl == Inf) = 0;
                    
                    max_airtime_ris_donor_ul(max_airtime_ris_donor_ul == Inf) = 0;
                    max_airtime_ris_iab_ul(max_airtime_ris_iab_ul == Inf) = 0;
                    max_airtime_sr_donor_ul(max_airtime_sr_donor_ul == Inf) = 0;
                    max_airtime_sr_iab_ul(max_airtime_sr_iab_ul == Inf) = 0;
                    
                    ris_airtime_donor_dl(ris_airtime_donor_dl == Inf)=0;
                    ris_airtime_iab_dl(ris_airtime_iab_dl == Inf)=0;
                    ris_airtime_donor_ul(ris_airtime_donor_ul == Inf)=0;
                    ris_airtime_iab_ul(ris_airtime_iab_ul == Inf)=0;
                    sr_airtime_donor_dl(sr_airtime_donor_dl == Inf)=0;
                    sr_airtime_iab_dl(sr_airtime_iab_dl == Inf)=0;
                    sr_airtime_donor_ul(sr_airtime_donor_ul == Inf)=0;
                    sr_airtime_iab_ul(sr_airtime_iab_ul == Inf)=0;
%                     
                otherwise
                    error('Unrecognized snr model');
            end
            
            % variable pruning
            
            ris_p_mask = true(n_tp,n_cs,n_cs);
            af_p_mask = true(n_tp,n_cs,n_cs);
            %capacity pruning
            temp_mask_ris = max_airtime_ris_iab_dl <= 1 & ris_airtime_iab_dl <= 1;
            temp_mask_sr = max_airtime_sr_iab_dl <= 1 & sr_airtime_iab_dl <= 1;
            
            %angles pruning
            angles_mask_ris = zeros(n_tp,n_cs,n_cs);
            for r=1:n_cs
                for d=1:n_cs
                    for t=1:n_tp
                        angles_mask_ris(t,d,r) = max([cs_tp_angles(r,t) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t) cs_cs_angles(r,d)]) <= 2*max_angle_span;
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
            instance_struct.ris_budget = ris_budget;

            instance_struct.ris_price = ris_price;
            instance_struct.iab_price = iab_price;
            instance_struct.sr_price = af_price;

            %access and backhaul masks
            instance_struct.bh_p_mask = bh_p_mask;
            instance_struct.acc_p_mask = ris_p_mask;
            instance_struct.sr_p_mask = af_p_mask;

            %downlink and uplink demands
            instance_struct.d = ones(n_tp,1).*R_dir_min;
            instance_struct.d_ul = ones(n_tp,1).*R_dir_min*0.1;

            %distances
            instance_struct.cs_tp_dist = cs_tp_distance_matrix';

            %angle section
            instance_struct.cs_tp_angles = cs_tp_angles;
            instance_struct.cs_cs_angles = cs_cs_angles;
            instance_struct.smallest_angles = smallest_angles;
            instance_struct.angle_span = max_angle_span;

            %sr bs panel orientation
            sr_minangle=mod(cs_cs_angles+90,360);
            instance_struct.sr_minangle=sr_minangle-diag(diag(sr_minangle));

            sr_maxangle=mod(cs_cs_angles-90,360);
            instance_struct.sr_maxangle=sr_maxangle-diag(diag(sr_maxangle));
            %OF weight and degradation factor
            instance_struct.OF_weight = OF_weight;
            instance_struct.rate_ratio = rate_ratio;

            %OF normalization constraints
            instance_struct.angle_norm = 180;
            instance_struct.length_norm = max(cs_tp_distance_matrix(:));

            %max airtimes for halfduplex
            instance_struct.max_airtime_dl_ris_donor=max_airtime_ris_donor_dl;
            instance_struct.max_airtime_dl_ris_iab=max_airtime_ris_iab_dl;
            instance_struct.max_airtime_dl_sr_donor = max_airtime_sr_donor_dl;
            instance_struct.max_airtime_dl_sr_iab = max_airtime_sr_iab_dl;

            instance_struct.max_airtime_ul_ris_donor=max_airtime_ris_donor_ul;
            instance_struct.max_airtime_ul_ris_iab=max_airtime_ris_iab_ul;
            instance_struct.max_airtime_ul_sr_donor = max_airtime_sr_donor_ul;
            instance_struct.max_airtime_ul_sr_iab = max_airtime_sr_iab_ul;

            %airtimes for RIS/SR sharing
            instance_struct.direct_airtime_dl_donor = direct_airtime_donor_dl;
            instance_struct.ris_airtime_dl_donor= ris_airtime_donor_dl;
            instance_struct.sr_airtime_dl_donor = sr_airtime_donor_dl;
            instance_struct.direct_airtime_dl_iab = direct_airtime_iab_dl;
            instance_struct.ris_airtime_dl_iab= ris_airtime_iab_dl;
            instance_struct.sr_airtime_dl_iab = sr_airtime_iab_dl;

            instance_struct.direct_airtime_ul_donor = direct_airtime_donor_ul;
            instance_struct.ris_airtime_ul_donor= ris_airtime_donor_ul;
            instance_struct.sr_airtime_ul_donor = sr_airtime_donor_ul;
            instance_struct.direct_airtime_ul_iab = direct_airtime_iab_ul;
            instance_struct.ris_airtime_ul_iab= ris_airtime_iab_ul;
            instance_struct.sr_airtime_ul_iab = sr_airtime_iab_ul;

            instance_struct.c_iab = bh_rates_iab;
            instance_struct.c_don_tx = bh_rates_donor_tx;
            instance_struct.c_don_rx=bh_rates_donor_rx;
% 
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
    end
end