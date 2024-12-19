scenario_struct = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel();
load("Blockage_Data/Milan_Buildings_5.mat","Buildings");
Blockage.Buildings = Buildings;
Blockage.max_side = 370.9238;
for inst=1:100

    site_cache_id = DataHash([DataHash(scenario_struct.site) num2str(inst)]); % hash is salted with rng_seed, since the site data is generated randomly
    site_cache_path = ['cache/' site_cache_id '.mat'];
    if isfile(site_cache_path)
        load(site_cache_path,'cs_positions');
    else
        disp("Site cache not found!!")
        continue;

    end
    center = [cs_positions(end,1)+ scenario_struct.site.site_width/2, cs_positions(end,2)];
    site_polygon = nsidedpoly(6,'Center',center,'SideLength',scenario_struct.site.site_width/2);
    siteBuildings = pruneBuildings(scenario_struct.site.site_width,Blockage,center);
    n=numel(siteBuildings);
    pv = [];
    for b=1:n
        xy = reformat_building(siteBuildings(b).geometry.coordinates,'loop');
        z = siteBuildings(b).properties.UN_VOL_AV;
        pv=[pv;xy repmat([z b],[size(xy,1),1]); NaN NaN NaN NaN];
    end
    if not(isempty(pv))
        map = polyshape(pv(:,1:2));
        % free_area=zeros(n_sectors,1);
        % for i=1:n_sectors
        %     free_area(i) = area(subtract(spl(i),map))/area(spl(i));
        % end
    else
        map = polyshape.empty;
        % free_area = ones(n_sectors,1);
    end
    number=inst;
    plot(subtract(site_polygon,map),'HandleVisibility','off');
    hold on;
    % text(center(1),center(2),num2str(number),'FontSize',30);
    drawnow
end
axis equal;