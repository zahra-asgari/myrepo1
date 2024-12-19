%% building collision computation
if has_buildings
    cs_cs_obstruction = zeros(n_cs,n_cs);
    cs_tp_obstruction = zeros(n_cs,n_tp);
    
    for c1 = 1:n_cs
        for c2 = 1:n_cs-1
            if c1==c2
                continue;
            end
            cs_cs_obstruction(c1,c2) = building_collision_det(cs_positions(c1,:),...
                cs_positions(c2,:),build_descr);
            if ~cs_cs_obstruction(c1,c2)
                plot([cs_positions(c1,1) cs_positions(c2,1)], [cs_positions(c1,2) cs_positions(c2,2)],'--k','HandleVisibility','off');
            end
        end
        for t=1:n_tp
            cs_tp_obstruction(c1,t) = building_collision_det(cs_positions(c1,:),...
                tp_positions(t,:),build_descr);
            if ~cs_tp_obstruction(c1,t)
                plot([cs_positions(c1,1) tp_positions(t,1)],[cs_positions(c1,2) tp_positions(t,2)],'--k','HandleVisibility','off')
            end
        end
    end
end