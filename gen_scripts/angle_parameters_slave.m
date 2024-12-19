
%max_angle_span = 180;
smallest_angles = zeros(n_tp,active_donor_cs,active_ris_cs);
%this is for the smallest angles between two cs as seen from tp

for t=1:n_tp
    for d=1:active_donor_cs
        for r=1:active_ris_cs
            %tp as reference
            offset = tp_positions(t,:);
            %compute angle with n1
            relative_cs_position = donor_cs(d,:) - offset;
            a1 = angle(relative_cs_position(1) + 1i*relative_cs_position(2))*180/pi;
            if a1 <0
                a1 = a1+360;
            end
            %compute angle with n2
            relative_cs_position = ris_cs(r,:) - offset;
            a2 = angle(relative_cs_position(1) + 1i*relative_cs_position(2))*180/pi;
            if a2 <0
                a2 = a2+360;
            end
            %compute smallest angle
            smallest_angles(t,d,r) = abs(a1-a2);
            if smallest_angles(t,d,r) > 180
                smallest_angles(t,d,r) = 360 - smallest_angles(t,d,r);
            end
        end
    end
end