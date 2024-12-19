clear;
clc;
%load('/home/paolo/projects/RIS-Planning-Instance-Generator/Blockage_Data/buildingtestset.mat');
% load('/Users/paolo/MATLAB/projects/RIS-Planning-Instance-Generator/Blockage_Data/Milan_Buildings_5.mat');
%bl works only with the 2012 data
% bl.Buildings = Buildings;
% bl.max_side = max_side;

%uso i dati del 2020 per l'esperimento della smart skin, non ci sono
%edifici senza altezza nell'area DEIB
load('/Users/paolo/MATLAB/projects/RIS-Planning-Instance-Generator/Blockage_Data/2020_Milan_Buildings_1.mat');
bl.Buildings = Buildings;
bl.max_side = 3.709237921710240e+02; %valore di distanza massima di un edificio calcolato dal vecchio esperimento


%load('/home/paolo/projects/RIS-Planning-Instance-Generator/Blockage_Data/plot_height.mat','center','cs_positions','tp_positions');
%load('/home/paolo/projects/RIS-Planning-Instance-Generator/Blockage_Data/newpruning.mat','pruning_matrix_bh','pruning_matrix_ref1');
%load('/home/paolo/projects/RIS-Planning-Instance-Generator/Blockage_Data/site_data.mat')
% run('/home/paolo/projects/RIS-Planning-Instance-Generator/solved_instances/extra_100/hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel19.2_100runs/solutions/iab_ris_fixedDonor_fakeRis_blockageModel_sumextra_run50.m')


count = zeros(3,1);
threeD = 1;
% center = [0.517840, 5.036085]*1e6; %Polimi
%center = [0.515721548, 5.036825512]*1e6; %Pirellone
% center = [0.514979685, 5.034531874]*1e6; %Duomo
% center = [0.514070294, 5.035177579]*1e6; %Castello Sforzesco
%center = [0.513478063, 5.035808645]*1e6; %Arco della Pace
% center = [0.514882824, 5.036676153]*1e6; %Piazza Gae Aulenti
% center = [0.512178893, 5.035946418]*1e6; %City Life
%center = [0.514257550264988   5.035961232455120]*1e6;
% center = [0.518242204 5.035891666]*1e6;
% center = [0.517148265 5.036324419]*1e6; %Selezione per journal
center = [0.518231035 5.035901012]*1e6; %DEIB
diameter = 600;
% site_polygon = nsidedpoly(6,'Center',center,'SideLength', diameter/2);
site_polygon = nsidedpoly(4,'Center',center,'SideLength', diameter);
tempBuildings = pruneBuildings(diameter,bl,center,site_polygon);
n = numel(tempBuildings);
hexa = plot(site_polygon,'DisplayName','Cell Area','FaceAlpha',0.25,'EdgeColor',[251 192 45]./255,'LineWidth',4);
hold on;
ax = gca;
ax.Clipping = 'off';

%coordinates

%link_coord = [ (center(1) +150), (center(1) -132);(center(2) -108), (center(2) +131); 25, 1.5];
% if threeD
%     plot3(link_coord(1,:),link_coord(2,:),link_coord(3,:),'LineWidth',3,'Color','g');
%     view(30,30);
% else
%     plot(link_coord(1,:),link_coord(2,:),'LineWidth',3,'Color','g');
% end

for b=1:n
    count(3) = count(3) +1;

    pv = tempBuildings(b).geometry.coordinates;

    if threeD
        h = plotsolid(pv,tempBuildings(b).properties.UN_VOL_AV);
        % h.f.HandleVisibility = 'off';
        h.c.HandleVisibility = 'off';
        h.s.HandleVisibility = 'off';
        %             if checkobstruction(pv,Buildings(b).properties.UN_VOL_AV,link_coord)
        %                 h.f.FaceColor = 'r';
        %                 h.c.FaceColor = 'r';
        %                 h.s.FaceColor = 'r';
        %                 %                     h(1).FaceColor = 'r';
        %             end
    else
        h = plot(polyshape(pv));
        hold on;
        h.FaceAlpha = 1;
        h.FaceColor = [0.8627 0.8627 0.8627];
        %             if checkobstruction(pv,Buildings(b).properties.UN_VOL_AV,link_coord)
        %                 h.FaceColor = 'r';
        %             end
    end

end


% cs=scatter3(cs_positions(2:end-1,1),cs_positions(2:end-1,2),repmat(6,[size(cs_positions,1)-2,1]),50,'^r','filled','DisplayName','Candidate Sites');
% don=scatter3(cs_positions(end,1),cs_positions(end,2),25,100,'^k','filled','DisplayName','Donor');
% tp=scatter3(tp_positions(:,1),tp_positions(:,2),repmat(1.5,[size(tp_positions,1),1]),50,'*b','DisplayName','Test Points');
% n_cs = size(cs_positions,1);
% n_tp = size(tp_positions,1);
% for i=2:n_cs
%     for j=2:n_cs
%         if i~=j && pruning_struct.bh(i,j)
%             if i~=n_cs
%                 h=plot3([cs_positions(i,1) cs_positions(j,1)],[cs_positions(i,2) cs_positions(j,2)],[6 6],'r');
%             else
%                 h = plot3([cs_positions(i,1) cs_positions(j,1)],[cs_positions(i,2) cs_positions(j,2)],[25 6],'r');
%             end
%         end
%         h.HandleVisibility = 'off';
%     end
%     for j=1:n_tp
%         if pruning_struct.dir(i,j)
%             if i~=n_cs
%                 h=plot3([cs_positions(i,1) tp_positions(j,1)],[cs_positions(i,2) tp_positions(j,2)],[6 1.5],'g');
%             else
%                 h = plot3([cs_positions(i,1) tp_positions(j,1)],[cs_positions(i,2) tp_positions(j,2)],[25 1.5],'r');
%             end
%         end
%         h.HandleVisibility = 'off';
%     end
% end
% for i=2:n_cs
%     if i~=n_cs
%         h=plot3([cs_positions(i,1) cs_positions(i,1)],[cs_positions(i,2) cs_positions(i,2)],[6 0],'k');
%     else
%         h=plot3([cs_positions(i,1) cs_positions(i,1)],[cs_positions(i,2) cs_positions(i,2)],[25 0],'k');        
%     end
%     h.HandleVisibility = 'off';
% end

axis equal;
% legend('Location','best')
%view([0 30])

% function handle = plotsolid(xy,z)
% 
% % tr = triangulation(polyshape(xy));
% % tnodes = tr.Points';
% % telements = tr.ConnectivityList';
% % model = createpde;
% % geometryFromMesh(model,tnodes,telements);
% % g = model.Geometry;
% % handle = pdegplot(extrude(g,z));
% % hold on;
% % delete(findobj(gcf,'type','Quiver'));
% 
% handle.f = patch(xy(:,1),xy(:,2),[0.8627 0.8627 0.8627]);  
% hold on;% face wall
% handle.c = patch(xy(:,1),xy(:,2),xy(:,1)*0+z,[0.8627 0.8627 0.8627]);   % back wall
% handle.s = surface([xy(:,1) xy(:,1)],[xy(:,2) xy(:,2)],[xy(:,1)*0 xy(:,1)*0+z],'facecolor',[0.8627 0.8627 0.8627]);
% 
% end
% sdf('Scenario');


% view([45 45]);
axis off;

scatter3(518175.245, 5036153.217,30,100,"rpentagram",'filled');

function [blocked] = checkobstruction(xy,z,link)

c = link(3,2) - link(3,1);
if ~c    
    if link(3,1) <= z
        [in3,~] = intersect(polyshape(xy),[link(1:2,1)';link(1:2,2)']);
        if ~isempty(in3)
            disp("Blocked! IAB2IAB case");
            blocked = 1;
        end
    else        
        disp("Not Blocked. IAB2IAB case");
        blocked = 0;        
    end        
else    
    t = (z - link(3,1))/c;    
    if link(1,1) == link(1,2)        
        x_p = link(1,1);        
    else       
        x_p = link(1,1) + t*(link(1,2) - link(1,1));      
    end
    if link(2,1) == link(2,2)       
        y_p = link(2,1);       
    else       
        y_p = link(2,1) + t*(link(2,2) - link(2,1));      
    end   
    [in3,~] = intersect(polyshape(xy),[[x_p y_p];link(1:2,2)']);    
    if ~isempty(in3)
        disp("Blocked!! Access case");
        blocked = 1;
    else
        disp("Not Blocked. Access case");
        blocked = 0;
    end   
end
end


