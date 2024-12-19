function [tested_centers, Blockage] = freeDonorSite(city_lim,diameter,donor_height,tested_centers,fsi_driven,fsi_vector)
load("Blockage_Data/sector_data.mat");
if nargin == 4
    
    fsi_driven = 0;
elseif nargin==5 && fsi_driven
    fsi_vector = 2:50; %to test in single instance
end
% select Donor coordinates not overlapping with a building

if fsi_driven
    load('Blockage_Data/fsi_cell.mat');
    load('Blockage_Data/fsi_map.mat','coord');
end
don_selected = 0;
check_height = 1;
pl = 0;

while ~don_selected
    if fsi_driven
        inst = rng().Seed;
        filter = find(fsi_cell >= fsi_vector(inst) & fsi_cell < fsi_vector(inst+1));
        selected = randsample(filter,1);
        center_coord = coord(selected,:);
        don_coord = [center_coord(1) - diameter/2, center_coord(2)];
        % disp(don_coord);
    else
        don_coord = [rand*(city_lim(2,1) - city_lim(1,1)) + city_lim(1,1), ...
            rand*(city_lim(2,2) - city_lim(1,2)) + city_lim(1,2)];
    end
    hcell = nsidedpoly(6,'Center',[(don_coord(1)+diameter/2),don_coord(2)],'SideLength',diameter/2);
    city = polyshape(city_poly);
    outside = 1 - area(intersect(hcell,city))/area(hcell);
    % disp(['Area of cell is ' num2str(outside*100) '% outside of the city']);
    don_blocked = 0;
    if all(ismember([(don_coord(1)+diameter/2),don_coord(2)],tested_centers)) || outside > 0
        don_blocked = 1;
    end
    tested_centers = [tested_centers; [(don_coord(1)+diameter/2),don_coord(2)]];
    Considered_Buildings = [];
    while ~don_blocked && ~don_selected
        load_sector=find(cellfun(@(x)inpolygon(don_coord(1),don_coord(2),...
            polyshape(x).Vertices(:,1),polyshape(x).Vertices(:,2)),sector_poly));

  
        if numel(load_sector)==0
            don_blocked = 1;
            continue;
        end

        [x, y] = boundary(hcell);
        c_bound = [x, y];
        s_bound = sector_poly;

        p_closer = Inf*ones(numel(s_bound),size(c_bound,1)-1);
        for q=1:size(c_bound,1)-1
            c_edgeStart = c_bound(q,:);
            c_edgeEnd = c_bound(q+1,:);
            c_edge_x = linspace(c_edgeStart(1),c_edgeEnd(1),20)';
            c_edge_y = linspace(c_edgeStart(2),c_edgeEnd(2),20)';
            for t=1:numel(s_bound)
                if ismember(t,load_sector)
                    continue;
                else
                    for r=1:size(s_bound{t},1)-1
                        s_edgeStart = s_bound{t}(r,:);
                        s_edgeEnd = s_bound{t}(r+1,:);
                        s_edge_x = linspace(s_edgeStart(1),s_edgeEnd(1),20)';
                        s_edge_y = linspace(s_edgeStart(2),s_edgeEnd(2),20)';
        
                        d = pdist2([c_edge_x,c_edge_y],[s_edge_x,s_edge_y]);
                        d = min(d,[],'all');
                        if d < p_closer(t,q)
                            p_closer(t,q) = d ;
                        end
                    end
                end
            end
        end
        p_closer = min(p_closer,[],2);
        load_sector = [load_sector; find(p_closer < max_distance)];

        
        if pl

            plot(hcell)
            axis equal
            hold on
            for i=1:numel(sector_poly)
                plot(polyshape(sector_poly{i}));
                disp(p_closer(i));
            end
        end
        for sec=1:numel(load_sector)
            load(['Blockage_Data/Milan_Sector_Buildings_' num2str(load_sector(sec)) '.mat'],'Sector_Buildings','max_side');
            Considered_Buildings = [Considered_Buildings; Sector_Buildings];
        end
        n=numel(Considered_Buildings);
        for b=1:n

            pv = reformat_building(Considered_Buildings(b).geometry.coordinates, 'no-loop');
            height = Considered_Buildings(b).properties.UN_VOL_AV;
            p_dist = sqrt((pv(:,1) - don_coord(1)).^2 + (pv(:,2) - don_coord(2)).^2);
            if sum(p_dist <= diameter/2) >= 1

                %if checkobstruction(pv,Buildings(b).properties.UN_VOL_AV,link_coord)
                if inpolygon(don_coord(1),don_coord(2),pv(:,1),pv(:,2))
                    if check_height
                        if height >= donor_height
                            don_blocked = 1;
                            disp(['Donor blocked by building ' num2str(b)]);
                            %                         plot(polyshape(pv));
                            %                         hold on;
                            %                         scatter(don_coord(1),don_coord(2));
                            break;
                        end
                    else
                        don_blocked = 1;
                        disp(['Donor blocked by building ' num2str(b)]);
                        %                         plot(polyshape(pv));
                        %                         hold on;
                        %                         scatter(don_coord(1),don_coord(2));
                        break;
                    end

                end


            end
        end
        if ~don_blocked
            don_selected = 1;

        end
    end

end

Blockage.site_center = [(don_coord(1)+diameter/2),don_coord(2)];
Blockage.Buildings = Considered_Buildings;
Blockage.max_side = max_side;
Blockage.max_distance = max_distance;
Blockage.city_poly = city_poly;
Blockage.sector_poly = sector_poly(load_sector);
Blockage.fsi = fsi_cell(selected);
if outside > 0
    Blockage.hinterland = 1;
else
    Blockage.hinterland = 0;
end
% scatter(don_coord(1),don_coord(2),'r');
% hold on;
% scatter(center_coord(1),center_coord(2),'b');

end

