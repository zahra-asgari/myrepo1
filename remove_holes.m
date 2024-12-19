clear;
clc;
load('Blockage_Data\refactor_map.mat','city_with_holes','sector_poly');
hole_array = city_with_holes.holes;
sector_shapes = polyshape(11,1);
check_contact = zeros(numel(hole_array),numel(sector_poly));
for j=1:numel(sector_poly)
    sector_shapes(j,1)=polyshape(sector_poly{j});
    for i=1:numel(hole_array)
        if union(sector_shapes(j,1),hole_array(i)).NumRegions == 1
            check_contact(i,j) = 1;
        end
    end
end
for i = 1:numel(hole_array)
    a = find(check_contact(i,:));
    if numel(a) > 1
        areas = area(sector_shapes(a));
        [val, ind] = min(areas);
        sector_shapes(a(ind)) = union(sector_shapes(a(ind)),hole_array(i));
    end
end
