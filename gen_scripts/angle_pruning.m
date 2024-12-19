s_angle_ok = zeros(n_tp, n_cs, n_cs);

if ris_on_buildings
    % if ris are on building then angle pruning is done wrt their fixed
    % cs_fixed_orientation
%     for r=1:n_cs
%         u_thr = cs_fixed_orientation(r) + max_angle_span/2;
%         l_thr = cs_fixed_orientation(r) - max_angle_span/2;
%         for d=1:n_cs
%             
%             if cs_cs_angles(r,d)
%             
%             for t=1:n_tp
%                 
%             end
%         end
%     end
else
    for r=1:n_cs
        for d=1:n_cs
            for t=1:n_tp
                s_angle_ok(t,d,r) = max([cs_tp_angles(r,t) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t) cs_cs_angles(r,d)]) <= 2*max_angle_span;
            end
        end
    end
end