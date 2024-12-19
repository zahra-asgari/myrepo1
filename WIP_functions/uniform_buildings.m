clear all;
clc;
load('Blockage_Data/Milan_Buildings_1.mat','Buildings');
newBuildings = Buildings;
n=numel(newBuildings);
for b=1:n
    if isa(Buildings(b).geometry.coordinates,'cell')
        for c=1:numel(Buildings(b).geometry.coordinates)
            pv = Buildings(b).geometry.coordinates{c};
            if c==1
                newBuildings(b).geometry.coordinates = [pv; NaN NaN];
            elseif c<numel(Buildings(b).geometry.coordinates)
                newBuildings(b).geometry.coordinates = [newBuildings(b).geometry.coordinates; pv; NaN NaN];
            else
                newBuildings(b).geometry.coordinates = [newBuildings(b).geometry.coordinates; pv];
            end
        end

    elseif ndims(Buildings(b).geometry.coordinates) == 3 && size(Buildings(b).geometry.coordinates,3) >= 2
        for c=1:size(Buildings(b).geometry.coordinates,3)
            pv = squeeze(Buildings(b).geometry.coordinates(c,:,:));
            if c==1
                newBuildings(b).geometry.coordinates = [pv; NaN NaN];
            elseif c<size(Buildings(b).geometry.coordinates,3)
                newBuildings(b).geometry.coordinates = [newBuildings(b).geometry.coordinates; pv; NaN NaN];
            else
                newBuildings(b).geometry.coordinates = [newBuildings(b).geometry.coordinates; pv];
            end
        end     
    elseif ndims(Buildings(b).geometry.coordinates) == 2
        %do nothing
    else
        warning(['I dont know what building ' num2str(b) ' is'])
    end
end
field = 'type';
newBuildings = rmfield(newBuildings,field);
for b=1:n
    disp(newBuildings(b).geometry);
    newBuildings(b).geometry = rmfield(newBuildings(b).geometry,field);
    disp(newBuildings(b).geometry);
end    

Buildings = newBuildings;
save('Blockage_Data/Milan_Buildings_4.mat','Buildings');
