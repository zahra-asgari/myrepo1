function [] = plot_ris_sr_multi_final(workspace_struct,solution_struct,figure_style)
%PLOT_RIS_SR_MULTI_FINAL This function plots the solution according to the
%solution and generation structures given as input
%   Detailed explanation goes here

if nargin <= 2
    figure_style = [];
end

%% unpack structures
v2struct(workspace_struct);
v2struct(solution_struct);

%%
%tp_focus = { any tp-> plot curresponding src; -1 -> plot all}
% tp_focus = -1;
% PLOT_FAKERIS = 0;
% PLOT_OPTIDELTA = 1;

% if ~exist('run_once', 'var')
%     load(['solved_instances/' sim_folder dir_name_list{fldr} '/instances/' data_name])
%     run_once = 0;
% end
clear('size'); %clearing variable size loaded from solution such that we avoid bugs when callinng function size

RIS_MODEL = 1;

site_scatter = figure();
hold on;
grid on;

xlabel('Site Width [m]');
ylabel('Site Height [m]');
title('Planning Step 2');

%sites
scatter(cs_positions(:,1),cs_positions(:,2), 80,'xk');
scatter(tp_positions(:,1),tp_positions(:,2), 100,'dr','filled');

%populated sites
scatter(cs_positions(y_don == 1,1),cs_positions(y_don == 1,2),100,'og', 'filled');
scatter(cs_positions(xor(y_iab,y_don) == 1,1),cs_positions(xor(y_iab,y_don) == 1,2),100,'^b', 'filled');
scatter(cs_positions(y_ris == 1,1),cs_positions(y_ris == 1,2),100,'sm', 'filled');
scatter(cs_positions(y_sr == 1,1),cs_positions(y_sr == 1,2),100,'pm', 'filled');

legend_cells={'Construction Sites', 'Test Points', 'Donors', 'IAB nodes', 'RIS','SR'};
if ~strcmp(site.site_shape, 'rectangular')
    site_polygon = nsidedpoly(6,'Center',[site.site_width/2 site.site_width/2],'SideLength',site.site_width/2);
    plot(site_polygon);
    legend_cells{end+1} = 'Site shape';
end
legend(legend_cells);

%% backhaul links
first = 1;
for c=1:n_cs
    for d=1:n_cs
        if z(c,d) == 1
            if first
                plot([cs_positions(c,1) cs_positions(d,1)],[cs_positions(c,2) cs_positions(d,2)], 'DisplayName', 'BH Link');
                first = 0;
            else
                plot([cs_positions(c,1) cs_positions(d,1)],[cs_positions(c,2) cs_positions(d,2)], 'HandleVisibility','off');
            end
        end
    end
end

%%
first = 1;
for c=1:n_cs
    for t=1:n_tp
        for r=1:n_cs
            if x_ris(t,c,r) == 1
                if first
                    plot([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)], 'k-.', 'HandleVisibility','off');
                    plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], 'k-.', 'HandleVisibility','off');
                    first=0;
                else
                    plot([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)], 'k-.',  'HandleVisibility','off');
                    plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], 'k-.', 'HandleVisibility','off');
                end
            end
        end
    end
end

first = 1;
for c=1:n_cs
    for t=1:n_tp
        for r=1:n_cs
            if x_sr(t,c,r)  == 1
                if first
                    plot([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)], 'k-.', 'DisplayName', 'SRC Link');
                    plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], 'k-.', 'HandleVisibility','off');
                    first=0;
                else
                    plot([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)], 'k-.',  'HandleVisibility','off');
                    plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], 'k-.', 'HandleVisibility','off');
                end
            end
        end
    end
end
sdf(figure_style);


end