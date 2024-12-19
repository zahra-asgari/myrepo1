%% Distance computation

%each element is the distance between two CSs or CS-TP
cs_cs_distance_matrix = squareform(pdist(cs_positions));
cs_tp_distance_matrix = pdist2(cs_positions, tp_positions);

if PLOT_DISTANCE_STATISTICS
    t = cs_cs_distance_matrix;
    t(cs_cs_distance_matrix==0) = NaN;
    figure();
    cdfplot(min(t,[],2,'omitnan'));
    title('cscs cdf');
    
    figure();
    cdfplot(min(cs_tp_distance_matrix,[],2));
    title('cstp cdf');
    clear t;
end

max_dist = sqrt(site_height^2 + site_width^2);