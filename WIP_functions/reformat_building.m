function [new_building] = reformat_building(building,mode)
new_building = building;
angle_tolerance = 1; %if two edges have a 1° difference in coefficient, the common vertex is removed (collinearity)
switch mode
    case 'no-loop'
        %reformat only the cell/3d array buildings, the standard ones
        %don't need to be reformatted
        if isa(building,'cell')
            curves = numel(building);
            for c=1:curves
                pv = building{c};
                [pv , curve ] = remove_useless_vertices(pv, angle_tolerance);
                if c==1
                    new_building = [pv; NaN NaN];
                elseif c<numel(building)
                    new_building = [new_building; pv; NaN NaN];
                else
                    new_building = [new_building; pv];
                end
            end

         elseif ndims(building) == 3 && size(building,3) >= 2
             curves = size(building,3);
             for c=1:curves                 
                 pv = building(:,:,c);
                 [pv , curve ] = remove_useless_vertices(pv, angle_tolerance);
                 if c==1
                     new_building = [pv; NaN NaN];
                 elseif c<size(building,3)
                     new_building = [new_building; pv; NaN NaN];
                 else
                     new_building = [new_building; pv];
                 end
            end  
         elseif ismatrix(building)
        %do nothing
         else
        warning(['I dont know what building ' num2str(b) ' is'])
        end

        case 'loop'
            %reformat only the cell/3d array buildings, the standard ones
        %don't need to be reformatted
        if isa(building,'cell')
            curves = numel(building);
            for c=1:curves
                pv = building{c};
                [pv , curve ] = remove_useless_vertices(pv, angle_tolerance);
                if c==1
                    pv = findloop(pv);  
                    new_building = [pv; NaN NaN];
                elseif c<numel(building)
                    pv = findloop(pv);
                    new_building = [new_building; pv; NaN NaN];
                else
                    pv = findloop(pv);
                    new_building = [new_building; pv;];
                end
            end

         elseif ndims(building) == 3 && size(building,3) >= 2
             curves = size(building,3);
             for c=1:curves                 
                 pv = building(:,:,c);
                 [pv , curve ] = remove_useless_vertices(pv, angle_tolerance);
                 if c==1
                     pv = findloop(pv);
                     new_building = [pv; NaN NaN];
                 elseif c<size(building,3)
                     pv = findloop(pv);
                     new_building = [new_building; pv; NaN NaN];
                 else
                     pv = findloop(pv);
                     new_building = [new_building; pv;];
                 end
            end  
         elseif ismatrix(building)
            [building, curve ] = remove_useless_vertices(building, angle_tolerance); 
            building = findloop(building); 
            new_building = building;
         else
        warning(['I dont know what building ' num2str(b) ' is'])
        end

 end

end

function pv = findloop(pv)
if pv(1,:) ~= pv(end,:)
    pv =[pv; pv(1,:)];
end
end

function [building, curvemask] = remove_useless_vertices(building,tolerance)
deathmask = zeros(numel(building(:,1)),1);
curvemask = zeros(numel(building(:,1)),1);
num_vert = numel(building(:,1));
for i=0:num_vert-1
    v1= [building(i+1,1) building(i+1,2) 0];
    v2= [building(mod(i+1,num_vert)+1,1) building(mod(i+1,num_vert)+1,2) 0];
    v3= [building(mod(i+2,num_vert)+1,1) building(mod(i+2,num_vert)+1,2) 0];
    edge1 = v1 - v2;
    edge2 = v3 - v2;
    angle = atan2d(norm(cross(edge1, edge2)), dot(edge1, edge2));
   curvemask(mod(i+1,num_vert)+1) = angle;
    if angle < 180 + tolerance && angle > 180 - tolerance
        deathmask(mod(i+1,num_vert)+1) = true;
    end
end
building(find(deathmask),:) = [];
curvemask(find(deathmask),:) = [];
% bar(curvemask);
end