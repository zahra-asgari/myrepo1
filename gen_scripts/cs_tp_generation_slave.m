%% cs and tp generation
site_area = scenario.site_height*scenario.site_width;

max_n_cs = 144;
max_n_tp = 1000;

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
