load('C:/Users/paolo/MATLAB/Projects/RIS-Planning-Instance-Generator/Blockage_Data/Milan_Buildings_5.mat', 'Buildings');
n = numel(Buildings);
max_side = 0;
disp(max_side);
all_sides = [];
for b=1:n
    building = reformat_building(Buildings(b).geometry.coordinates,'loop');
    if (sum(isnan(building),'all')>0)
        idx = find(isnan(building));
        idx = idx(1);
        building = building(1:idx-1,:);
    end
n_v = size(building,1)-1;
    for v=1:n_v
        cur_dist = sqrt((building(v,1) - building(v+1,1)).^2 + (building(v,2) - building(v+1,2)).^2);
        all_sides = [all_sides cur_dist];
        if cur_dist >= max_side
            max_side = cur_dist;
            disp(max_side);
        end
    end
end
all_sides = sort(all_sides);
bar(all_sides)
save('Blockage_Data/Milan_Buildings_5.mat','max_side','-append');