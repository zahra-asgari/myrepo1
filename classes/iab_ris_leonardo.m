classdef iab_ris_leonardo < instance
    %IAB_RIS_MULTI_INSTANCE Summary of this class goes here
    %   Detailed explanation goes here
    methods
        function obj = iab_ris_leonardo(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed)
            %IAB_RIS_MULTI_INSTANCE Construct an instance of this class
            obj@instance(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed);
        end

        function [instance_struct, workspace_struct] = generate_inner(obj)
            init;

            %% load the subarea data
            subarea_folder = 'V_4/leonardo_subareas/';
            subarea_name = 'golgi_data';
            subarea_filename = [subarea_folder subarea_name];

            load(subarea_filename);
            
            % preprocess block mask
            bh_block_mask = ~bh_block_mask;
            bh_block_mask = bh_block_mask - diag(diag(bh_block_mask));

            %% positions
            %             cs_positions = [bs_positions; ris_positions];
            %             tp_positions = tp_filt;
            %
            %             n_cs = size(cs_positions,1);
            %             n_

            n_bs = size(bs_positions,1);
            n_ris = size(ris_positions,1);
            n_tp = size(tp_filt,1);
            tp_positions = tp_filt;
            tp_bs_distances = pdist2(tp_positions, bs_positions);
            tp_ris_distances = pdist2(tp_positions, ris_positions);

            % link length
            src_mean_linlen = zeros(n_tp,n_bs,n_ris);
            for t=1:n_tp
                for b=1:n_bs
                    for r=1:n_ris
                        src_mean_linlen(t,b,r) = 0.5*(tp_bs_distances(t,b) + tp_ris_distances(t,r));
                    end
                end
            end

            % angular separation
            src_angsep = zeros(n_tp,n_bs,n_ris);
            for t=1:n_tp
                offset = tp_positions(t,:);
                for b=1:n_bs
                    relative_bs_pos = bs_positions(b,:) - offset;
                    bs_angle = atan2d(relative_bs_pos(2),relative_bs_pos(1));
                    for r=1:n_ris
                        % compute angular separation as seen by tp
                        relative_ris_position = ris_positions(r,:) - offset;
                        ris_angle = atan2d(relative_ris_position(2),relative_ris_position(1));
                        if bs_angle >= ris_angle
                            src_angsep(t,b,r) = bs_angle-ris_angle;
                        else
                            src_angsep(t,b,r) = ris_angle-bs_angle;
                        end
                    end
                end
            end
            src_angsep(src_angsep > 180) = src_angsep(src_angsep > 180) - 180;

            %% Rates computation


            direct_airtime = repmat(obj.scenario.R_dir_min./direct_rates, 1,1,n_ris);
            reflected_airtime = (obj.scenario.R_dir_min*obj.scenario.rate_ratio)./ris_rates;
            max_airtime = max(direct_airtime, reflected_airtime);

            max_airtime(max_airtime == Inf) = 0;
            reflected_airtime(reflected_airtime == Inf) = 0;

            bh_rates(bh_rates == 0) = 1;

            %% generate instance structure
            instance_struct.n_bs=n_bs;
            instance_struct.n_ris = n_ris;
            instance_struct.n_tp=n_tp;

            instance_struct.donor_id = donor_id;

            instance_struct.donor_price = donor_price;
            instance_struct.ris_price = ris_price;
            instance_struct.iab_price = iab_price;
            instance_struct.budget = budget;

            instance_struct.bh_p_mask = bh_block_mask;
            instance_struct.src_p_mask = ~src_block_mask;

            instance_struct.angsep = src_angsep;
            instance_struct.linlen = src_mean_linlen;

            instance_struct.C_bh = bh_rates;
            instance_struct.min_rate = R_dir_min;
            instance_struct.max_airtime = max_airtime;
            instance_struct.ris_airtime = reflected_airtime;

            instance_struct.angsep_norm = 180;
            instance_struct.linlen_norm = max(src_mean_linlen(:));
            instance_struct.angsep_emphasis = OF_weight;

            instance_struct.output_filename = [num2str(obj.dataname) '.m'];

            %% generate workspace structure
            workspace_struct=ws2struct();

        end

        function plot_solution(obj)
            if ~obj.is_solved
                warning('Planning instance not yet solved, cannot plot')
            else
            plot_iab_ris_multi_leonardo(obj.workspace_struct,obj.solution_struct,obj.FIGURE_EXPORT_STYLE);
            end
        end
    end
end
