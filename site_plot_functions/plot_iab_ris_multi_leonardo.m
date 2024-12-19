function [] = plot_iab_ris_multi_leonardo(workspace_struct,solution_struct,figure_style)
%PLOT_IAB_RIS_MULTI_FINAL This function plots the solution according to the
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

% site_scatter = figure();
hold on;
grid on;

xlabel('Site Width [m]');
ylabel('Site Height [m]');
%title('Planning Step 2');

% load and plot buiildings
% load('V_4/Blockage_Data/scaled_translated_leonardo.mat');
% for b=1:numel(translated_scaled_polygons)
%         plot(translated_scaled_polygons{1,b},'HandleVisibility','off');
% end

%sites
scatter(bs_positions(:,1),bs_positions(:,2),'x','red');
scatter(ris_positions(:,1),ris_positions(:,2),'x','blue');
scatter(tp_positions(:,1),tp_positions(:,2),'o','filled','green');

%populated sites
scatter(bs_positions(y_don == 1,1),bs_positions(y_don == 1,2),'o','filled','k');
scatter(bs_positions(xor(y_iab,y_don) == 1,1),bs_positions(xor(y_iab,y_don) == 1,2),'o','filled','red');
scatter(ris_positions(y_ris == 1,1),ris_positions(y_ris == 1,2),'o','filled','blue');

legend('BS Sites','RIS Sites', 'Test Points', 'Donors', 'IAB nodes', 'RIS');

%% backhaul links
first = 1;
for c=1:n_bs
    for d=1:n_bs
        if z(c,d) == 1
            if first
                plot([bs_positions(c,1) bs_positions(d,1)],[bs_positions(c,2) bs_positions(d,2)], 'red','DisplayName', 'BH Link','LineWidth',0.5);
                first = 0;
            else
                plot([bs_positions(c,1) bs_positions(d,1)],[bs_positions(c,2) bs_positions(d,2)],'red', 'HandleVisibility','off','LineWidth',0.5);
            end
        end
    end
end

%%
first = 1;
for c=1:n_bs
    for t=1:n_tp
        for r=1:n_ris
            if x(t,c,r) == 1
                if first
                    plot([bs_positions(c,1) tp_positions(t,1)],[bs_positions(c,2) tp_positions(t,2)], 'k-.', 'DisplayName', 'SRC Link','LineWidth',0.5);
                    plot([ris_positions(r,1) tp_positions(t,1)],[ris_positions(r,2) tp_positions(t,2)], 'k-.', 'HandleVisibility','off','LineWidth',0.5);
                    first=0;
                else
                    plot([bs_positions(c,1) tp_positions(t,1)],[bs_positions(c,2) tp_positions(t,2)], 'k-.',  'HandleVisibility','off','LineWidth',0.5);
                    plot([ris_positions(r,1) tp_positions(t,1)],[ris_positions(r,2) tp_positions(t,2)], 'k-.', 'HandleVisibility','off','LineWidth',0.5);
                end
            end
        end
    end
end
sdf(figure_style);


end

