function custom_marker(scatter_set, png)
    x = scatter_set.XData;
    y = scatter_set.YData;

    marker = png;

    markersize = [0.4,1.5]; %//The size of marker is expressed in axis units, NOT in pixels
    x_low = x - markersize(1)/2; %//Left edge of marker
    x_high = x + markersize(1)/2;%//Right edge of marker
    y_low = y - markersize(2)/2; %//Bottom edge of marker
    y_high = y + markersize(2)/2;%//Top edge of marker

    for k = 1:length(x)
        imagesc([x_low(k) x_high(k)], [], [y_low(k) y_high(k)], marker)
        hold on
    end
end