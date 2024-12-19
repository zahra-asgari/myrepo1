clear; clc;
load("Blockage_Data/sector_data.mat")
load("Blockage_Data/fsi_map.mat")
city = polyshape(city_poly);
city_width = max(city_poly(:,1)) - min(city_poly(:,1));
city_height = max(city_poly(:,2)) - min(city_poly(:,2));
square_size_m = 5;
% n = numel(Sector_Buildings);
% pv = [];
% for b=1:n
%     xy = reformat_building(Sector_Buildings(b).geometry.coordinates,'no-loop');
%     pv=[pv;xy;NaN NaN];
% end
% current_neighbours = neighbours;
% for neigh=1:numel(current_neighbours)
%     load(['Blockage_Data/Milan_Sector_Buildings_' num2str(current_neighbours(neigh)) '.mat']);
%     n = numel(Sector_Buildings);
%     for b=1:n
%         xy = reformat_building(Sector_Buildings(b).geometry.coordinates,'no-loop');
%         pv=[pv;xy;NaN NaN];
%     end
% end
% all_obstacles = polyshape(pv);
% sect_obstacles = intersect(all_obstacles,sect_bound);
% streets = subtract(sect_bound,all_obstacles);
% [pmi,pmo] = inpolygon(coord(:,1),coord(:,2),streets.Vertices(:,1),streets.Vertices(:,2));
% pruning_matrix = pmi & not(pmo);
% pruned_p_closer = p_closer(pruning_matrix);
if not(isfile('Blockage_Data/city_fsi_contour.mat'))
    coord_x = linspace(min(city_poly(:,1)), max(city_poly(:,1)),city_width/square_size_m)';
    coord_y = linspace(min(city_poly(:,2)), max(city_poly(:,2)),city_height/square_size_m)';
    coord_y = flip(coord_y);
    [bitmap_x, bitmap_y] = meshgrid(coord_x, coord_y);
    bitmap_x = bitmap_x';
    bitmap_y = bitmap_y';
    bitmap_z = reshape(p_closer,size(bitmap_y));
    save("Blockage_Data/city_fsi_contour.mat","bitmap_x","bitmap_y","bitmap_z");
else
    load('Blockage_Data/city_fsi_contour.mat');
end
% num_bins=100;
% cutoffs=linspace(0,max_distance,num_bins+2);
% bins = zeros(numel(cutoffs)-1,1);
% for bin=1:numel(bins)
%     bins(bin) = sum(ordered>=cutoffs(bin) & ordered<cutoffs(bin+1));
% end
% bar(cutoffs(2:end),bins);
% hold on;
figure;
% levels = prctile(ordered,0:10:100);
levels = 2.^(0:8);
contourf(bitmap_x,bitmap_y,bitmap_z,'FaceAlpha',0.7,'LevelList',levels);
axis equal;


