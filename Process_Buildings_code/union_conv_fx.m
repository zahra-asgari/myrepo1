function [pol_conv] = union_conv_fx(buildings)
    union_bool = 0;
    pol_conv = struct;
    i = 1;
    while(~isempty(buildings))
        p_conv_ref = buildings(1).Polygon;
        p_conv_ref_ver = buildings(1).Polygon.Vertices;
        buildings(1) = [];
        j = 1;
        while( j <= length(buildings))
            p_conv_check = buildings(j).Polygon.Vertices;
            in1 = inpolygon(p_conv_check(:,1),p_conv_check(:,2),p_conv_ref_ver(:,1),p_conv_ref_ver(:,2));
            in2 = inpolygon(p_conv_ref_ver(:,1),p_conv_ref_ver(:,2),p_conv_check(:,1),p_conv_check(:,2));
            if((sum(in1)+sum(in2)) > 0)
                x1 = p_conv_check(:,1);
                y1 = p_conv_check(:,2);
                x2 = p_conv_ref_ver(:,1);
                y2 = p_conv_ref_ver(:,2);
                pol_new = polyshape({x1,x2},{y1,y2});
                p_conv_ref = convhull(pol_new);
                p_conv_ref_ver = p_conv_ref.Vertices;
                buildings(j) = [];
                j = 0;
                union_bool = union_bool + 1;
            end
            j = j + 1;
        end
        pol_conv(i).Polygon = p_conv_ref;;
        i = i+1;
    end
    if(union_bool > 0)
        pol_conv = union_conv_fx(pol_conv);
    end
end