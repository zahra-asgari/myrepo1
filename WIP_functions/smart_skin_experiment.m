clear all;
clc;
PLOT3D = 1; %plotta gli edifici 3d e basta
PLOTCOORD = 0; % plotta la griglia di punti in 2D in base alla condizione di LoS
PLOTAZ = 1;
ROOF_EXP_1 = 0; % tutti i dispositivi sui tetti del DEIB e 24
LARGE = 0; %usa la SS con lo spotlight largo, se no usa quella col pencil beam
%uso i dati del 2020 per l'esperimento della smart skin, non ci sono
%edifici senza altezza nell'area DEIB
BS_sector = '24'; %either CityLife or 24

load('/Users/paolo/MATLAB/projects/RIS-Planning-Instance-Generator/Blockage_Data/2020_Milan_Buildings_1.mat');
if isfile("Blockage_Data/smart_skin_data.mat")
    load("Blockage_Data/smart_skin_data.mat")
    COORDS = 1; %non calcola l'ostruzione dei link a terra
else
    COORDS = 0; %calcola l'ostruzione dei link sui tetti del DEIB e 24
end

if LARGE
    el = smart_skin_elevations.large40x55;
else
    el = smart_skin_elevations.pencil27x27; %TBD
end
%per ora lo faccio così, al massimo dopo lo possiamo rendere dinamico in
%base alla distanza dalla BS/UE

bl.Buildings = Buildings;
bl.max_side = 3.709237921710240e+02; %valore di distanza massima di un edificio calcolato dal vecchio esperimento
threeD = 1;
center = [0.518231035 5.035901012]*1e6; %DEIB
BS = [518175.245 5036153.217 25]; %Coordinate della Base Station sul tetto del DEIB
switch BS_sector
    case 'CityLife'
        BS_tilt = 0;
        BS_orientation = deg2rad(180); % direzione principale dell'antenna, per definire il range in
        %azimut dei beam generati. 180° punta verso ovest (city life)
    case '24'
        BS_tilt = deg2rad(-2); %2 gradi di tilt, verrà corretto in base al valore vero. Permette anche di determinare il range in elevazione dei beam
        BS_orientation = deg2rad(0); % direzione principale dell'antenna, per definire il range in
        %azimut dei beam generati. 180° punta verso ovest (city life)
end
BS_az_span = deg2rad(60);
BS_el_span = deg2rad(15);
DEIB = [518127 5036150; 518221 5036180];
ED24 = [518332 5036010; 518353 5036030];
if LARGE
    area_width = deg2rad(60);
    area_az_min = deg2rad(74.4);
    area_az_max = area_az_min + area_width;
else
    area_width = 2/7;
    area_az_min = deg2rad(110) - area_width/2;
    area_az_max = deg2rad(110) + area_width/2;
end
site_width = 600;
scenario = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel();
site_polygon = nsidedpoly(4,'Center',center,'SideLength', site_width);
tempBuildings = pruneBuildings(site_width,bl,center,site_polygon);
n = numel(tempBuildings);
BS_az = deg2rad(50);

if PLOT3D
    site_handle = figure;
    site = plot(site_polygon,'DisplayName','Cell Area','EdgeColor',[251 192 45]./255,'LineWidth',4);
    hold on;
    ax = gca;
    ax.Clipping = 'off';
end
all_buildings = [];
roof_buildings = [];
for b=1:n

    xy = reformat_building(tempBuildings(b).geometry.coordinates,'no-loop');
    z = tempBuildings(b).properties.UN_VOL_AV;
    all_buildings=[all_buildings;xy repmat([z b],[size(xy,1),1]); NaN NaN NaN NaN];
    pv = tempBuildings(b).geometry.coordinates;
    if any(all(xy > DEIB(1,:) & xy < DEIB(2,:),2)) || any(all(xy > ED24(1,:) & xy < ED24(2,:),2))
        roof_buildings = [roof_buildings; xy repmat([z b],[size(xy,1),1]); NaN NaN NaN NaN];
    end
    if PLOT3D
        if threeD
            h = plotsolid(pv,tempBuildings(b).properties.UN_VOL_AV);
            h.c.HandleVisibility = 'off';
            h.s.HandleVisibility = 'off';
        else
            h = plot(polyshape(pv));
            hold on;
            h.FaceAlpha = 1;
            h.FaceColor = [0.8627 0.8627 0.8627];
        end
    end

end
if PLOT3D
    axis equal off;
    ax2 = gca;
    ax2.Clipping = 'off';
    % legend('Location','best')
    % view([45 45]);
    scatter3(BS(1),BS(2),BS(3),100,"rpentagram",'filled');
end
if not(isempty(all_buildings))
    map = polyshape(all_buildings(:,1:2));

else
    map = polyshape.empty;
end
if not(isempty(map))
    streets = subtract(site_polygon,map);
else
    streets = site_polygon;
end
square_size_m = 10; %one sample every x meters, uses dividends of 600
coord_x = linspace(center(1) - site_width/2, center(1) + site_width/2,(site_width/square_size_m+1))';
coord_y = linspace(center(2) - site_width/2, center(2) + site_width/2,(site_width/square_size_m+1))';
[bitmap_x, bitmap_y] = meshgrid(coord_x, coord_y);
vect_x = reshape(bitmap_x,[],1);
vect_y = reshape(bitmap_y,[],1);
coord = [vect_x, vect_y];
if ~COORDS
    pruning_matrix = inpolygon(coord(:,1),coord(:,2),streets.Vertices(:,1),streets.Vertices(:,2));
    coord = coord.*pruning_matrix;
    coord = coord(~all(coord == 0, 2),:); %prune points outside the site streets
    % coord(coord(:,2)>BS(2),:) = []; %prune points north of the BS
end
if ROOF_EXP_1
    roof_map = polyshape(roof_buildings(:,1:2));
    roof_square_size_m = 1; %sample every 0.5 meters on the roofs
    roof_coord_x = linspace(center(1) - site_width/2, center(1) + site_width/2,(site_width/roof_square_size_m+1))';
    roof_coord_y = linspace(center(2) - site_width/2, center(2) + site_width/2,(site_width/roof_square_size_m+1))';
    [roof_bitmap_x, roof_bitmap_y] = meshgrid(roof_coord_x, roof_coord_y);
    roof_vect_x = reshape(roof_bitmap_x,[],1);
    roof_vect_y = reshape(roof_bitmap_y,[],1);
    roof_coord = [roof_vect_x, roof_vect_y];
    roof_pruning_matrix = inpolygon(roof_coord(:,1),roof_coord(:,2),roof_map.Vertices(:,1),roof_map.Vertices(:,2));
    roof_coord = roof_coord.*roof_pruning_matrix;
    roof_coord = roof_coord(~all(roof_coord == 0, 2),:); %prune points outside of the two experiment buildings
end
if PLOTCOORD
    street_handle = figure;
    plot(streets,"FaceAlpha",0.2);
    hold on; axis equal off;
    scatter(BS(1),BS(2),100,"bpentagram",'filled');
end
if ~COORDS
    link_num = 2*(size(coord,1));
    direct_link = zeros(link_num,3);
    counter = 0;
    for d=1:size(coord,1)
        counter = counter +1;
        direct_link(2*counter-1:2*counter,1:2) = [BS(1) BS(2);...
            coord(d,1) coord(d,2)];
    end

    batch_num = 200; %split in batches to speed up calculation
    pruning_struct = zeros(size(coord,1),1);
    direct_link(:,3)=repmat([BS(3);scenario.radio.ue_height],[link_num/2,1]);
    for batch=1:ceil(link_num/batch_num)
        if batch*batch_num <= link_num
            max_val = batch*batch_num;
        else
            max_val = link_num;
        end
        pruning_struct((batch-1)*100+1:max_val/2,1) = check_vector_obstruction(all_buildings,direct_link((batch-1)*batch_num+1:max_val,:))';
        disp(['Batch ' num2str(batch) ' of ' num2str(ceil(link_num/batch_num)) '...'])
    end
    ue_coord = coord;
    ss_coord = coord;
    ue_coord(~(pruning_struct),:) = [];
    ss_coord(pruning_struct==1,:) = [];

        link_num = 2*(size(roof_coord,1));
    direct_link = zeros(link_num,3);
    counter = 0;
    for d=1:size(roof_coord,1)
        counter = counter +1;
        direct_link(2*counter-1:2*counter,1:2) = [BS(1) BS(2);...
            roof_coord(d,1) roof_coord(d,2)];
    end

    batch_num = 200; %split in batches to speed up calculation
    pruning_struct = zeros(size(roof_coord,1),1);
    direct_link(:,3)=repmat([BS(3);BS(3)],[link_num/2,1]);
    for batch=1:ceil(link_num/batch_num)
        if batch*batch_num <= link_num
            max_val = batch*batch_num;
        else
            max_val = link_num;
        end
        pruning_struct((batch-1)*100+1:max_val/2,1) = check_vector_obstruction(all_buildings,direct_link((batch-1)*batch_num+1:max_val,:))';
        disp(['Batch ' num2str(batch) ' of ' num2str(ceil(link_num/batch_num)) '...'])
    end
    if ROOF_EXP_1
        roof_ue_coord = roof_coord;
        roof_ss_coord = roof_coord;
        roof_ue_coord(~(pruning_struct),:) = [];
        roof_ss_coord(pruning_struct==1,:) = [];
    end
else
    ue_coord = intersect(coord,ue_coord,'rows');
    ss_coord = intersect(coord,ss_coord,'rows');
    if ROOF_EXP_1
        roof_ue_coord = intersect(roof_coord,roof_ue_coord,'rows');
        roof_ss_coord = intersect(roof_coord,roof_ss_coord,'rows');
    end
end
n_ss = size(ss_coord,1);
n_ue = size(ue_coord,1);
if PLOTCOORD
    figure(street_handle);
    ue_prune = scatter(ue_coord(:,1),ue_coord(:,2),10,'red','filled');
    ss_prune = scatter(ss_coord(:,1),ss_coord(:,2),10,'green','filled');
    if ROOF_EXP_1
        roof_ue_prune = scatter(roof_ue_coord(:,1),roof_ue_coord(:,2),10,'red','filled');
        roof_ss_prune = scatter(roof_ss_coord(:,1),roof_ss_coord(:,2),10,'green','filled');
    end
else
    ue_prune = scatter3(ue_coord(:,1),ue_coord(:,2),repmat(scenario.radio.ue_height,[n_ue 1]),10,'red','filled');
    ss_prune = scatter3(ss_coord(:,1),ss_coord(:,2),repmat(scenario.radio.ris_height,[n_ss 1]),10,'green','filled');
    if ROOF_EXP_1
        roof_ue_prune = scatter(roof_ue_coord(:,1),roof_ue_coord(:,2),10,'red','filled');
        roof_ss_prune = scatter(roof_ss_coord(:,1),roof_ss_coord(:,2),10,'green','filled');
    end
end
if ~isfile("Blockage_Data/smart_skin_data.mat")
    save("Blockage_Data/smart_skin_data.mat","ss_coord","ue_coord","roof_ss_coord","roof_ue_coord");
end

ss_BS_angles = zeros(n_ss,1);
ss_az_orientation = zeros(n_ss,1);
for n=1:n_ss
    
        offset = ss_coord(n,:);
        relative_BS_position2D = BS(1:2) - offset;
        ss_BS_angles(n) = wrapTo2Pi(angle(relative_BS_position2D(1) +1i*relative_BS_position2D(2)));
        start = wrapTo2Pi(BS_orientation - BS_az_span);
        disp(rad2deg(wrapTo2Pi(wrapTo2Pi(ss_BS_angles(n)+pi) - start)))
    if wrapTo2Pi(wrapTo2Pi(ss_BS_angles(n)+pi) - start) <= 2*BS_az_span %this check considers only CSs for the SS inside the BS FoV
        ss_az_orientation(n) = wrapTo2Pi(ss_BS_angles(n) - BS_az);

        % disp(['BS position wrt SS: ' num2str(rad2deg(ss_BS_angles(n))) '°, SS az orientation: ' num2str(rad2deg(ss_az_orientation(n))) '°']);
        if exist('current_ss','var')
            delete(current_ss);
            delete(ss_drawing);
            delete(BS_link);
        end
        if PLOTAZ
            % figure(street_handle);
            current_ss = scatter(ss_coord(n,1),ss_coord(n,2),20,'k','filled');
            ss_edges = [ss_coord(n,1)-10 ss_coord(n,1)+10; ss_coord(n,2) ss_coord(n,2)];
            ss_center = repmat(ss_coord(n,:)', 1, 2);
            rot_matr = [cos(ss_az_orientation(n)) -sin(ss_az_orientation(n));...
                sin(ss_az_orientation(n)) cos(ss_az_orientation(n))];
            edge_shift = ss_edges - ss_center;
            rot = rot_matr*edge_shift;
            ss_edges = rot + ss_center;
            ss_drawing = plot(ss_edges(1,:),ss_edges(2,:),'k','LineWidth',2);
            BS_link = plot([ss_coord(n,1) BS(1)],[ss_coord(n,2) BS(2)],'Color',"#EDB120",'LineStyle','--','LineWidth',2);
            drawnow
            % exportgraphics(gcf,'SmartSkinAzimuthOrientation.gif','Append',true);

        end
    end

end

% ss_ue_angles = zeros(n_ss,n_ue);
% for s=1:n_ss
%     offset = ss_coord(s,:);
%     if exist('current_ss','var')
%         delete(current_ss);
%     end
%     current_ss = scatter(ss_coord(s,1),ss_coord(s,2));
%     for t=1:n_ue
%         relative_ue_position = ue_coord(t,:) - offset;
%         ss_ue_angles(s,t) = angle(relative_ue_position(1) +1i*relative_ue_position(2))*180/pi; %1i is the imaginary unit
%         if ss_ue_angles(s,t) < 0
%             ss_ue_angles(s,t) = wrapTo2Pi(ss_ue_angles(s,t));
%         end
%         % disp(ss_ue_angles(s,t));
%         if exist('current_ue','var')
%             delete(current_ue);
%         end
%         current_ue = scatter(ue_coord(t,1),ue_coord(t,2));
%     end
% end


%selezionato gli edifici
%griglia punti da prendere da free_space_index
%TODO:
%      intersezione tra posizione BS e tutti i punti, trovare punti
%      potenziali per UE
%      applicare a questi punti (o a un subset selezionato) il check Smart
%      Skin con un set di altezze (l'azimut dipende dalle coordinate x-y
%      che abbiamo già e l'elevazione dall'altezza, quindi l'unica
%      dimensione per ogni punto è l'altezza. Magari basta un'altezza sola,
%      lo faccio per scrupolo per vedere se ci sono punti per i quali va
%      bene una sola specifica altezza)

