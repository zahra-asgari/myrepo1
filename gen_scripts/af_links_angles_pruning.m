%direct links pruning mask
direct_p_mask = direct_rate >= R_dir_min;

%refl. links pruning
af_p_mask  = af_rel_rate >= R_out_min;
ris_p_mask = ris_rate >= R_out_min;

%angles
angles_mask_ris = zeros(t,d,r);
for r=1:n_cs
    for d=1:n_cs
        for t=1:n_tp
            angles_mask_ris(t,d,r) = max([cs_tp_angles(r,t) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t) cs_cs_angles(r,d)]) <= 2*max_angle_span;        
        end
    end
end

ris_p_mask = ris_p_mask & angles_mask_ris & repmat(direct_p_mask,1,1,n_cs);
af_p_mask  = af_p_mask & repmat(direct_p_mask,1,1,n_cs);

if has_buildings
    for r=1:n_cs
        for d=1:n_cs
            for t=1:n_tp
                af_p_mask(t,d,r) = af_p_mask(t,d,r) & ~cs_cs_obstruction(d,r) & ~cs_tp_obstruction(d,t) & ~cs_tp_obstruction(r,t);
                ris_p_mask(t,d,r) = ris_p_mask(t,d,r) & ~cs_cs_obstruction(d,r) & ~cs_tp_obstruction(d,t) & ~cs_tp_obstruction(r,t);
            end
        end
    end
    if scenario.has_relays 
        bh_p_mask = ~cs_cs_obstruction;
    end
end

%decativate self links 
bh_p_mask = bh_p_mask - diag(diag(bh_p_mask));