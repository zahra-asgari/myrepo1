clear;
clc;

if not(isfile('Blockage_Data/refactor_map.mat'))
% if 1
    load("Blockage_Data/Milan_Buildings_5.mat","Buildings")
    n = numel(Buildings);
    count_vertices = zeros(n,1);
    coordinates = [];
    for b=1:n
        new_building = reformat_building(Buildings(b).geometry.coordinates,'no-loop');
        % count_vertices(b) = sum(not(isnan(new_building(:,1))));
        if (sum(isnan(new_building),'all')>0)
            idx = find(isnan(new_building));
            idx = idx(1);
            new_building = new_building(1:idx-1,:);
        end
        count_vertices(b) = size(new_building,1);
        % coordinates = [coordinates; new_building(not(isnan(new_building(:,1))),:)];
        coordinates = [coordinates; new_building];
        if not(sum(count_vertices)==size(coordinates,1))
            disp(['Anomaly detected, ' num2str(sum(count_vertices)) ' is not ' num2str(size(coordinates,1))])
            break;
        end
    end
else
    load('Blockage_Data/refactor_map.mat')
    load('Blockage_Data/Milan_Buildings_5.mat');
    best_k = eva_ch.OptimalK;
    n = numel(Buildings);
    vertex_counter = 0;
    % boundary_buildings = cell(0,2);
    building_sector = zeros(n,1);
    for b=1:n
        new_building = reformat_building(Buildings(b).geometry.coordinates,'no-loop');
        if (sum(isnan(new_building),'all')>0)
            idx = find(isnan(new_building));
            idx = idx(1);
            new_building = new_building(1:idx-1,:);
        end
        
        vert_clust = clust(vertex_counter+1:vertex_counter + size(new_building,1),best_k);
        building_sector(b) = mode(vert_clust);
        % if numel(unique(vert_clust)) > 1
        %     disp(['boundary building ' num2str(b)]);
        %     boundary_buildings{end+1,1} = b;
        %     boundary_buildings{end,2} = unique(vert_clust);
        % end      

        vertex_counter = vertex_counter + size(new_building,1);
    end
    for sect=1:best_k
        Sector_Buildings = Buildings(building_sector==sect);
        save(['Blockage_Data/Milan_Sector_Buildings_' num2str(sect) '.mat'],'Sector_Buildings','max_side');
    end

end