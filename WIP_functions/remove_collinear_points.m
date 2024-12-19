clear all;
clc;
load('Blockage_Data/Milan_Buildings_5.mat','Buildings');
newBuildings = Buildings;
n=numel(newBuildings);
for b=1:n
    if isa(Buildings(b).geometry.coordinates,'cell')
        for c=1:numel(Buildings(b).geometry.coordinates)
            if b==116 && c>1
                disp("CAZZOOOOOOO!!!!")
            end
            pv = Buildings(b).geometry.coordinates{c};
            collinear = check_collinearity(pv);


            if any(collinear)
                disp("COLLINEAR!")
                i = find(collinear);
                newBuildings(b).geometry.coordinates{c}(i,:)=[];
            end

        end

    elseif ndims(Buildings(b).geometry.coordinates) == 3 && size(Buildings(b).geometry.coordinates,3) >= 2
        for c=1:size(Buildings(b).geometry.coordinates,3)
            pv = Buildings(b).geometry.coordinates(:,:,c);
            collinear = check_collinearity(pv);
            if any(collinear)
                disp("COLLINEAR!")
                i = find(collinear);
                newBuildings(b).geometry.coordinates(i,:,c)=[];
            end
        end
    elseif ndims(Buildings(b).geometry.coordinates) == 2
        pv = Buildings(b).geometry.coordinates;
        collinear = check_collinearity(pv);

        if any(collinear)
            disp("COLLINEAR!")
            i = find(collinear);
            newBuildings(b).geometry.coordinates(i,:)=[];
        end
    else
        warning(['I dont know what building ' num2str(b) ' is'])
    end
end



Buildings = newBuildings;
save('Blockage_Data/Milan_Buildings_5.mat','Buildings');

function col_vec = check_collinearity(pv)
n_points = size(pv,1);
col_vec = zeros(n_points,1);
for p=0:n_points-1
    idx = p:p+2;
    idx = mod(idx,n_points);
    xy=pv(idx+1,:);
    col_vec(idx(2)+1) = (rank(xy(2:end,:) - xy(1,:))==1);
end

end
