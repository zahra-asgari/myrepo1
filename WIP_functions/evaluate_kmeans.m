clear all;
clc;
load('Blockage_Data/sector_data.mat');
load('Blockage_Data/k-means_data.mat');
k=20;
SCORES = 0;
CLUSTERS = 0;
OPT_K = 1;
SAVE_FIG = 0;
if not(exist('clust','var'))
    clust = zeros(size(coordinates,1),k);
    centroids = cell(k,1);
    sumdist = cell(k,1);

    for i=1:k
        [clust(:,i), centroids{i}, sumdist{i}] = kmeans(coordinates,i,'Distance','cityblock','Display','final','MaxIter',1000,'Options',statset('UseParallel',1));
    end
    save('Blockage_Data/refactor_map.mat','clust','centroids','sumdist','-append');
end

if SCORES
    ch_handle = subplot(1,2,1);
    % if not(exist('eva_ch','var'))
        eva_ch = evalclusters(coordinates,clust,'CalinskiHarabasz');
        save("Blockage_Data/refactor_map.mat","eva_ch","-append");
    % end
    plot(ch_handle,1:k,eva_ch.CriterionValues);
    hold on;
    scatter(eva_ch.OptimalK,eva_ch.CriterionValues(eva_ch.OptimalK),40,'ro');
    title(ch_handle,'Calinski-Harabasz')
    xlabel(ch_handle,'Number of Clusters')
    db_handle = subplot(1,2,2);
    % if not(exist('eva_db','var'))
        eva_db = evalclusters(coordinates,clust,'DaviesBouldin');
        save("Blockage_Data/refactor_map.mat","eva_db","-append");
    % end
    plot(db_handle,1:k,eva_db.CriterionValues);
    hold on;
    scatter(eva_db.OptimalK,eva_db.CriterionValues(eva_db.OptimalK),40,'ro');
    title(db_handle,'Davies-Bouldin')
    xlabel(db_handle,'Number of Clusters')
end
if OPT_K
    figure('WindowState','maximized');
    hold on;
    axis equal;
    title(['K=' num2str(eva_ch.OptimalK)]);
    best_k_h = gscatter(coordinates(:,1),coordinates(:,2),clust(:,eva_ch.OptimalK),clr);
    % h_leg = legend;
    % set(h_leg,'visible','off');
    if not(exist('sector_poly','var'))
        sector_boundaries = cell(eva_ch.OptimalK,1);
        internal_coords = cell(eva_ch.OptimalK,1);
        sector_poly = cell(eva_ch.OptimalK,1);
        for i=1:eva_ch.OptimalK
            a = find(clust(:,11)==i);
            internal_coords{i} = coordinates(a,:);
            sector_boundaries{i} = boundary(internal_coords{i}(:,1),internal_coords{i}(:,2));
            sector_poly{i} = internal_coords{i}(sector_boundaries{i},:);
        end
        city_boundaries = boundary(coordinates(:,1),coordinates(:,2));
        city_poly = coordinates(city_boundaries,:);
        save('Blockage_Data/refactor_map.mat','city_poly','sector_poly','-append');
    end
for i=1:eva_ch.OptimalK
    plot(sector_poly{i}(:,1),sector_poly{i}(:,2),'Color','r','LineWidth',2,'HandleVisibility','off');    
end
plot(city_poly(:,1),city_poly(:,2),'Color','g','LineWidth',3,'HandleVisibility','off');
text(centroids{eva_ch.OptimalK}(:,1),centroids{eva_ch.OptimalK}(:,2),{'1','2','3','4','5','6','7','8','9','10','11'});
end
if CLUSTERS
    grid = k;
    if isprime(k)
        grid = grid + 1;
    end
    square = sqrt(grid);
    div=divisors(grid);
    sides=zeros(2,1);
    mindist = Inf;
    for cy=1:numel(div)
        if (abs(square - div(cy)) < mindist)
            mindist = abs(square - div(cy));
            if div(cy) > k/div(cy)
                sides(1) = div(cy);
                sides(2) = grid/div(cy);
            else
                sides(2) = div(cy);
                sides(1) = grid/div(cy);
            end
        end

    end
    cluster_handle = figure('units','normalized','outerposition',[0 0 1 1]);
    for m=1:k
        cluster_handle(m) = subplot(sides(1),sides(2),m);
        hold on;
        axis equal;
        title(cluster_handle(m), ['K=' num2str(m)]);
        gscatter(coordinates(:,1),coordinates(:,2),clust(:,m));
        h_leg = legend(cluster_handle(m));
        set(h_leg,'visible','off');
    end
end
if SAVE_FIG
end

