function blocked = check_obstruction(xy,z,link)

blocked = 0;
c = link(2,3) - link(1,3);
if ~c    
    if link(1,3) <= z
        [in3,~] = intersect(polyshape(xy),[link(1,1:2);link(2,1:2)]);
        if ~isempty(in3)
            %disp("Blocked! IAB2IAB case");
            blocked = 1;
        end
    end              
else    
    t = (z - link(1,3))/c;    
    if link(1,1) == link(2,1)        
        x_p = link(1,1);        
    else       
        x_p = link(1,1) + t*(link(2,1) - link(1,1));      
    end
    if link(1,2) == link(2,2)       
        y_p = link(1,2);       
    else       
        y_p = link(1,2) + t*(link(2,2) - link(1,2));      
    end   
    [in3,~] = intersect(polyshape(xy),[[x_p y_p];link(2,1:2)]);    
    if ~isempty(in3)
        %disp("Blocked!! Access case");
        blocked = 1;
    end 
end

end