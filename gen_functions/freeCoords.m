function [siteBuildings, coord] = freeCoords(max_n,center,vertices,diameter,Blockage)

% select Donor coordinates not overlapping with a building

pl=0;

x = rand(max_n,1)*diameter -(diameter - diameter/2);
y = rand(max_n,1)*diameter -(diameter - diameter/2);
coord = [center(1) + x,center(2) + y];

pruning_matrix = inpolygon(coord(:,1),coord(:,2),vertices(:,1),vertices(:,2));
coord = coord.*pruning_matrix;
coord = coord(~all(coord == 0, 2),:); %prune points outside the hexagon

if sum(pruning_matrix)>=1 %at least one coordinate must pass the first pruning process
    
    blocked = zeros(size(coord,1),1);
    
    siteBuildings = pruneBuildings(diameter,Blockage);
    n = numel(siteBuildings);
    for b=1:n
       
        pv = reformat_building(siteBuildings(b).geometry.coordinates,'no-loop');
        p_dist = sqrt((pv(:,1) - center(1)).^2 + (pv(:,2) - center(2)).^2);
        if sum(p_dist <= diameter/2) >= 1
            if pl
                plot(polyshape(pv));
                hold on;
            end
            blocked = blocked + inpolygon(coord(:,1),coord(:,2),pv(:,1),pv(:,2));
            %disp([num2str(size(blocked,1) - (sum(blocked))) ' points remaining']);
                   
        end
        
    end
    
    
end
coord = coord.*~blocked;
coord = coord(~all(coord == 0, 2),:);
if pl
    scatter(coord(:,1),coord(:,2),'g');
    axis equal;
    hold off;
end
disp([num2str(size(coord,1)) ' points generated out of ' num2str(max_n)]);
end

