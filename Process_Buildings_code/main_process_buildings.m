clc,clear all, close all;
%% Load Data

load('leonardoBuildings.mat')
%% Initial dataset
figure
for i = 1:length(Buildings)
    pol = polyshape(Buildings{1,i}(:,1),Buildings{1,i}(:,2));
    plot(pol)
    hold on
end
title('Initial Dataset')

%% Aggregation of adjacent buildings
buildings_struct = struct;
i = 1;
while(~isempty(Buildings))
    % Transform shapefile element in polygon element and initialization of area and average height
    polygon = polyshape(Buildings{1,1}(:,1),Buildings{1,1}(:,2),'Simplify',true,'KeepCollinearPoints',true); 
    coordinate_vect = Buildings{1,1}(:,1);
    Buildings(1) = [];
    j=1;
    % Looking for buildings with same coordinates in common.
    while( j < length(Buildings))
        adj = sum(intersect(coordinate_vect,Buildings{1,j}(:,1)));
        if(adj > 0)
            % Merging of buildings
            polygon_add = polyshape(Buildings{1,j}(:,1),Buildings{1,j}(:,2),'Simplify',true,'KeepCollinearPoints',true);
            polygon = union(polygon,polygon_add,'KeepCollinearPoints',true);
            Buildings(j) = [];
            j=0;
        end
        j = j+1;
        coordinate_vect = polygon.Vertices(:,1);
    end
    % Update the struct
    buildings_struct(i).Polygon = polygon;
    i = i+1;
end

figure
axis equal
for i = 1:length({buildings_struct.Polygon})
    plot(buildings_struct(i).Polygon), hold on;
end
title('Aggragation of buildings')
%% Further processing (remove holes inside buildings and buidings in buildings)

% Remove holes inside buildings
pol =[buildings_struct.Polygon];
for p = 1:length(pol)
    buildings_struct(p).Polygon = rmholes(pol(p));
end

% Delete buildings inside buildings
delete_build = [];
struct_temp = buildings_struct;
for p = 1:length(buildings_struct)
    pol_ref = buildings_struct(p).Polygon.Vertices;
    for p_check = 1:length(struct_temp)
        if(p_check ~= p)
            pol_check = struct_temp(p_check).Polygon.Vertices;
            in = inpolygon(pol_check(:,1),pol_check(:,2),pol_ref(:,1),pol_ref(:,2));
            if(sum(in) == size(pol_check,1))
                delete_build = [delete_build p_check];
            end
        end
    end
end
buildings_struct(delete_build) = [];

figure
axis equal
for i = 1:length({buildings_struct.Polygon})
    plot(buildings_struct(i).Polygon), hold on;
end
title('Aggragation of buildings w/out holes')
%% Generate convex buildings

buildings_struct_conv = struct;
for b = 1:length(buildings_struct)
    polygon = convhull(buildings_struct(b).Polygon);
    buildings_struct_conv(b).Polygon = polygon;
end

figure
axis equal
for i = 1:length({buildings_struct_conv.Polygon})
    plot(buildings_struct_conv(i).Polygon), hold on;
end
title('Convex buildings')

buildings_convex = union_conv_fx(buildings_struct_conv);

figure
axis equal
for i = 1:length({buildings_convex.Polygon})
    plot(buildings_convex(i).Polygon), hold on;
end
title('Final convex buildings')
%% Remove small buildings

area_min = 350;               % Filtering parameter: minimum building area
for b = 1:length(buildings_convex)
    area_pol = area(buildings_convex(b).Polygon);
    buildings_convex(b).AREA = area_pol;    
end

area_block = [buildings_convex.AREA];
index_smallArea = find(area_block < area_min);
buildings_convex(index_smallArea) = [];

figure
axis equal
for i = 1:length({buildings_convex.Polygon})
    plot(buildings_convex(i).Polygon), hold on;
end
title('Final convex buildings w/o small buildings')
%% Specific processing for this dataset (Manually selection of the buildings to aggregate)
% Use this code to plot buildings with their ID.
% figure
% axis equal
% for i = 1:length({buildings_convex.Polygon})
%     plot(buildings_convex(i).Polygon), hold on;
% end
% for ii = 1:length({buildings_convex.Polygon})
%     [x,y] = centroid(buildings_convex(ii).Polygon);
%     text(x,y,num2str(ii),'Color','k')
% end

ID_b = 3:10;
pol_1 = buildings_convex(ID_b(1)).Polygon;
for i =2:length(ID_b)   
    pol_2 = buildings_convex(ID_b(i)).Polygon;
    pol = union(pol_1,pol_2,'KeepCollinearPoints',true);
    pol = convhull(pol);
    pol_1 = pol;
end
buildings_convex(ID_b) = [];
buildings_convex(end+1).Polygon = pol;

ID_b = [1 4];
pol_1 = buildings_convex(ID_b(1)).Polygon;
for i =2:length(ID_b)   
    pol_2 = buildings_convex(ID_b(i)).Polygon;
    pol = union(pol_1,pol_2,'KeepCollinearPoints',true);
    pol = convhull(pol);
    pol_1 = pol;
end
buildings_convex(ID_b) = [];
buildings_convex(end+1).Polygon = pol;

ID_b = [2 8];
pol_1 = buildings_convex(ID_b(1)).Polygon;
for i =2:length(ID_b)   
    pol_2 = buildings_convex(ID_b(i)).Polygon;
    pol = union(pol_1,pol_2,'KeepCollinearPoints',true);
    pol = convhull(pol);
    pol_1 = pol;
end
buildings_convex(ID_b) = [];
buildings_convex(end+1).Polygon = pol;

ID_b = [4 5 8 9];
pol_1 = buildings_convex(ID_b(1)).Polygon;
for i =2:length(ID_b)   
    pol_2 = buildings_convex(ID_b(i)).Polygon;
    pol = union(pol_1,pol_2,'KeepCollinearPoints',true);
    pol = convhull(pol);
    pol_1 = pol;
end
buildings_convex(ID_b) = [];
buildings_convex(end+1).Polygon = pol;

ID_b = [8 21 28 29];
pol_1 = buildings_convex(ID_b(1)).Polygon;
for i =2:length(ID_b)   
    pol_2 = buildings_convex(ID_b(i)).Polygon;
    pol = union(pol_1,pol_2,'KeepCollinearPoints',true);
    pol = convhull(pol);
    pol_1 = pol;
end
buildings_convex(ID_b) = [];
buildings_convex(end+1).Polygon = pol;

figure
axis equal
for i = 1:length({buildings_convex.Polygon})
    plot(buildings_convex(i).Polygon), hold on;
end


