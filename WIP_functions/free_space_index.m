function [bitmap_z,fsi] = free_space_index(map,site_polygon,Blockage,site_width)
pl = 0;
CALCULATE_FSI = 0;
center = Blockage.site_center;
if CALCULATE_FSI
    Buildings = pruneBuildings((sqrt(3)/2)*(site_width/2+Blockage.max_distance),Blockage);
    square_size_m = 5; %one sample every x meters
    sampl_freq_wall = 0.5;
    coord_x = linspace(center(1) - site_width/2, center(1) + site_width/2,site_width/square_size_m)';
    coord_y = linspace(center(2) - site_width/2, center(2) + site_width/2,site_width/square_size_m)';
    [bitmap_x, bitmap_y] = meshgrid(coord_x, coord_y);
    vect_x = reshape(bitmap_x,[],1);
    vect_y = reshape(bitmap_y,[],1);
    coord = [vect_x, vect_y];

    if Blockage.hinterland
        if not(isempty(map))
            streets = intersect(streets,polyshape(Blockage.city_poly));
        else
            streets = intersect(site_polygon,polyshape(Blockage.city_poly));
        end
    else
        if not(isempty(map))
            streets = subtract(site_polygon,map);
        else
            streets = site_polygon;
        end
    end
    pruning_matrix = inpolygon(coord(:,1),coord(:,2),streets.Vertices(:,1),streets.Vertices(:,2));

    coord = coord.*pruning_matrix;
    coord = coord(~all(coord == 0, 2),:); %prune points outside the hexagon
    n = numel(Buildings);
    pv = [];
    for b=1:n
        xy = reformat_building(Buildings(b).geometry.coordinates,'no-loop');
        pv=[pv; xy; NaN NaN];
    end
    fsi_obstacles = polyshape(pv);
    %I want to intersect all buildings in the loaded set to be
    %intersected with the convex hull of the sector(s)
    sector_vertices = zeros(sum(cellfun(@(x)sum(numel(x(:,1))),Blockage.sector_poly)),2);
    counter = 0;
    for i=1:numel(Blockage.sector_poly)
        sector_vertices(counter+1:counter + numel(Blockage.sector_poly{i}(:,1)),:) = Blockage.sector_poly{i};
        counter = counter + numel(Blockage.sector_poly{i}(:,1));
    end
    hull = convhull(sector_vertices);
    outer_boundary = polyshape(sector_vertices(hull,:));
    diff = subtract(outer_boundary,fsi_obstacles);
    diff = intersect(diff,polyshape(Blockage.city_poly));
    n_boundaries = diff.NumRegions + diff.NumHoles;
    bound = cell(n_boundaries,1);
    for n_b=1:n_boundaries
        [x_filter, y_filter] = boundary(diff,n_b);
        bound{n_b}=[x_filter, y_filter];
    end
    p_closer = find_min_dist(bound, coord,sampl_freq_wall);

    [~, indeces] = sort(p_closer,'descend');
    p_closer = p_closer(indeces);
    coord = coord(indeces,:);
    bitmap_z = zeros(size(bitmap_x));
    for i=1:size(bitmap_z,1)
        for j=1:size(bitmap_z,1)
            [member, index] = ismember([bitmap_x(i,j) bitmap_y(i,j)],coord,'rows');
            if member
                bitmap_z(i,j) = p_closer(index);
            elseif inpolygon(bitmap_x(i,j),bitmap_y(i,j),site_polygon.Vertices(:,1),site_polygon.Vertices(:,2))...
                    &&inpolygon(bitmap_x(i,j),bitmap_y(i,j),Blockage.city_poly(:,1),Blockage.city_poly(:,2))
                bitmap_z(i,j) = 0;
            else
                bitmap_z(i,j) = NaN;
            end
        end
    end
    fsi = mean(p_closer);
elseif not(isfield(Blockage,'fsi'))
    load('Blockage_Data/city_fsi_contour.mat');
    x_filter = find(bitmap_x(:,1)>=min(site_polygon.Vertices(:,1)) & bitmap_x(:,1)<=max(site_polygon.Vertices(:,1)));
    y_filter = find(bitmap_y(1,:)>=min(site_polygon.Vertices(:,2)) & bitmap_y(1,:)<=max(site_polygon.Vertices(:,2)));
    x = bitmap_x(x_filter,y_filter);
    y = bitmap_y(x_filter,y_filter);
    z = bitmap_z(x_filter,y_filter);
    in_hexagon = inpolygon(x,y,site_polygon.Vertices(:,1),site_polygon.Vertices(:,2));
    z(not(in_hexagon)) = NaN;
    %put at NaN also the samples inside the buildings in the hexagon, so
    %that they don't skew the mean
    filter = z(in_hexagon);
    a = filter==0;
    filter(a) = NaN;
    z(in_hexagon) = filter;
    p_closer = reshape(z,[],1);
    p_closer = p_closer(not(isnan(p_closer)));
    fsi = mean(p_closer);
else
    fsi = Blockage.fsi;
    bitmap_z = NaN;
end
if pl
    if not(isempty(map))
        plot(map,'FaceColor','k','FaceAlpha',0.7,'HandleVisibility','callback');
    end
    axis equal
    hold on;
    xlim([min(site_polygon.Vertices(:,1)), max(site_polygon.Vertices(:,1))]);
    ylim([min(site_polygon.Vertices(:,2)), max(site_polygon.Vertices(:,2))]);
    if CALCULATE_FSI
        scatter(coord(:,1),coord(:,2),10,'b.','HandleVisibility','callback');
        contourf(bitmap_x,bitmap_y,bitmap_z,'FaceAlpha',0.7,'LevelList',0:10:200,'HandleVisibility','callback')
        scatter(coord(1,1),coord(1,2),'r','filled','HandleVisibility','callback');
        circle(coord(1,1),coord(1,2),p_closer(1),0:0.01:2*pi);
    else
        scatter(x(in_hexagon),y(in_hexagon),10,'b.','HandleVisibility','callback');
        contourf(x,y,z,'FaceAlpha',0.7,'LevelList',0:10:200,'HandleVisibility','callback')
        [val,ind] = max(z,[],'all');
        scatter(x(ind),y(ind),'r','filled','HandleVisibility','callback');
        circle(x(ind),y(ind),val,0:0.01:2*pi);
    end
    drawnow
end

% disp(['Instance allows open space up to ' num2str(fsi*100) '% of the free area. Scrap it']);
%disp(['Free space index is ' num2str(fsi)]);
end