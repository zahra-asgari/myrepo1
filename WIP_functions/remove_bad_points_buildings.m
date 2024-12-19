clear all;
clc;
load('Blockage_Data/Milan_Buildings_1.mat','Buildings');
newBuildings = Buildings;
n=numel(newBuildings);
for b=1:n
    if isa(Buildings(b).geometry.coordinates,'cell')
        for c=1:numel(Buildings(b).geometry.coordinates)
            pv = Buildings(b).geometry.coordinates{c};
            if pv(1,:)==pv(end,:)
                pv(end,:) = [];
            end
            newBuildings(b).geometry.coordinates{c} = pv;
        end

    elseif ndims(Buildings(b).geometry.coordinates) == 3 && size(Buildings(b).geometry.coordinates,3) >= 2
        for c=1:size(Buildings(b).geometry.coordinates,3)
            pv = permute(Buildings(b).geometry.coordinates,[2 3 1]);
            if pv(1,:,:)==pv(end,:,:)
                pv(end,:,:) = [];
            end
            newBuildings(b).geometry.coordinates = pv;
        end
    elseif ismatrix(Buildings(b).geometry.coordinates)
        pv = Buildings(b).geometry.coordinates;
        if pv(1,:)==pv(end,:)
            pv(end,:) = [];
        end
        newBuildings(b).geometry.coordinates = pv;
    else
        warning(['I dont know what building ' num2str(b) ' is'])
    end
end
field = 'type';
newBuildings = rmfield(newBuildings,field);
for b=1:n
%     disp(newBuildings(b).geometry);
    newBuildings(b).geometry = rmfield(newBuildings(b).geometry,field);
%     disp(newBuildings(b).geometry);
end    

Buildings = newBuildings;
save('Blockage_Data/Milan_Buildings_2.mat','Buildings');
