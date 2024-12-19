function [n_tp,n_cs,cs_cs_distance_matrix, cs_tp_distance_matrix,...
    cs_positions, tp_positions] = generate_cs_tp_positions(scenario,PLOT_SITE,figure_style, cache_found, cache_path)
%GENERATE_CS_TP_POSITIONS This function generates the tp and cs positions
%(and distances) according to the chosen policy and scenario

if nargin ==2
    cache_found = false;
    save_to_cache = false;
    figure_style = [];
elseif nargin==3
    cache_found = false;
    save_to_cache = false;
elseif nargin <2
    error('Not enough input arguments');
else
    save_to_cache = true;
end

% unpack scenario
v2struct(scenario.site);
clear size;
rng(scenario.rng_seed);

site_area = site_height*site_width;

max_n_cs = max_pregen_cs;
max_n_tp = max_pregen_tp;

switch generation_policy
    case 'uniform'
        n_cs = uniform_n_cs;
        n_tp = uniform_n_tp;
    case 'poisson'
        n_cs = poissrnd(cs_density*site_area);
        n_tp = poissrnd(tp_density*site_area);
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
    
    switch site_shape
        case 'hexagonal'
            % first check if width equals height, otherwise, since ethe
            % hexagon is expected to have equal sides, some parts of it
            % might fall outside of the planning area
            assert(site_width == site_height, 'width must equal height, otherwise, since the hexagon is expected to have equal sides, some parts of it might fall outside of the planning area');
            % we build an hexagon contained in the rectangular area
            % in particualar, we list the vertices counterclock-wise
            % starting from the lower left vertex
            site_polygon = nsidedpoly(6,'Center',[site_width/2 site_width/2],'SideLength',site_width/2);
            
            %then we filter the points outside the hexagon using the
            %rejection method
            mask = inpolygon(cs_positions(:,1), cs_positions(:,2), site_polygon.Vertices(:,1), site_polygon.Vertices(:,2));
            cs_positions = cs_positions(mask,:);
            mask = inpolygon(tp_positions(:,1), tp_positions(:,2), site_polygon.Vertices(:,1), site_polygon.Vertices(:,2));
            tp_positions = tp_positions(mask,:);
            
            % finally we check if the pre-gen positions could provide enough
            % samples after the rejection method
            assert((size(cs_positions,1) >= n_cs & size(tp_positions,1) >= n_tp),...
                'Not enough samples have survived the rejection method. Increase scenario.max_pregen{cs,tp}');
            
            % if donor is fixed, we add a new cs site at the
            % leftmost vertex of the hexagon
            if fixed_donor_position
                cs_positions = [cs_positions(1:n_cs,:); 0 site_width/2; cs_positions(n_cs+1:end,:)];
                n_cs = n_cs + 1;
            end
        case 'rectangular'
            % do nothing
        otherwise
            error('Unrecognized site shape');
    end
    
    %assert((size(cs_positions,1) >= n_cs & size(tp_positions,1) >= n_tp), 'Number of CS or TP higher than maximum. In generateInstance');
    tp_positions = tp_positions(1:n_tp,:);
    if ~ris_on_buildings
        cs_positions = cs_positions(1:n_cs,:);
    end
    
    if fakeris
        %add an additional ris, which will be the fake one, it's position (0,0)
        n_cs = n_cs + 1;
        %cs_positions = [cs_positions; [0 0]];
        cs_positions = [[0 0]; cs_positions];
        %I've moved the fake RIS to the first position in the matrix
        %otherwise it would be lost among the extra CSs.
    end
    
    
    if PLOT_SITE
        site_scatter = figure();
        %grid on;
        hold on;
        grid on;
        scatter(cs_positions(:,1),cs_positions(:,2),50, 'o', 'filled');
        scatter(tp_positions(:,1),tp_positions(:,2),50,'d','filled');
        legend_cells={'Construction Sites', 'Test Points'};
        if ~strcmp(site_shape, 'rectangular')
            plot(site_polygon);
            legend_cells{end+1} = 'Site shape';
        end
        legend(legend_cells);
    end
    
    if has_buildings && PLOT_SITE
        for b = 1:size(build_descr,1)
            %draw building
            rectangle('position', build_descr(b,:), 'FaceColor', [0.4660 0.6740 0.1880]	);
        end
    end
    %sdf(figure_style);
    if PLOT_SITE, sdf(figure_style); end
    %each element is the distance between two CSs or CS-TP
    cs_cs_distance_matrix = squareform(pdist(cs_positions));
    cs_tp_distance_matrix = pdist2(cs_positions, tp_positions);
    
    if save_to_cache
        save(cache_path, 'cs_positions','tp_positions',...
            'cs_cs_distance_matrix', 'cs_tp_distance_matrix','-append');
    end
    
else
    load(cache_path, 'cs_positions','tp_positions',...
        'cs_cs_distance_matrix', 'cs_tp_distance_matrix');
end

end

