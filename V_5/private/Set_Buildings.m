function [Params]= Set_Buildings(Address,Name,Params)

A = load([Address,'/',Name]);
Building_Edges = A.Buildings;
Params.Buildings = cell(1,length(Building_Edges));
% load('Blockage_Data/leonardoBuildings.mat');
% figure; hold on;
figure
for i = 1:length(Building_Edges)
    
    Params.Buildings{1,i} = polyshape(Building_Edges{1,i}(:,1),Building_Edges{1,i}(:,2));
    %     patch( Params.Buildings{1,i}(:,1),  Params.Buildings{1,i}(:,2), [217, 217, 217]/255);
    %     hold on
    
    plot(Params.Buildings{1,i})
    hold on
end

end

