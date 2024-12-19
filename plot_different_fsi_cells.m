clear; clc;
load("Blockage_Data/fsi_cell.mat");
load("Blockage_Data/city_fsi_contour.mat");
load("Blockage_Data/Milan_Buildings_5.mat");
Blockage.Buildings = Buildings;
Blockage.max_side = max_side;
threshold = 0;
index = find(fsi_filter<=threshold);
fsi_cell_filtered = fsi_cell(index);
max_cell = floor(max(fsi_cell_filtered));
center_vector = NaN(max_cell,2);
for i=1:floor(max(fsi_cell_filtered))
    bin_idx = find(fsi_cell_filtered >= i-1 & fsi_cell_filtered < i);
    [fsi,min_idx] = min(fsi_cell_filtered(bin_idx));
    if not(isempty(bin_idx)) && (isempty(previous_bin_idx) || bin_idx(min_idx) ~= previous_bin_idx)
        center_vector(i,:) = [bitmap_x(index(bin_idx(min_idx))), bitmap_y(index(bin_idx(min_idx)))];
        previous_bin_idx = index(bin_idx(min_idx));
    else
        previous_bin_idx = index(bin_idx(min_idx));
        continue;
    end
    if mod(i-1,5) == 0 && i<=101
        site_polygon = nsidedpoly(6,'Center',center_vector(i,:),'SideLength',150);
        site_Buildings = pruneBuildings(300,Blockage,center_vector(i,:));
        n = numel(site_Buildings);
        pv = [];
        for b=1:n
            xy = reformat_building(site_Buildings(b).geometry.coordinates,'no-loop');
            pv=[pv;xy;NaN NaN];
        end
        if not(isempty(pv))
            map = polyshape(pv);
        else
            map = polyshape.empty;
        end
    
        x_filter = find(bitmap_x(:,1)>=min(site_polygon.Vertices(:,1)) & bitmap_x(:,1)<=max(site_polygon.Vertices(:,1)));
        y_filter = find(bitmap_y(1,:)>=min(site_polygon.Vertices(:,2)) & bitmap_y(1,:)<=max(site_polygon.Vertices(:,2)));
        x = bitmap_x(x_filter,y_filter);
        y = bitmap_y(x_filter,y_filter);
        z = bitmap_z(x_filter,y_filter);
        in_hexagon = inpolygon(x,y,site_polygon.Vertices(:,1),site_polygon.Vertices(:,2));
        z(not(in_hexagon)) = NaN;
        if not(isempty(map))
            plot(map,'FaceColor','k','FaceAlpha',0.7);
        end
        axis equal
        hold on;
        xlim([min(site_polygon.Vertices(:,1)), max(site_polygon.Vertices(:,1))]);
        ylim([min(site_polygon.Vertices(:,2)), max(site_polygon.Vertices(:,2))]);
        scatter(x(in_hexagon),y(in_hexagon),10,'b.');
        %levels = 2.^(-1:9);
        levels = 0:10:200;
        [C,h] = contourf(x,y,z,'FaceAlpha',0.7,'LevelList',levels);
        clabel(C,h);
        % [val,ind] = max(z,[],'all');
        % scatter(x(ind),y(ind),'r','filled');
        % circle(x(ind),y(ind),val,0:0.01:2*pi);
        title(['FSI=' num2str(fsi)]);
        drawnow      
        % exportgraphics(gcf,'FSI.gif','Append',true);
        hold off;
    end
end