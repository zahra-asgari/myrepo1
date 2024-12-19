function [positions] = position_building_filter(positions, build_descr)
%REDISTRIBUTE_OUT_BUILDINGS This function filters out any position falling
%inside any building in the building descriptor
    
%logic mask x and y
lm = zeros(size(positions,1),1);
for b = 1:size(build_descr,1)
    x_l_thr = build_descr(b,1);
    x_u_thr = build_descr(b,1) + build_descr(b,3);
    y_l_thr = build_descr(b,2);
    y_u_thr = build_descr(b,2) + build_descr(b,4);
    lm = lm | (positions(:,1) > x_l_thr & positions(:,1) < x_u_thr ...
        & positions(:,2) > y_l_thr & positions(:,2) < y_u_thr);
end
%use inverted logic mask to filter out positions inside buildings
positions = positions(~lm,:);

end

