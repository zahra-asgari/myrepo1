function handle = plotsolid(building, h)
% function handle = plotsolid(xy, z)
% handle.f = patch(xy(:,1),xy(:,2),[0.8627 0.8627 0.8627]);  
% hold on;% floor
% handle.c = patch(xy(:,1),xy(:,2),xy(:,1)*0+z,[0.8627 0.8627 0.8627]);   % ceiling
% handle.s = surface([xy(:,1) xy(:,1)],[xy(:,2) xy(:,2)],[xy(:,1)*0 xy(:,1)*0+z],'facecolor',[0.8627 0.8627 0.8627]); %walls
building = reformat_building(building,'loop');

% Create a polyshape object from the building vertices
buildingShape = polyshape(building);

% Triangulate the building shape
triang = triangulation(buildingShape);
% Create the Z coordinates by extending the height
floor = zeros(size(triang.Points,1),1); % Set the base height to 0
ceiling = floor + h; % Add the height to all Z coordinates
red = 241;
green = 234;
blue = 220;
building_color = [red green blue]./255; %grey tint used in pde toolbox
edge_color = [132 105 53]./255;
% building_color = [0.8627 0.8627 0.8627];
% Plot the triangulated shape
handle.c =trisurf(triang.ConnectivityList, triang.Points(:, 1), triang.Points(:, 2), ceiling, 'FaceColor', building_color,'EdgeColor', 'None');
hold on;
% handle.f = trisurf(triang.ConnectivityList, triang.Points(:, 1), triang.Points(:, 2), floor, 'FaceColor', building_color,'EdgeColor', 'None');
handle.w = surface([building(:,1) building(:,1)],[building(:,2) building(:,2)],[building(:,1)*0 building(:,1)*0+h],'FaceColor',building_color,'LineWidth',0.25,'EdgeColor',edge_color); %walls

end

%20 sides to approximate circle: 162 degrees threshold