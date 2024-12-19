clear all;
% Define the radius for the sphere
sphereRadius = 30;

LARGE = 0; %If Larger SS, load the right values, if not load the other ones

%NB: sul datasheet della SS piccola la misura è 27x27 cm, mentre quella che
%abbiamo in lab è 22x22 cm circa

% Create a sphere
[sphereX, sphereY, sphereZ] = sphere(100);

% Scale the sphere by the radius
sphereX = sphereX * sphereRadius;
sphereY = sphereY * sphereRadius;
sphereZ = sphereZ * sphereRadius;

% Center the sphere at (0, 0, 5)
sphereCenter = [0, 0, 0];
sphereX = sphereX + sphereCenter(1);
sphereY = sphereY + sphereCenter(2);
sphereZ = sphereZ + sphereCenter(3);

% Define a light blue color for the sphere (RGB)
sphereColor = [0.7, 0.7, 1.0];

% Plot the sphere
figure;
sphereHandle = surf(sphereX, sphereY, sphereZ, 'FaceColor', sphereColor, 'EdgeColor', 'none', 'FaceAlpha', 0.5);

hold on;  % Hold the current axis for multiple plots

% Define the size of the plane
planeSize = 60;

% Define the coordinates of the plane
xPlane = linspace(-planeSize, planeSize, 100);
yPlane = linspace(-planeSize, planeSize, 100);
[xPlane, yPlane] = meshgrid(xPlane, yPlane);
zPlane = zeros(size(xPlane));  % z-coordinate at 0

% Define the color for the plane (e.g., green)
planeColor = [0.2, 0.8, 0.2];

% Plot the plane
planeHandle = surf(xPlane, yPlane, zPlane, 'FaceColor', planeColor, 'EdgeColor', 'none', 'FaceAlpha', 0.2);
if LARGE
    % Rectangle dimensions
    width = 0.40;  % Width of the rectangle
    height = 0.55;  % Height of the rectangle

    % Center coordinates
    center_x = 0;  % x-coordinate of the center
    center_y = 0;  % y-coordinate of the center
    center_z = 5;  % z-coordinate of the center
    % Define radii
    outer_radius = 29;
    inner_radius = 24;
    % Shift the sector to start at 74.4 degrees
    theta_start = 74.4;
    theta_end = theta_start + 60; % 60 degrees
    % Generate an array of angles
    theta = linspace(deg2rad(theta_start), deg2rad(theta_end), 100);
else
    % Rectangle dimensions
    width = 0.27;  % Width of the rectangle
    height = 0.27;  % Height of the rectangle
    % Center coordinates
    center_x = 0;  % x-coordinate of the center
    center_y = 0;  % y-coordinate of the center
    center_z = 1.5;  % z-coordinate of the center
    % Define radii
    outer_radius = 8;
    inner_radius = 6;
    theta_center = deg2rad(110);
    theta_span = 2/7; %angle calculated by having approximately a 2x2=4sqm area
    % Shift the sector to start at 74.4 degrees
    theta_start = theta_center - theta_span/2;
    theta_end = theta_center + theta_span/2; % circa 16.37 degrees
    % Generate an array of angles
    theta = linspace(theta_start, theta_end, 30);
end

%sull'immagine del ppt è segnato che l'elevazione del raggio riflesso è
%-45°, ma chiaramente per avere un angolo del genere il triangolo
%dev'essere circa rettangolo, quindi o la distanza è a 1.5 m o la smart
%skin è a 7 metri d'altezza.

% Calculate the corner coordinates
ax = gca;
ax.Clipping = "off";
% Plot the rectangle
% Calculate the corner coordinates
x = center_x - width/2;
y = center_y;
z = center_z - height/2;

% Define rectangle vertices
vertices = [x, y, z;
            x+width, y, z;
            x+width, y, z+height;
            x, y, z+height];


% Define rectangle faces
faces = [1, 2, 3, 4];

% Plot the rectangle using patch
ss=patch('Vertices', vertices, 'Faces', faces, 'FaceColor', 'b', 'EdgeColor', 'b');




% Calculate coordinates of the outer circle
x_outer = outer_radius * cos(theta);
y_outer = outer_radius * sin(theta);

% Calculate coordinates of the inner circle
x_inner = inner_radius * cos(theta);
y_inner = inner_radius * sin(theta);

% Plot the filled area between the circles
pp= patch([x_outer, fliplr(x_inner)], [y_outer, fliplr(y_inner)], 'r', 'FaceAlpha', 1);

x_sector = [x_inner(end) x_inner(1) x_outer(end) x_outer(1)];
x_rect = [vertices(1,1) vertices(2,1) vertices(4,1) vertices(3,1)];
y_sector = [y_inner(end) y_inner(1) y_outer(end) y_outer(1)];
y_rect = [vertices(1,2) vertices(2,2) vertices(4,2) vertices(3,2)];
z_sector = [0 0 0 0];
z_rect = [vertices(1,3) vertices(2,3) vertices(4,3) vertices(3,3)];

for i = 1:4
    % plot3([x_rect(i), x_sector(i)], [y_rect(i), y_sector(i)], [z_rect(i), z_sector(i)],'k-', 'LineWidth', 2);
    plot3([center_x, x_sector(i)], [center_y, y_sector(i)], [center_z, z_sector(i)],'k-', 'LineWidth', 2);
    vector(i,:) = [center_x - x_sector(i) center_y - y_sector(i) center_z - z_sector(i)];
    el(i) = wrapToPi(atan2(norm(cross(vector(i,:), [0, 0, 1])), dot(vector(i,:), [0, 0, 1])));
end
el = el - pi/2;
disp(rad2deg(el));

% Plot the line starting at (0, 0, 5) and going outwards at a 40-degree azimuth angle
azimuth = 40;  % Azimuth angle in degrees
radius = 30;  % Distance from the origin

% Convert azimuth angle to radians
azimuth_rad = deg2rad(azimuth);

% Calculate the coordinates of the end point of the line
x_line_end = radius * cos(azimuth_rad);
y_line_end = radius * sin(azimuth_rad);
z_line_end = center_z;

% Plot the line
gg=plot3([center_x, x_line_end], [center_y, y_line_end], [center_z, z_line_end],'r-', 'LineWidth', 2);


% Set axis limits

hold off;  % Release the current axis

% Set axis equal
axis equal;

% Set labels
xlabel('X-axis');
ylabel('Y-axis');
zlabel('Z-axis');

% Title
title('Smart Skin area projection');

% Display grid
grid on;
view([220 30]);
% view([270 0]);
