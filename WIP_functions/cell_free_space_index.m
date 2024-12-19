clear; clc;
load('C:\Users\paolo\MATLAB\Projects\RIS-Planning-Instance-Generator\Blockage_Data\city_fsi_contour.mat')
%loop over all the points and intersect with the shape of the cell
shape = 'hexagonal';
side = 150;
threshold = 1; %how much I accept an hexagon outside of the city
fsi_cell = NaN(size(bitmap_z));
fsi_filter = NaN(size(bitmap_z));
for i=1:size(bitmap_z,1)
    for j=1:size(bitmap_z,2)
        center = [bitmap_x(i,j), bitmap_y(i,j)];
        switch shape
            case 'hexagonal'
                site_cell = nsidedpoly(6,'Center',center,'SideLength',side);
            case 'other'
        end
        x_filter = find(bitmap_x(:,1)>=min(site_cell.Vertices(:,1)) & bitmap_x(:,1)<=max(site_cell.Vertices(:,1)));
        y_filter = find(bitmap_y(1,:)>=min(site_cell.Vertices(:,2)) & bitmap_y(1,:)<=max(site_cell.Vertices(:,2)));
        x = bitmap_x(x_filter,y_filter);
        y = bitmap_y(x_filter,y_filter);
        z = bitmap_z(x_filter,y_filter);
        in_hexagon = inpolygon(x,y,site_cell.Vertices(:,1),site_cell.Vertices(:,2));
        fsi_filter(i,j) = sum(isnan(z(in_hexagon)))/numel(z(in_hexagon));
        if fsi_filter(i,j) >= threshold
            continue;
        end
        z_no_build = z(in_hexagon);
        z_no_build = z_no_build(not(isnan(z_no_build)));
        z_no_build = z_no_build(z_no_build~=0);        
        fsi_cell(i,j) = mean(z_no_build);
    end
end
save('Blockage_Data/fsi_cell.mat','fsi_cell','fsi_filter')
