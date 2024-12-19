%max_angle_span = 180;
cs_tp_angles = zeros(n_cs,n_tp);
cs_cs_angles = zeros(n_cs,n_cs);
smallest_angles = zeros(n_tp,n_cs,n_cs);

for n=1:n_cs
    for t=1:n_tp
        %everything will be referenced to the position of the cs, so we
        %need an offset
        offset = cs_positions(n,:);
        relative_tp_position = tp_positions(t,:) - offset;
        %now it is like computing the angle of a vector having coordinates relative_tp_position
        cs_tp_angles(n,t) = angle(relative_tp_position(1) +1i*relative_tp_position(2))*180/pi; %1i is the imaginary unit
        if cs_tp_angles(n,t) < 0
            cs_tp_angles(n,t) = cs_tp_angles(n,t) + 360;
        end
    end
end

for n1=1:n_cs
    for n2=1:n_cs
        offset = cs_positions(n1,:);
        relative_cs_position = cs_positions(n2,:) - offset;
        cs_cs_angles(n1,n2) = angle(relative_cs_position(1) +1i*relative_cs_position(2))*180/pi;
        if cs_cs_angles(n1,n2) < 0
            cs_cs_angles(n1,n2) = cs_cs_angles(n1,n2) + 360;
        end
    end
end

%this is for the smallest angles between two cs as seen from tp

for t=1:n_tp
    for n1=1:n_cs
        for n2=1:n_cs
            %tp as reference
            offset = tp_positions(t,:);
            %compute angle with n1
            relative_cs_position = cs_positions(n1,:) - offset;
            a1 = angle(relative_cs_position(1) + 1i*relative_cs_position(2))*180/pi;
            if a1 <0
                a1 = a1+360;
            end
            %compute angle with n2
            relative_cs_position = cs_positions(n2,:) - offset;
            a2 = angle(relative_cs_position(1) + 1i*relative_cs_position(2))*180/pi;
            if a2 <0
                a2 = a2+360;
            end
            %compute smallest angle
            smallest_angles(t,n1,n2) = abs(a1-a2);
            if smallest_angles(t,n1,n2) > 180
                smallest_angles(t,n1,n2) = 360 - smallest_angles(t,n1,n2);
            end
        end
    end
end