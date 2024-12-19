clear;
clc;
load('Blockage_Data/2020_Milan_Buildings_1.mat')
n = numel(Buildings);
count = zeros(5,1);
pl=1;

for b=1:n
    if isa(Buildings(b).geometry.coordinates,'cell')
        count(1) = count(1) +1;
            disp(['Building ' num2str(b) ' is in cell format'])
            if pl
                building = reformat_building(Buildings(b).geometry.coordinates,'no-loop');
                plot(polyshape(building));
                drawnow
            end
            hold off;

    elseif ndims(Buildings(b).geometry.coordinates) == 3 && size(Buildings(b).geometry.coordinates,3) >= 2
        count(2) = count(2) +1;
        disp(['Building ' num2str(b) ' is in vector format (' num2str(size(Buildings(b).geometry.coordinates,3)) ' curves)'])
        for c=1:size(Buildings(b).geometry.coordinates,3)
            %pv = squeeze(Buildings(b).geometry.coordinates(c,:,:));
            if pl
                building = reformat_building(Buildings(b).geometry.coordinates,'no-loop');
                plot(polyshape(building));
                drawnow
            end
            hold off;
        end
    elseif any(not(isfinite(Buildings(b).geometry.coordinates)),'all')
        count(3) = count(3) + 1;
        disp(['Building ' num2str(b) ' has been converted from vector format to NaN-separated format'])
        if pl
            building = reformat_building(Buildings(b).geometry.coordinates,'no-loop');
            plot(polyshape(building));
            drawnow
        end
        hold off;
    elseif ismatrix(Buildings(b).geometry.coordinates)
        count(4) = count(4) +1;
        pv = Buildings(b).geometry.coordinates;
        disp(['Building ' num2str(b) ' is in standard format'])
        if pl
            building = reformat_building(Buildings(b).geometry.coordinates,'no-loop');
            plot(polyshape(building));
            drawnow
        end
        hold off;
    else
        count(5) = count(5) + 1;
        disp(['I dont know what kind of building ' num2str(b) ' is'])

    end
end

disp(count);