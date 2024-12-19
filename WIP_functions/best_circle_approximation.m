n_sides = 100;
area_gain = zeros(n_sides-2,1);
side_cost = zeros(n_sides-2,1);
side = 1;
for i=3:n_sides
    r = 0.5*side*csc(pi/i);
    area_circle = pi*r^2;
    pg = nsidedpoly(i,'SideLength',side);
    area_gain(i-2) = area(pg)/area_circle;
    side_cost(i-2) = side/r;
    plot(pg)
    axis equal;
    hold on;
    drawnow
end




