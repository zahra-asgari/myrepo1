function blocked = manage_polygons(Buildings,link,center,diameter)

n = numel(Buildings);
blocked = 0;
for b=1:n
    pv = Buildings(b).geometry.coordinates;
%     p_dist = sqrt((pv(:,1) - center(1)).^2 + (pv(:,2) - center(2)).^2);
%     if sum(p_dist <= diameter/2) >= 1
        blocked = check_obstruction(pv,Buildings(b).properties.UN_VOL_AV,link);
%     end
    if blocked
        return;
    end
end

end


