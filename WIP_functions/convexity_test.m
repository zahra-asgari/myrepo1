load("Blockage_Data/sector_data.mat")
figure
hold on;
axis equal
coord_for_city = [];
for i=1:eva_ch.OptimalK
    plot(polyshape(sector_poly{i}));
    sect_hull_data = convhull(sector_poly{i});
    sect_hull = polyshape(sector_poly{i}(sect_hull_data,:));
    plot(sect_hull)
    coord_for_city = [coord_for_city; sector_poly{i}(1:end-1,:)];
end
city_poly_bound = boundary(coord_for_city,0.8);
plot(polyshape(coord_for_city(city_poly_bound,:)),'FaceAlpha',0,'LineWidth',3,'EdgeColor','r','LineWidth',3,'EdgeColor','r');
city_poly = coord_for_city(city_poly_bound,:);

% for i=1:eva_ch.OptimalK
%     load(['Blockage_Data/Milan_Sector_Buildings_' num2str(i) '.mat']);
%     n = numel(Sector_Buildings);
%     all_dotterinos = [];
%     for b=1:n
%         building = reformat_building(Sector_Buildings(b).geometry.coordinates,'loop');
%         % plot(polyshape(building));
%         if (sum(isnan(building),'all')>0)
%             idx = find(isnan(building));
%             idx = idx(1);
%             building = building(1:idx-1,:);
% 
%         end
%         all_dotterinos = [all_dotterinos; building];
%     end
%     bound = boundary(all_dotterinos);
%     bound_coord = all_dotterinos(bound,:);
%     sector_poly{i} = bound_coord;
%     % plot(polyshape(bound_coord));
%     chb = convhull(bound_coord);
%     % plot(polyshape(bound_coord(chb,:)));
% 
% end
% % save('Blockage_Data/refactor_map.mat',"sector_poly",'-append');
% 
% 
