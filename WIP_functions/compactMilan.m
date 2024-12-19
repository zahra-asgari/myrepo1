clear all;
clc;
load('/home/paolo/projects/RIS-Planning-Instance-Generator/Blockage_Data/shape_Milan_Buildings.mat','Buildings');
shapeBuildings = Buildings;
load('/home/paolo/projects/RIS-Planning-Instance-Generator/Blockage_Data/onekind_Milan_Buildings.mat','Buildings');
n=numel(Buildings);
for b=1:n
    disp(Buildings(b).geometry.coordinates);
    Buildings(b).geometry.coordinates = shapeBuildings(b).shape.Vertices;
    disp(Buildings(b).geometry.coordinates);
end

save('/home/paolo/projects/RIS-Planning-Instance-Generator/Blockage_Data/nowarning_Milan_Buildings.mat','Buildings');
