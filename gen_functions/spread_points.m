function [points_per_sector] = spread_points(free_area,num_points,index_set,n_sectors,decay)
if nargin==4
    decay=1;
end
epsilon=1e-8;
points_per_sector = zeros(n_sectors,1);
points_per_sector(index_set)=free_area(index_set)/sum(free_area(index_set))*num_points;
residual = num_points;
next_set = [];
if all(points_per_sector(index_set)==points_per_sector(index_set(1)))
    lucky = randsample(find(points_per_sector(index_set)),1);
    for i=1:numel(index_set)
        if i == lucky
            points_per_sector(index_set(i)) = ceil(points_per_sector(index_set(i)));
            residual = residual - points_per_sector(index_set(i));
        else
            points_per_sector(index_set(i)) = floor(points_per_sector(index_set(i)));
            residual = residual - points_per_sector(index_set(i));
        end
    end
else
    for i=1:numel(index_set)
        decimal = points_per_sector(index_set(i)) - floor(points_per_sector(index_set(i)));
        if  decimal <= 1 - decay
            points_per_sector(index_set(i)) = floor(points_per_sector(index_set(i)));
            residual = residual - points_per_sector(index_set(i));
            %points_per_sector(index_set(index_set~=i)) = points_per_sector(index_set(index_set~=i)) + decimal/numel(index_set(index_set~=i));
        elseif decimal >= decay
            points_per_sector(index_set(i)) = ceil(points_per_sector(index_set(i)));
            residual = residual - points_per_sector(index_set(i));
            %points_per_sector(index_set(index_set~=i)) = points_per_sector(index_set(index_set~=i)) - (1 - decimal)/numel(index_set(index_set~=i));
        else
            next_set = [next_set index_set(i)];
        end
    end
end
%disp(next_set)
if ~isempty(next_set)
    
    points_per_sector(next_set)=free_area(next_set)/sum(free_area(next_set))*residual;
    
    m_max = max((points_per_sector(next_set) - floor(points_per_sector(next_set)))) - epsilon;
    m_min = 1 - min((points_per_sector(next_set) - floor(points_per_sector(next_set)))) - epsilon;
    points_per_sector(next_set) = spread_points(free_area,residual,next_set,n_sectors,max(m_max,m_min));
    
    %     points_per_sector(next_set) = spread_points(free_area,residual,next_set,0.99*decay);
    %     points_per_sector = points_per_sector(index_set);
end
points_per_sector = points_per_sector(index_set);
assert(sum(points_per_sector)==num_points);
end

