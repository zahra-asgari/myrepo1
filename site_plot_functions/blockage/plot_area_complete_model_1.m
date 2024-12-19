%% init
clear all;
addpath('utils/','cache/','scenarios/');
BUILDINGS = 1;
THREED = 1;
SAVE_PICS = 0;
BH_SD = 1;
export_style = 'Scenario';
% sim_folder = 'avg_100/';
% sim_folder = 'extra_100/';
% sim_folder = 'demand_campaign_avg/';
sim_folder = 'demand_campaign_peak/';
% model_name = 'iab_ris_fixedDonor_fakeRis_blockageModel_sumrate';
% model_name = 'iab_ris_fixedDonor_fakeRis_blockageModel_sumextra';
model_name = 'peak_complete_fixedDonor_blockageModel_sum_mean';
% model_name = 'complete_fixedDonor_blockageModel_sum_mean';
scenario_struct = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel();
folder_names_root = 'hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel';
%% open results folder and list files curresponding to the model
directories = dir(['solved_instances/' sim_folder folder_names_root '*']);
n_dir = numel(directories);
if BUILDINGS
    load('Blockage_Data/Milan_Buildings_5.mat');
    bl.Buildings = Buildings;
    bl.max_side = max_side;
end
%nat sort forlder such that the are sorted in increasing parameter
%variations
dir_name_list = {directories.name};
dir_name_list = natsort(dir_name_list, '\d+\.?\d*');

figure_style = 'Polimi-ppt';
%% execute some data processing for each folder, over all the runs in the folder

solved_count    = zeros(n_dir,1); % how many solved instances for scenario, useful for mean calculation, under half shadow the plot
% for di = 1:numel(dir_name_list)
for di=61:61

    %enter solution folders and get all the solved .mfiles
    disp(['Processing ' dir_name_list{di}]);
    solutions = dir(['solved_instances/' sim_folder dir_name_list{di} '/solutions/' model_name '*.m']);
    [~,sortidx]=natsort({solutions.name});
    solutions = solutions(sortidx);

    if numel(solutions) < 20
        disp([dir_name_list{di} ' has ' num2str(20-numel(solutions)) ' unsolved instances']);
        if numel(solutions) == 0

            continue;

        end
    end
    solved_count(di) = numel(solutions);


    %for each solution...
    for sol=1:numel(solutions)
        %for sol=14:14
        %run the solution
        run([solutions(sol).folder '/' solutions(sol).name]);

        %load needed variables from the curresponding .mat file
        data_name = split(solutions(sol).name, '_'); %split the string
        model_title = data_name{end -1};

        if strcmp(model_title,'sumrate')
            model_title = 'MTF';
        elseif strcmp(model_title,'sumextra')
            model_title = 'PTF';
        end
        data_name = data_name{end}; %get the run
        data_name = data_name(4:end-2); %truncate .m and 'run' to get the .mat data name
        %                 if ismember(str2double(data_name),[52,57,59,66,74,99])
        % set of instances with intersection bug (fixed)
        % if ismember(str2double(data_name),[10])
        %     %set of instances with found malformed polygons
        %     % if ismember(str2double(data_name),[29,36,56,83])
        % else
        %     continue;
        % end

        % if ismember(str2double(data_name),[52])
        if ismember(str2double(data_name),[23])
        else
            continue;
        end

        site_cache_id = DataHash([DataHash(scenario_struct.site) num2str(data_name)]); % hash is salted with rng_seed, since the site data is generated randomly
        radio_cache_id = DataHash([DataHash(scenario_struct.radio) site_cache_id]);
        site_cache_path = ['cache/' site_cache_id '.mat'];
        radio_cache_path = ['cache/' radio_cache_id '.mat'];
        % site_cache_path = ['cache/20_instances/' site_cache_id '.mat'];
        % radio_cache_path = ['cache/20_instances/' radio_cache_id '.mat'];
        if isfile(site_cache_path)
            load(site_cache_path,...
                'cs_positions','tp_positions','cs_tp_distance_matrix','cs_cs_distance_matrix','smallest_angles','n_cs','n_tp','scenario');
        else
            disp("Site cache not found!!")
            continue;

        end
        if isfile(radio_cache_path)
            load(radio_cache_path,...
                'bh_rates','avg_rates','sd_rates','state_rates','state_probs','sd_better_mask');
            time_ratio.DL.ris = sum(state_probs.DL.*sd_better_mask.DL.ris,4);
            time_ratio.UL.ris = sum(state_probs.UL.*sd_better_mask.UL.ris,4);
            time_ratio.DL.ncr = sum(state_probs.DL.*sd_better_mask.DL.ncr,4);
            time_ratio.UL.ncr = sum(state_probs.UL.*sd_better_mask.UL.ncr,4);
        else
            disp("Site cache not found!!")
            continue;

        end



        %sites
        [ue,bs,sd,sdt] = ind2sub(size(x),find(x)); %find all SDs involved in an access connection x
        sd_counter = zeros(n_cs,1);
        sd_useless = [];
        for ttt = 1:n_tp
            if sdt(ttt) == 1 && sd(ttt) ~= 1
                if all([time_ratio.DL.ris(ue(ttt),bs(ttt),sd(ttt)) time_ratio.UL.ris(ue(ttt),bs(ttt),sd(ttt))]==0)
                    sd_counter(sd(ttt)) = sd_counter(sd(ttt)) +1;
                end
            elseif sdt(ttt) == 2
                if all([time_ratio.DL.ncr(ue(ttt),bs(ttt),sd(ttt)) time_ratio.UL.ncr(ue(ttt),bs(ttt),sd(ttt))]==0)
                    sd_counter(sd(ttt)) = sd_counter(sd(ttt)) +1;
                end
            end
        end
        for sdb=1:n_cs
            if sd_counter(sdb)
                a = find(sd == sdb);
                if numel(a) == sd_counter(sdb)
                    disp(['useless SD ' num2str(sdb)])
                    sd_useless = [sd_useless; sdb];
                end
            end
        end
        [tx_dl,rx_dl] = find(f_dl>1);
        ris_idx = setdiff(unique(sd(sdt==1)),[1; sd_useless]);
        ncr_idx = setdiff(unique(sd(sdt==2)),sd_useless);
        iab_idx = unique([tx_dl rx_dl]);
        % if isempty(ncr_idx)
        %     continue;
        % end


        used_iab = iab_idx;
        used_ris = ris_idx;
        used_ncr = ncr_idx;
        % if or(isempty(used_ris),isempty(used_ncr))
        %     continue;
        % end
        if SAVE_PICS
            site_scatter = figure('visible','off');
        else
            site_scatter = figure();
            ax = gca;
            ax.Clipping = 'off';
        end
        hold on;
        grid on;

        xlabel('UTM Grid Zone 32T X Coordinates [m]','FontSize',16);
        ylabel('UTM Grid Zone 32T Y Coordinates [m]','FontSize',16);
        axis equal;
        %                 title(['Hexagonal Cell, Instance ' data_name ', Budget ' num2str(scenario_struct.sim.budget(di)) ', ' model_title ' model']);
        % title(['Instance ' data_name ', Budget ' num2str(scenario_struct.sim.budget(di)) ', ' model_title]);
        title(['Instance ' data_name ', Demand ' num2str(scenario_struct.sim.R_dir_min(di)) ', ' model_title]);
        center = [scenario.site.site_width/2 scenario.site.site_width/2];
        if BUILDINGS
            center = [cs_positions(end,1) + scenario.site.site_width/2 cs_positions(end,2)];
            tempBuildings = pruneBuildings(scenario.site.site_width,bl,center);
        end
        cs_dx = 2; cs_dy = 2; % displacement so the text does not overlay the data points
        cs_id= (1:n_cs)';
        ue_id= 'A':'Z';
        ue_id = ue_id(1:n_tp)';
        %cs_id_handle = text(cs_positions(2:end,1)+cs_dx, cs_positions(2:end,2)+cs_dy, cellstr(num2str(cs_id(2:end))));
        %used_cs = used_iab + used_ris + y_don;
        %                 for ucs=2:n_cs
        %                     if used_cs(ucs) == 0
        %                         cs_id_handle(ucs-1).Visible = "off";
        %                     end
        %                 end
        %text(tp_positions(1:end,1)+cs_dx, tp_positions(1:end,2)+cs_dy, ue_id(1:end));
        marker_size = 100;
        if THREED

            %scatter3(cs_positions(2:end,1),cs_positions(2:end,2),zeros([size(cs_positions,1)-1,1]),80,'xk');
            scatter3(cs_positions(y_don == 1,1),cs_positions(y_don == 1,2),scenario_struct.radio.donor_height,marker_size,'og','filled');
            plot3([cs_positions(y_don == 1,1) cs_positions(y_don == 1,1)],[cs_positions(y_don == 1,2) cs_positions(y_don == 1,2)],[0 scenario_struct.radio.donor_height], 'Color','k','HandleVisibility','off');
            scatter3(cs_positions(setdiff(used_iab,n_cs),1),cs_positions(setdiff(used_iab,n_cs),2),repmat(scenario_struct.radio.iab_height,[size(cs_positions(setdiff(used_iab,n_cs)),1),1]),marker_size,'^b','filled');
            plot3([cs_positions(setdiff(used_iab,n_cs),1) cs_positions(setdiff(used_iab,n_cs),1)],[cs_positions(setdiff(used_iab,n_cs),2) cs_positions(setdiff(used_iab,n_cs),2)],[0 scenario_struct.radio.iab_height], 'Color','k','HandleVisibility','off');
            scatter3(cs_positions(used_ris,1),cs_positions(used_ris,2),repmat(scenario_struct.radio.ris_height,[size(cs_positions(used_ris),1),1]),marker_size,'sm','filled');
            scatter3(cs_positions(used_ncr,1),cs_positions(used_ncr,2),repmat(scenario_struct.radio.ris_height,[size(cs_positions(used_ncr),1),1]),marker_size,'pentagramc','filled');

            %                     plot3([cs_positions(used_ris,1) cs_positions(used_ris,1)],[cs_positions(used_ris,2) cs_positions(used_ris,2)],[0 scenario_struct.radio.ris_height], 'Color','k','HandleVisibility','off');
            scatter3(tp_positions(:,1),tp_positions(:,2),repmat(scenario_struct.radio.ue_height,[size(tp_positions,1),1]),marker_size,'dr','filled');
            xlim([center(1)-scenario.site.site_width/2-20, center(1) + scenario.site.site_width/2+20]);
            ylim([center(2)-scenario.site.site_width/2-20, center(2) + scenario.site.site_width/2+20]);
            %                     xlim([517608,517948])
            %                     ylim([5033630,5033930])
            zlim([0 Inf]);
            %                     view([0 45]);
        else
            %scatter(cs_positions(2:end,1),cs_positions(2:end,2), 80,'xk');
            scatter(tp_positions(:,1),tp_positions(:,2),marker_size,'dr','filled');
            scatter(cs_positions(y_don == 1,1),cs_positions(y_don == 1,2),marker_size,'og', 'filled');
            scatter(cs_positions(setdiff(used_iab,n_cs),1),cs_positions(setdiff(used_iab,n_cs),2),marker_size,'^b', 'filled');
            scatter(cs_positions(used_ris,1),cs_positions(used_ris,2),marker_size,'sm', 'filled');
        end
        %used_ris(1) = false; %remove fake RIS
        %populated sites



        %legend_cells={'Construction Sites', 'Donors', 'IAB nodes', 'RIS', 'Test Points'};
        legend_cells={'IAB Donor', 'IAB Node', 'RIS', 'NCR', 'Test Point'};

        if ~strcmp(scenario.site.site_shape, 'rectangular')
            site_polygon = nsidedpoly(6,'Center',center,'SideLength',scenario.site.site_width/2);
            plot(site_polygon,'FaceColor',[0, 0.4470, 0.7410],'FaceAlpha',0.15,'EdgeColor',[0.8627 0.8627 0.8627]);
            legend_cells{end+1} = 'Site shape';
        end
        if BUILDINGS

            for b=1:numel(tempBuildings)

                %                         pv = [tempBuildings(b).geometry.coordinates; tempBuildings(b).geometry.coordinates(1,:)];
                if b==24
                    disp('')
                end
                if THREED
                    pv = tempBuildings(b).geometry.coordinates;
                    h = plotsolid(pv,tempBuildings(b).properties.UN_VOL_AV);
                    h.f.HandleVisibility = 'off';
                    h.c.HandleVisibility = 'off';
                    h.w.HandleVisibility = 'off';
                else
                    pv = reformat_building(tempBuildings(b).geometry.coordinates,'no-loop');
                    h = plot(polyshape(pv));
                    hold on;
                    h.FaceAlpha = 1;
                    h.FaceColor = [0.8627 0.8627 0.8627];
                end
            end
            %light_handle = lightangle(200.72,64.75);
        end
        l = legend(legend_cells,'Position',[0.735460073984641,0.630704372175155,0.218749995459803,0.249255945285162],'FontSize',14);

        %% backhaul links
        first = 1;
        for c=1:n_cs
            for d=1:n_cs
                if ismember([c d],[tx_dl rx_dl],'rows')

                    if first
                        if THREED
                            if c==n_cs
                                bh = plot3([cs_positions(c,1) cs_positions(d,1)],[cs_positions(c,2) cs_positions(d,2)],[scenario_struct.radio.donor_height scenario_struct.radio.iab_height], 'Color', 'b', 'DisplayName', 'BH Link');
                            else
                                bh = plot3([cs_positions(c,1) cs_positions(d,1)],[cs_positions(c,2) cs_positions(d,2)],[scenario_struct.radio.iab_height scenario_struct.radio.iab_height], 'Color', 'b', 'DisplayName', 'BH Link');
                            end
                        else
                            bh = plot([cs_positions(c,1) cs_positions(d,1)],[cs_positions(c,2) cs_positions(d,2)], 'Color', 'b', 'DisplayName', 'BH Link');
                        end
                        first = 0;
                    else
                        if THREED
                            if c==n_cs
                                bh = plot3([cs_positions(c,1) cs_positions(d,1)],[cs_positions(c,2) cs_positions(d,2)],[scenario_struct.radio.donor_height scenario_struct.radio.iab_height], 'Color', 'b', 'HandleVisibility','off');
                            else
                                bh = plot3([cs_positions(c,1) cs_positions(d,1)],[cs_positions(c,2) cs_positions(d,2)],[scenario_struct.radio.iab_height scenario_struct.radio.iab_height], 'Color', 'b', 'HandleVisibility','off');
                            end
                        else
                            bh = plot([cs_positions(c,1) cs_positions(d,1)],[cs_positions(c,2) cs_positions(d,2)], 'Color', 'b', 'HandleVisibility','off');
                        end
                    end

                end

            end
        end

        %% access links

        first = 1;
        first_r = 1;
        for c=1:n_cs
            for t=1:n_tp
                for r=1:n_cs
                    if any(x(t,c,r,:) == 1)
                        if first
                            if THREED
                                if c==n_cs

                                    dir1 = plot3([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)],[scenario_struct.radio.donor_height scenario_struct.radio.ue_height], 'r-.', 'DisplayName', 'Direct Link');
                                    if r~=1 && ismember(r,[used_ris;used_ncr])
                                        acc1 = plot3([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)],[scenario_struct.radio.ris_height scenario_struct.radio.ue_height], 'k:', 'DisplayName', 'Reflected Link');
                                        first_r = 0;
                                        if BH_SD
                                            acc2 = plot3([cs_positions(c,1) cs_positions(r,1)],[cs_positions(c,2) cs_positions(r,2)],[scenario_struct.radio.donor_height scenario_struct.radio.ris_height], 'k:', 'HandleVisibility','off');
                                        end
                                    end
                                else
                                    dir1 = plot3([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)],[scenario_struct.radio.iab_height scenario_struct.radio.ue_height], 'r-.', 'DisplayName', 'Direct Link');
                                    if r~=1 && ismember(r,[used_ris;used_ncr])
                                        acc1 = plot3([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)],[scenario_struct.radio.ris_height scenario_struct.radio.ue_height], 'k:', 'DisplayName', 'Reflected Link');
                                        first_r = 0;
                                        if BH_SD
                                            acc2 = plot3([cs_positions(c,1) cs_positions(r,1)],[cs_positions(c,2) cs_positions(r,2)],[scenario_struct.radio.iab_height scenario_struct.radio.ris_height], 'k:', 'HandleVisibility','off');
                                        end
                                    end
                                end
                            else
                                dir1 = plot([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)], 'r-.', 'DisplayName', 'Direct Link');
                                if r~=1 && ismember(r,[used_ris;used_ncr])
                                    acc1 = plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], 'k:', 'DisplayName', 'Reflected Link');
                                    if BH_SD
                                        acc2 = plot([cs_positions(c,1) cs_positions(r,1)],[cs_positions(c,2) cs_positions(r,2)], 'k:', 'HandleVisibility','off');
                                    end
                                end
                            end
                            first=0;
                        else
                            if THREED
                                if c==n_cs

                                    dir1 = plot3([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)],[scenario_struct.radio.donor_height scenario_struct.radio.ue_height], 'r-.', 'HandleVisibility','off');
                                    if r~=1 && ismember(r,[used_ris;used_ncr])
                                        if first_r
                                            acc1 = plot3([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)],[scenario_struct.radio.ris_height scenario_struct.radio.ue_height], 'k:', 'DisplayName', 'Reflected Link');
                                            first_r = 0;
                                        else
                                            acc1 = plot3([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)],[scenario_struct.radio.ris_height scenario_struct.radio.ue_height], 'k:', 'HandleVisibility','off');
                                        end
                                        if BH_SD
                                            acc2 = plot3([cs_positions(c,1) cs_positions(r,1)],[cs_positions(c,2) cs_positions(r,2)],[scenario_struct.radio.donor_height scenario_struct.radio.ris_height], 'k:', 'HandleVisibility','off');
                                        end
                                    end
                                else
                                    dir1 = plot3([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)],[scenario_struct.radio.iab_height scenario_struct.radio.ue_height], 'r-.', 'HandleVisibility','off');
                                    if r~=1 && ismember(r,[used_ris;used_ncr])
                                        if first_r
                                            acc1 = plot3([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)],[scenario_struct.radio.ris_height scenario_struct.radio.ue_height], 'k:', 'DisplayName', 'Reflected Link');
                                            first_r = 0;
                                        else
                                            acc1 = plot3([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)],[scenario_struct.radio.ris_height scenario_struct.radio.ue_height], 'k:', 'HandleVisibility','off');
                                        end
                                        if BH_SD
                                            acc2 = plot3([cs_positions(c,1) cs_positions(r,1)],[cs_positions(c,2) cs_positions(r,2)],[scenario_struct.radio.iab_height scenario_struct.radio.ris_height], 'k:', 'HandleVisibility','off');
                                        end
                                    end
                                end
                            else
                                dir1= plot([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)], 'r-.',  'HandleVisibility','off');
                                if r~=1 && ismember(r,[used_ris;used_ncr])
                                    acc1=plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], 'k:', 'HandleVisibility','off');
                                    if BH_SD
                                        acc2=plot([cs_positions(c,1) cs_positions(r,1)],[cs_positions(c,2) cs_positions(r,2)], 'k:', 'HandleVisibility','off');
                                    end
                                end
                            end
                        end

                    end
                end
            end
        end
        %                 set(l,'visible','off');
        %                 if exist('ax','var')
        %                     ax(end+1) = gca;
        %                 else
        %                     ax(1) = gca;
        %                 end



    end
    sdf(export_style);
    if SAVE_PICS
        saveas(gcf,['site_plot_functions/blockage/pictures_peak_demand_analysis/' num2str(scenario_struct.sim.R_dir_min(di)) '.png']);
    end
    drawnow
    % view([45 35]);

end

% ax(1) = '';
% save('site_plot_functions/blockage/axis_list.mat','ax');

