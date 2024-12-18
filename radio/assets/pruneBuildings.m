function siteBuildings = pruneBuildings(diameter,Blockage,site_center,site_polygon)

if exist('site_center','var')
    Blockage.site_center = site_center;
end
if not(exist('site_polygon','var'))
    site_polygon = nsidedpoly(6,'Center',Blockage.site_center,'SideLength',diameter/2);
    %default to hexagon if shape not provided, otherwise use provided shape
end
%prune Buildings from all (~ 2*1e5) to the ones in the 300 m diameter cell (about 200), to speed up intersections

n = numel(Blockage.Buildings);

tempBuildings(1) = Blockage.Buildings(1);

for b=1:n

    pv = reformat_building(Blockage.Buildings(b).geometry.coordinates,'no-loop');
    p_dist = sqrt((pv(:,1) - Blockage.site_center(1)).^2 + (pv(:,2) - Blockage.site_center(2)).^2);
    if sum(p_dist <= diameter + Blockage.max_side) >= 1
        tempBuildings(end+1) = Blockage.Buildings(b);
        % disp(['Edificio numero ' num2str(b) 'è alto ' num2str(Blockage.Buildings(b).properties.UN_VOL_AV) ' m'])
%         plot(polyshape(pv));
%         disp(['Edificio ' num2str(numel(tempBuildings)) ' è sul totale il numero ' num2str(b)])
%         disp('')

    end

end

tempBuildings(1) = [];

n = numel(tempBuildings);
if n~=0
    siteBuildings(1) = tempBuildings(1);

    for b=1:n
        pv = reformat_building(tempBuildings(b).geometry.coordinates,'no-loop');
        if ~isempty(intersect(polyshape(pv),site_polygon.Vertices)) || sum(inpolygon(pv(:,1),pv(:,2),site_polygon.Vertices(:,1),site_polygon.Vertices(:,2))) >= 1
            siteBuildings(end+1) = tempBuildings(b);
            % if siteBuildings(end).properties.UN_VOL_AV <=1
            %     disp(siteBuildings(end).properties.UN_VOL_AV);
            %     disp(siteBuildings(end).properties.ID_EDIF);
            % end
%             plot(polyshape(pv));
%             disp(['Edificio ' num2str(numel(tempBuildings))])
        end

    end

    siteBuildings(1) = [];
else
    siteBuildings = [];
end
end

