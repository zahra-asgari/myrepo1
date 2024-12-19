clear;
clc;
pl=0;
pl_fsi = 0;
if pl_fsi
    first_time = 1;
end
load('Blockage_Data/sector_data.mat');
run('GLOBAL_OPTIONS.m');
addpath('utils','scenarios','WIP_functions');
scenario = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel;
city_width = max(city_poly(:,1)) - min(city_poly(:,1));
city_height = max(city_poly(:,2)) - min(city_poly(:,2));
city = polyshape(city_poly);
square_size_m = 1;
sampl_freq_wall = 0.5;
coord_x = linspace(min(city_poly(:,1)), max(city_poly(:,1)),city_width/square_size_m)';
coord_y = linspace(min(city_poly(:,2)), max(city_poly(:,2)),city_height/square_size_m)';
coord_y = flip(coord_y);
[bitmap_x, bitmap_y] = meshgrid(coord_x, coord_y);
bitmap_x = bitmap_x';
bitmap_y = bitmap_y';
vect_x = reshape(bitmap_x,[],1);
vect_y = reshape(bitmap_y,[],1);
coord = [vect_x, vect_y];
pruning_matrix = zeros(numel(vect_x),numel(sector_poly));
p_closer = Inf*ones(size(coord,1),1);
border_points = []; %coordinates of points whose circle intersects their sector boundary, must check other sectors later
for i=1:numel(sector_poly)
    if isfile('Blockage_Data/fsi_map_sampling1.mat')
        load('Blockage_Data/fsi_map_sampling1.mat');
        next_sector = max(border_points(:,3))+1;
        if i < next_sector
            continue;
        end
    end
    load(['Blockage_Data/Milan_Sector_Buildings_' num2str(i) '.mat'],'Sector_Buildings');
    % select all points in the city sample meshgrid that fall inside a
    % specific sector and save them in the matrix pruning_matrix
    %I have to check if I can remove all of the convex hull/rectangle if I
    %don't need it, or use it for the coordinate shift for the center of
    %the hexagons around the sector
    sect_bound = polyshape(sector_poly{i});
    [x_lim,y_lim] = boundingbox(sect_bound);
    rect_coord = [x_lim', y_lim'];
    [grid_x, grid_y] = meshgrid(rect_coord(:,1), rect_coord(:,2));
    rect_x = reshape(grid_x,[],1);
    rect_y = reshape(grid_y,[],1);
    rect_hull = convhull([rect_x,rect_y]);
    rect = polyshape([rect_x(rect_hull),rect_y(rect_hull)]);
    pruning_matrix(:,i) = inpolygon(coord(:,1),coord(:,2),rect.Vertices(:,1),rect.Vertices(:,2));
    coord_indeces = find(pruning_matrix(:,i));
    if pl_fsi
        plot(city,'FaceAlpha',0,'LineWidth',3,'EdgeColor','g');
        axis equal
        hold on;
        plot(sect_bound)
    end
    pruned_coord = coord.*pruning_matrix(:,i);
    pruned_coord = pruned_coord(~all(pruned_coord == 0, 2),:);
    temp_p_closer = p_closer(coord_indeces);
    pv = [];
    n = numel(Sector_Buildings);
    for b=1:n
        xy = reformat_building(Sector_Buildings(b).geometry.coordinates,'loop');
        pv=[pv;xy;NaN NaN];
    end
    fsi_obstacles = polyshape(pv);
    streets = subtract(sect_bound,fsi_obstacles);
    streets = intersect(streets,city);
    beehive = polyshape.empty;
    bh_vert = [];
    reference_point = coord(1,:);
    center = reference_point;
    odd = 1;
    x_movement = 3/2*(scenario.site.site_width);
    y_movement = (sqrt(3)/2)*scenario.site.site_width/2;
    while intersect(nsidedpoly(6,'Center',center,'SideLength',scenario.site.site_width/2),sect_bound).NumRegions < 1
    %while not(inpolygon(center(1),center(2),rect.Vertices(:,1),rect.Vertices(:,2)))
        if center(1)<max(rect.Vertices(:,1))
            center = [center(1)+x_movement,center(2)];
        elseif odd
            odd = 0;
            center = [reference_point(1) + x_movement/2, center(2) - y_movement];
        else
            odd = 1;
            center = [reference_point(1) , center(2) - y_movement];
        end
    end
    bee_cover = 0;
    while bee_cover < area(sect_bound)
        cell_site = nsidedpoly(6,'Center',center,'SideLength',scenario.site.site_width/2);
        if  (isempty(intersect(cell_site,beehive)) || intersect(cell_site,beehive).NumRegions < 1) ...
                && intersect(cell_site,sect_bound).NumRegions > 0
            if pl_fsi
                h_box_coord = [min(cell_site.Vertices);max(cell_site.Vertices)];
                [h_grid_x, h_grid_y] = meshgrid(h_box_coord(:,1), h_box_coord(:,2));
                h_rect_x = reshape(h_grid_x,[],1);
                h_rect_y = reshape(h_grid_y,[],1);
                h_rect_hull = convhull([h_rect_x,h_rect_y]);
                h_rect = polyshape([h_rect_x(h_rect_hull),h_rect_y(h_rect_hull)]);
                box_pruning_matrix = inpolygon(coord(:,1),coord(:,2),h_rect.Vertices(:,1),h_rect.Vertices(:,2));
                box_pruned_coord = coord.*box_pruning_matrix;
                box_pruned_coord = box_pruned_coord(~all(box_pruned_coord == 0, 2),:);
                [h_bitmap_x,h_bitmap_y] = meshgrid(unique(box_pruned_coord(:,1)),unique(box_pruned_coord(:,2)));
                % plot(intersect(cell_site,sect_bound),'FaceColor','b');
                % drawnow;
            end
            if not(isempty(beehive))
                beehive = union(beehive,cell_site);
            else
                beehive = cell_site;
            end
            bee_cover = area(intersect(beehive,sect_bound));
            cell_site_hinterland = intersect(cell_site,city);
            cell_site_pruned = subtract(cell_site,cell_site_hinterland);
            [out_of_bound_i,out_of_bound_o] = inpolygon(pruned_coord(:,1),pruned_coord(:,2),cell_site_pruned.Vertices(:,1),cell_site_pruned.Vertices(:,2));
            temp_p_closer(out_of_bound_i & not(out_of_bound_o)) = 0;
            cell_site_hinterland = intersect(cell_site_hinterland,sect_bound);
            cell_streets = intersect(cell_site_hinterland,streets);
            in_building = intersect(fsi_obstacles,cell_site_hinterland);
            [dont_check_indoor_i,dont_check_indoor_o] = inpolygon(pruned_coord(:,1),pruned_coord(:,2),in_building.Vertices(:,1),in_building.Vertices(:,2));
            temp_p_closer(dont_check_indoor_i & not(dont_check_indoor_o)) = 0;
            [h_pruning_matrix_i, h_pruning_matrix_o ] = inpolygon(pruned_coord(:,1),pruned_coord(:,2),cell_streets.Vertices(:,1),cell_streets.Vertices(:,2));
            h_pruning_matrix = h_pruning_matrix_i & not(h_pruning_matrix_o) & temp_p_closer>0;
            h_coord_indeces = find(h_pruning_matrix);
            h_pruned_coord = pruned_coord.*h_pruning_matrix;
            h_pruned_coord = h_pruned_coord(~all(h_pruned_coord == 0, 2),:);

            n_boundaries = fsi_obstacles.NumRegions + fsi_obstacles.NumHoles;
            bound = cell(n_boundaries,1);
            for n_b=1:n_boundaries
                [x, y] = boundary(fsi_obstacles,n_b);
                bound{n_b}=[x, y];
            end
            n_boundaries = n_boundaries + city.NumRegions;
            [x, y] = boundary(city);
            bound{end+1} = [x,y];
            h_temp_p_closer  = temp_p_closer(h_coord_indeces);
            h_temp_p_closer = find_min_dist(bound,h_pruned_coord,sampl_freq_wall,h_temp_p_closer);
            for xy=1:size(h_pruned_coord,1)
                circle_poly = nsidedpoly(100,'Center',h_pruned_coord(xy,:),'Radius',h_temp_p_closer(xy));
                circle_poly = intersect(circle_poly,city);
                if area(intersect(circle_poly,sect_bound))/area(circle_poly) < 1 -1e-8
                    border_points = [border_points; [h_pruned_coord(xy,:) i]]; %[x-coord y-coord sector-id]
                end
            end

            temp_p_closer(h_coord_indeces) = h_temp_p_closer;

            if pl_fsi
                cell_obstacles = intersect(fsi_obstacles,cell_site);
                h_bitmap_z = zeros(size(h_bitmap_x));
                for j=1:size(h_bitmap_z,1)
                    for k=1:size(h_bitmap_z,2)
                        [member, index] = ismember([h_bitmap_x(j,k) h_bitmap_y(j,k)],h_pruned_coord,'rows');
                        if member
                            h_bitmap_z(j,k) = h_temp_p_closer(index);
                            circle_poly = nsidedpoly(100,'Center',[h_bitmap_x(j,k) h_bitmap_y(j,k)],'Radius',h_temp_p_closer(index));
                            circle_poly = intersect(circle_poly,city);
                            if not(isempty(border_points))
                                if ismember([h_bitmap_x(j,k) h_bitmap_y(j,k)],border_points(:,1:2),'rows')
                                    scatter(h_bitmap_x(j,k),h_bitmap_y(j,k),'r','filled');
                                end
                            end
                        elseif inpolygon(h_bitmap_x(j,k),h_bitmap_y(j,k),cell_site_hinterland.Vertices(:,1),cell_site_hinterland.Vertices(:,2))
                            h_bitmap_z(j,k) = 0;
                        else
                            h_bitmap_z(j,k) = NaN;
                        end
                    end
                end
                scatter(h_pruned_coord(:,1),h_pruned_coord(:,2),10,'b.')
                contourf(h_bitmap_x,h_bitmap_y,h_bitmap_z,'FaceAlpha',0.7,'LevelList',0:10:scenario.site.site_width)
                if not(isempty(cell_obstacles)) && cell_obstacles.NumRegions > 0
                    plot(cell_obstacles,'FaceColor','k','FaceAlpha',0.5);
                end
                drawnow
            end
            if center(1) < max(rect.Vertices(:,1))
                center = [center(1)+x_movement,center(2)];
            elseif odd
                odd = 0;
                center = [reference_point(1) + x_movement/2, center(2) - y_movement];
            else
                odd = 1;
                center = [reference_point(1) , center(2) - y_movement];
            end
        else
            if center(1) < max(rect.Vertices(:,1))
                center = [center(1)+x_movement,center(2)];
            elseif odd
                odd = 0;
                center = [reference_point(1) + x_movement/2, center(2) - y_movement];
            else
                odd = 1;
                center = [reference_point(1) , center(2) - y_movement];
            end
            continue;
        end
        disp(['Sector ' num2str(i) ' of ' num2str(numel(sector_poly)) ', '...
            num2str(area(intersect(beehive,sect_bound))/area(sect_bound)*100) '%'])
    end
    p_closer(coord_indeces) = temp_p_closer;
    save('Blockage_Data/fsi_map_sampling1.mat','p_closer','coord','border_points','-v7.3');
end


if not(isempty(border_points))
    for j=1:numel(sector_poly)
        assigned_sect = [];
        ind = [];
        selected_border_points = border_points(border_points(:,3)~=j,:);
        if not(isempty(selected_border_points))
            [iscoord,overall_ind] = ismember(selected_border_points(:,1:2),coord,'rows');
            disp(['Processing points that might intersect with sector' num2str(j)])
            for xy=1:size(selected_border_points,1)
                if iscoord(xy) && p_closer(overall_ind(xy)) > 0 && isfinite(p_closer(overall_ind(xy)))
                    circle_poly = nsidedpoly(100,'Center',selected_border_points(xy,1:2),'Radius',p_closer(overall_ind(xy)));
                    % disp(area(circle_poly))
                    circle_poly = intersect(circle_poly,city);
                    % disp(area(circle_poly))
                    if area(intersect(circle_poly,polyshape(sector_poly{j})))/area(circle_poly) > 1e-8
                        assigned_sect = [assigned_sect; selected_border_points(xy,:) ]; %[x-coord y-coord, coming_from]
                        ind = [ind; overall_ind(xy)];
                       % disp([num2str(xy*100/size(selected_border_points,1)) '%'])
                    end
                end    
            end
            if not(isempty(assigned_sect))
                original_sector = unique(assigned_sect(:,3))';
                disp([num2str(size(assigned_sect,1)) ' points found. They came from these sectors: ' num2str(original_sector)])
                temp_p_closer2 = p_closer(ind);
                pv = [];
                load(['Blockage_Data/Milan_Sector_Buildings_' num2str(j) '.mat']);
                n = numel(Sector_Buildings);
                for b=1:n
                    xy = reformat_building(Sector_Buildings(b).geometry.coordinates,'loop');
                    pv=[pv;xy;NaN NaN];
                end
                fsi_obstacles = polyshape(pv);
                n_boundaries = fsi_obstacles.NumRegions + fsi_obstacles.NumHoles;
                bound = cell(n_boundaries,1);
                for n_b=1:n_boundaries
                    [x, y] = boundary(fsi_obstacles,n_b);
                    bound{n_b}=[x, y];
                end
                n_boundaries = n_boundaries + city.NumRegions;
                [x, y] = boundary(city);
                bound{end+1} = [x,y];
                temp_p_closer2 = find_min_dist(bound,assigned_sect(:,1:2),sampl_freq_wall,temp_p_closer2);
                different = sum(p_closer(ind)~=temp_p_closer2);
                disp([num2str(different) ' points'' FSI were recalculated out of ' num2str(numel(temp_p_closer2))])
                p_closer(ind) = temp_p_closer2;
            end
        end
    end
end
save('Blockage_Data/fsi_map_sampling1.mat','p_closer','coord','border_points','-v7.3');
