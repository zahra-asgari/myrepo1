load('C:/Users/paolo/MATLAB/Projects/RIS-Planning-Instance-Generator/Blockage_Data/refactor_map.mat', 'all_sides')
mean_samples = zeros(10,1);
samp_freq = 0.1:0.1:1;
for sf=1:10
    for i=1:numel(all_sides)   
        a = numel(linspace(0,all_sides(i),((ceil(all_sides(i))+1)/samp_freq(sf))));
        % disp([num2str(all_sides(i)) ' ' num2str(a)]);
        mean_samples(sf) = mean_samples(sf) + a;
    end
end
mean_samples = mean_samples/numel(all_sides);