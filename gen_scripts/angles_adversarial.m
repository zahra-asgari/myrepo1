function [cs_tp_angles,cs_cs_angles, smallest_angles] = angles_adversarial(cs_positions, tp_positions)
%ANGLES_ADVERSARIAL Summary of this function goes here
%   Detailed explanation goes here

n_cs = size(cs_positions,1);
n_tp = size(tp_positions,1);
P = size(tp_positions,3);

cs_tp_angles = zeros(n_cs,n_tp,P);
cs_cs_angles = zeros(n_cs,n_cs);
smallest_angles = zeros(n_tp,n_cs,n_cs,P);

%% cs_cs angles can be computed once

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

%% now tp angles
for p = 1:P
    for n=1:n_cs
        offset = cs_positions(n,:);
        for t=1:n_tp
            %everything will be referenced to the position of the cs, so we
            %need an offset
            relative_tp_position = tp_positions(t,:,p) - offset;
            %now it is like computing the angle of a vector having coordinates relative_tp_position
            cs_tp_angles(n,t,p) = angle(relative_tp_position(1) +1i*relative_tp_position(2))*180/pi; %1i is the imaginary unit
            if cs_tp_angles(n,t,p) < 0
                cs_tp_angles(n,t,p) = cs_tp_angles(n,t,p) + 360;
            end
        end
    end
end


%this is for the smallest angles between two cs as seen from tp
for p = 1:P
    for t=1:n_tp
        for n1=1:n_cs
            for n2=1:n_cs
                %tp as reference
                offset = tp_positions(t,:,p);
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
                smallest_angles(t,n1,n2,p) = abs(a1-a2);
                if smallest_angles(t,n1,n2,p) > 180
                    smallest_angles(t,n1,n2,p) = 360 - smallest_angles(t,n1,n2,p);
                end
            end
        end
    end
end
end

