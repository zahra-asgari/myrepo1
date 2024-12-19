function [collides] = building_collision_det(p1,p2,build_descr)
%BUILDING_COLLISION_DET Returns true only if the line of sight between p1
%and p2 is obstructed by the building
%   
collides = 0;
l1 = [[p1(1) p2(1)];[p1(2) p2(2)]];
for b = 1:size(build_descr,1)
    if ~isempty(interX(l1,...
            [[build_descr(b,1) build_descr(b,1)];...
            [build_descr(b,2) build_descr(b,2)+build_descr(b,4)]])) %west edge
        collides = 1;
        break;
    elseif ~isempty(interX(l1,...
            [[build_descr(b,1) build_descr(b,1)+build_descr(b,3)];...
            [build_descr(b,2) build_descr(b,2)]])) %south edge
        collides = 1;
        break;
    elseif ~isempty(interX(l1,...
            [[build_descr(b,1) build_descr(b,1)+build_descr(b,3)];...
            [build_descr(b,2)+build_descr(b,4) build_descr(b,2)+build_descr(b,4)]])) %north edge
        collides = 1;
        break;
    end
end
end


