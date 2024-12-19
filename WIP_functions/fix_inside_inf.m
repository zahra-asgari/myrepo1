clear;
clc;
load("Blockage_Data/fsi_map.mat",'p_closer','coord');
load("Blockage_Data/sector_data.mat");
indeces_of_not_inf = p_closer~=Inf;
not_inf_coord = coord(indeces_of_not_inf,:);
city = polyshape(city_poly);
[in,~] = inpolygon(not_inf_coord(:,1),not_inf_coord(:,2),city.Vertices(:,1),city.Vertices(:,2));
not_inf_in_ind = indeces_of_not_inf(in);
inside_coord = coord(not_inf_in_ind,:);
sampl_freq_wall = 5;
for j=1:numel(sector_poly)
    temp_p_closer2 = p_closer(not_inf_in_ind);
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
    temp_p_closer2 = find_min_dist(bound,inside_coord,sampl_freq_wall,temp_p_closer2);
    different = sum(p_closer(in)~=temp_p_closer2);
    disp([num2str(different) ' points'' FSI were recalculated out of ' num2str(numel(temp_p_closer2))])
    p_closer(in) = temp_p_closer2;
end
