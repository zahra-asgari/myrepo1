function [instance] = generateInstanceAdversarialSlaveV2(scenario, instance_folder, dataname, rng_seed,solution)
%generateInstances this function generates a random instance to be later
%simulated
%
% [instance] = generateInstances()
%
% $Author: Eugenio Moro $	$Date: 2020/11/30 16:29:44 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020
addpath('utils', 'radio', 'gen_scripts');
%these are local options that should be set to 1 only for debug
PLOT_SITE = 0;
PLOT_DISTANCE_STATISTICS = 0;


%unpack scenario into workspace
v2struct(scenario);
clear size;
rng(rng_seed);


%% check in databank if an instance of this particular scenario was already generated and saved in the cache
% we do this by using md5 hashes of the entire struct, since the name is
% not relaible enough

scenario_hash = DataHash(scenario);
cache_folder = 'cache/instances/';
cache_path = strcat(cache_folder,scenario_hash);
cache_found = isfile([cache_path '.mat']);

if ~cache_found
    save(cache_path, 'name');
    disp('cache not found');
end

%% cs and tp generation
site_area = scenario.site_height*scenario.site_width;

max_n_cs = max_pregen_cs;
max_n_tp = max_pregen_tp;

n_tp = max_n_tp;

switch scenario.generation_policy
    case 'uniform'
        n_cs = scenario.uniform_n_cs;
    case 'poisson'
        n_cs = poissrnd(scenario.cs_density*site_area);
        n_tp = poissrnd(scenario.tp_density*site_area);
    case 'adhoc'
        
    otherwise
        error('Unrecognized generation policy in instance generation')
end

if ~cache_found
    
    %this is for repeatability, these random number banks will be always the
    %same independently of the actual number of tp and cs if the rnd seed is
    %kept consistent
    rand_c_x = rand(max_n_cs,1);
    rand_c_y = rand(max_n_cs,1);
    rand_t_x = rand(max_n_tp,1);
    rand_t_y = rand(max_n_tp,1);
    
    
    
    assert(grid_factor <= 4, 'Grid factors larger than 4 not supported. In generateInstance');
    %assert(mod(n_cs, grid_factor^2) == 0 && mod(n_tp, grid_factor^2) == 0,...
    %'n_tp or n_cs not multiple of grid factor squared. In generateInstance');
    assert(mod(site_height,2)==0 && mod(site_width,2)==0,...
        'Site dimensions not multiple of grid factor. In generateInstance');
    
    if ris_on_buildings
        cs_positions = [];
        cs_fixed_orientation = [];
        % put cs with building_surface_sampling spacing on building surfaces
        % which are not on the edge of the map, basically any vertex which doea
        % not touch the edges are fine
        for b = 1:size(build_descr,1)
            % left vertical segment
            if build_descr(b,1) > 0
                yy=linspace(build_descr(b,2),build_descr(b,2)+build_descr(b,4),...
                    (build_descr(b,4))/building_surface_sampling)';
                cs_positions = [cs_positions; [build_descr(b,1)*ones(length(yy),1) yy]];
                cs_fixed_orientation = [cs_fixed_orientation; 180*ones(length(yy),1)];
            end
            
            %right vertical segment
            if build_descr(b,1)+build_descr(b,3) < site_width
                yy=linspace(build_descr(b,2),build_descr(b,2)+build_descr(b,4),...
                    (build_descr(b,4)/building_surface_sampling))';
                cs_positions = [cs_positions; [(build_descr(b,1)+build_descr(b,3))*ones(length(yy),1) yy]];
                cs_fixed_orientation = [cs_fixed_orientation; zeros(length(yy),1)];
            end
            
            %lower horizontal segment
            if build_descr(b,2) > 0
                xx=linspace(build_descr(b,1),build_descr(b,1)+build_descr(b,3),...
                    abs(build_descr(b,3)/building_surface_sampling))';
                cs_positions = [cs_positions; [xx build_descr(b,2)*ones(length(xx),1)]];
                cs_fixed_orientation = [cs_fixed_orientation; 270*ones(length(xx),1)];
            end
            
            %upper horizontal segment
            if build_descr(b,2) + build_descr(b,4) < site_height
                xx=linspace(build_descr(b,1),build_descr(b,1)+build_descr(b,3),...
                    (build_descr(b,3)/building_surface_sampling))';
                cs_positions = [cs_positions; [xx (build_descr(b,2)+build_descr(b,4))*ones(length(xx),1)]];
                cs_fixed_orientation = [cs_fixed_orientation; 90*ones(length(xx),1)];
            end
            
        end
        n_cs = size(cs_positions,1);
    else
        offsets_x = reshape(repmat(0:site_width/grid_factor:site_width-site_width/grid_factor,max_n_cs/grid_factor,1)',max_n_cs,1);
        %offsets_y = reshape(repmat(0:site_height/grid_factor:site_height-site_height/grid_factor,max_n_cs/grid_factor,1),max_n_cs,1);
        offsets_y = repmat(reshape(repmat((0:site_height/grid_factor:site_height-site_height/grid_factor),grid_factor,1),grid_factor^2,1),max_n_cs/(grid_factor^2),1);
        xpos = offsets_x + (site_width/grid_factor).*rand_c_x(1:max_n_cs);
        ypos = offsets_y + (site_height/grid_factor).*rand_c_y(1:max_n_cs);
        cs_positions = [xpos ypos];
        assert((size(cs_positions,1) >= n_cs), 'Number of CS or TP higher than maximum. In generateInstance')
        
    end
    
    offsets_x = reshape(repmat(0:site_width/grid_factor:site_width-site_width/grid_factor,max_n_tp/grid_factor,1)',max_n_tp,1);
    %offsets_y = reshape(repmat(0:site_height/grid_factor:site_height-site_height/grid_factor,max_n_tp/grid_factor,1),max_n_tp,1);
    offsets_y = repmat(reshape(repmat((0:site_height/grid_factor:site_height-site_height/grid_factor),grid_factor,1),grid_factor^2,1),max_n_tp/(grid_factor^2),1);
    xpos = offsets_x + (site_width/grid_factor).*rand_t_x(1:max_n_tp);
    ypos = offsets_y + (site_height/grid_factor).*rand_t_y(1:max_n_tp);
    tp_positions = [xpos ypos];
    assert((size(cs_positions,1) >= n_cs & size(tp_positions,1) >= n_tp), 'Number of CS or TP higher than maximum. In generateInstance')
    
    
    % if there are buildigs we need to filter the data bank such that the
    % positions of cs and tp are all outside of the buildings
    if has_buildings
        cs_positions = position_building_filter(cs_positions,build_descr);
        tp_positions = position_building_filter(tp_positions,build_descr);
    end
    
    %assert((size(cs_positions,1) >= n_cs & size(tp_positions,1) >= n_tp), 'Number of CS or TP higher than maximum. In generateInstance');
    tp_positions = tp_positions(1:n_tp,:);
    if ~ris_on_buildings
        cs_positions = cs_positions(1:n_cs,:);
    end
    
    
    
    if PLOT_SITE
        site_scatter = figure();
        %grid on;
        hold on;
        grid on;
        scatter(cs_positions(:,1),cs_positions(:,2),50, 'o', 'filled');
        scatter(tp_positions(:,1),tp_positions(:,2),50,'d','filled');
        legend('Construction Sites', 'Test Points');
    end
    
    if has_buildings && PLOT_SITE
        for b = 1:size(build_descr,1)
            %draw building
            rectangle('position', build_descr(b,:), 'FaceColor', [0.4660 0.6740 0.1880]	);
        end
    end
    
    %each element is the distance between two CSs or CS-TP
    cs_cs_distance_matrix = squareform(pdist(cs_positions));
    cs_tp_distance_matrix = pdist2(cs_positions, tp_positions);
    
    save(cache_path, 'cs_positions','tp_positions',...
        'cs_cs_distance_matrix', 'cs_tp_distance_matrix','-append');
    
else
    load(cache_path, 'cs_positions','tp_positions',...
        'cs_cs_distance_matrix', 'cs_tp_distance_matrix');
end


active_donor_cs = sum(solution.y_don);
active_ris_cs = sum(solution.y_ris);

donor_cs = zeros(active_donor_cs,2);
ris_cs = zeros(active_ris_cs,2);

donor_cs_map = zeros(active_donor_cs,1);
ris_cs_map = zeros(active_ris_cs,1);

i_don = 1;
i_ris = 1;

for c = 1:n_cs
    if solution.y_don(c) == 1
        donor_cs(i_don,:) = cs_positions(c,:);
        donor_cs_map(i_don) = c;
        i_don = i_don + 1;
    elseif solution.y_ris(c) == 1
        ris_cs(i_ris,:) = cs_positions(c,:);
        ris_cs_map(i_ris) = c;
        i_ris = i_ris + 1;
    end
end

bs_tp_distance_matrix = pdist2(donor_cs, tp_positions);
ris_tp_distance_matrix = pdist2(ris_cs, tp_positions);

%% channels and airtime
if cache_found
    load(cache_path, 'max_airtime', 'reflected_airtime');
else
    [direct_rate,reflected_rate] =...
        channel_computation_eugenio_slave(cs_tp_distance_matrix,cs_cs_distance_matrix, scenario);
    
    direct_airtime = repmat(R_dir_min./direct_rate, 1,1,n_cs);
    reflected_airtime = (R_dir_min*rate_ratio)./reflected_rate;
    max_airtime = max(direct_airtime, reflected_airtime);
    
    
    max_airtime(max_airtime == Inf) = 0;
    reflected_airtime(reflected_airtime == Inf) = 0;
    
    % save into cache
    save(cache_path,'max_airtime','reflected_airtime','-append');
end

%% angles computation

angle_parameters_slave;

%% association mask

ris_p_mask = true(n_tp,active_donor_cs,active_ris_cs);

% prepare mask for link length
for r=1:active_ris_cs
    for d=1:active_donor_cs
        for t=1:n_tp
            ris_p_mask(t,d,r) = (bs_tp_distance_matrix(d,t) <= max_bs_tp_dist) & (ris_tp_distance_matrix(r,t) <= max_bs_tp_dist);
        end
    end
end


% % prepare mask for angles: for all tp-bs check if the angle is inside ris fov
% temp_mask = false(n_tp, active_donor_cs, active_ris_cs);
% for t=1:n_tp
%     for r=1:active_ris_cs
%         for d=1:active_donor_cs
%             % compute ris-tp angle
%             relative_tp_position = tp_positions(t,:) - ris_cs(r,:);
%             %now it is like computing the angle of a vector having coordinates relative_tp_position
%             temp_angle = angle(relative_tp_position(1) +1i*relative_tp_position(2))*180/pi; %1i is the imaginary unit
%             if temp_angle < 0
%                 temp_angle = temp_angle + 360;
%             end
%             temp_mask(t,d,r) = temp_angle >= solution.delta(ris_cs_map(r)) + max_angle_span...
%                 || temp_angle <= solution.delta(ris_cs_map(r)) - max_angle_span;
%             
%             % compute ris-bs angle
%             relative_bs_position = tp_positions(t,:) - donor_cs(d,:);
%             %now it is like computing the angle of a vector having coordinates relative_tp_position
%             temp_angle = angle(relative_bs_position(1) +1i*relative_bs_position(2))*180/pi; %1i is the imaginary unit
%             if temp_angle < 0
%                 temp_angle = temp_angle + 360;
%             end
%             temp_mask(t,d,r) = temp_mask(t,d,r) && (temp_angle >= solution.delta(donor_cs_map(d)) + max_angle_span...
%                 || temp_angle <= solution.delta(donor_cs_map(d)) - max_angle_span);
%         end
%     end
% end
%
%ris_p_mask = ris_p_mask & temp_mask;

% prepare mask for airtime

ris_p_mask = ris_p_mask & (max_airtime(t,donor_cs_map,ris_cs_map) < 1);

%% generate instance structure
%some local variables are set as transpose in the instance structure in
%order to reflect the indexing in the model
instance.n_donors=active_donor_cs;
instance.n_ris = active_ris_cs;
instance.n_tp=n_tp;

instance.acc_p_mask = ris_p_mask;
%instance.forbidden_assoc = x_history(:,donor_cs_map, ris_cs_map);

instance.max_tp = scenario.uniform_n_tp;
instance.A_max = A_max;
instance.A_min = 1;

instance.angsep = smallest_angles;


instance.output_filename = [num2str(dataname) '.m'];
%% workspace saving
save([instance_folder dataname]);

end
