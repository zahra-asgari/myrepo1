%tp_focus = { any tp-> plot curresponding src; -1 -> plot all}
tp_focus = -1;
PLOT_FAKERIS = 0;
PLOT_OPTIDELTA = 1;

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

legend('Construction Sites', 'Test Points', 'Donors', 'IAB nodes', 'RIS');

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
            if x(t,c,r) == 1
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

sdf('Polimi-ppt');
% %%
%
% if RIS_MODEL
%     scatter(cs_positions(y_ris == 1,1),cs_positions(y_ris == 1,2),100,'b','filled');
%     legend('Construction Sites', 'Test Points', 'Donors', 'RIS');
%     %connections
%     for don=1:n_cs
%         for t=1:n_tp
%
%             %tp focus
%             if sum(tp_focus == t) == 0 && sum(tp_focus > 0)
%                 continue
%             end
%
%             if( sum(tau_ris(t,don,:)) > 0) %this tp is served by this donor, we will use the same color for each plot
%                 plot([cs_positions(don,1) tp_positions(t,1)],[cs_positions(don,2) tp_positions(t,2)], 'DisplayName', ['SRC ' num2str(t) '-' num2str(don)]);
%                 %and we plot the ris connection in this particular src
%                 for r=1:(n_cs-1 + PLOT_FAKERIS)
%                     if (tau_ris(t,don,r) > 0)
%                         %-1 on the color index and then plot
%                         set(gca, 'ColorOrderIndex', mod(get(gca, 'ColorOrderIndex')-2, size(get(gca, 'ColorOrder'),1))+1)
%
%                         %plot ris-tp connection
%                         %set(gca, 'ColorOrderIndex', get(gca, 'ColorOrderIndex')-1)
%                         plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], '--', 'HandleVisibility','off');
%
%                         set(gca, 'ColorOrderIndex', mod(get(gca, 'ColorOrderIndex')-2, size(get(gca, 'ColorOrder'),1))+1)
%                         %plot don-ris connection
%                         plot([cs_positions(r,1) cs_positions(don,1)],[cs_positions(r,2) cs_positions(don,2)], '-.', 'HandleVisibility','off');
%
%                         % plot ris orientation
%                         secdraw(delta(r)-60,120,10, cs_positions(r,:),'b');
%                         if PLOT_OPTIDELTA
%                             secdraw(optimized_delta(r)-60,120,15, cs_positions(r,:),'r');
%                         end
%
%                     end
%                 end
%             end
%         end
%     end
%     xlabel('Width [m]');
%     ylabel('Height [m]');
%     %sdf('Polimi-ppt');
% elseif ~RIS_MODEL
%     %connections
%     for don=1:n_cs
%         for t=1:n_tp
%             if( tau_don(t,don) > 0) %this tp is served by this donor, we will use the same color for each plot
%                 plot([cs_positions(don,1) tp_positions(t,1)],[cs_positions(don,2) tp_positions(t,2)], 'DisplayName', ['SRC ' num2str(t) '-' num2str(don)]);
%             end
%         end
%     end
%     xlabel('Width [m]');
%     ylabel('Height [m]');
%     sdf('Polimi-ppt');
% else
%     %connections
%     for don=1:n_cs
%         for t=1:n_tp
%             if( x_don(t,don) == 1) %this tp is served by this donor, we will use the same color for each plot
%                 plot([cs_positions(don,1) tp_positions(t,1)],[cs_positions(don,2) tp_positions(t,2)], 'DisplayName', ['SRC ' num2str(t) '-' num2str(don)]);
%                 %and we plot the ris connection in this particular src
%                 for r=1:n_cs
%                     if (s(t,don,r) == 1)
%                         %-1 on the color index and then plot
%                         set(gca, 'ColorOrderIndex', mod(get(gca, 'ColorOrderIndex')-2, size(get(gca, 'ColorOrder'),1))+1)
%                         %set(gca, 'ColorOrderIndex', get(gca, 'ColorOrderIndex')-1)
%                         plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], '--', 'HandleVisibility','off');
%                     end
%                 end
%             end
%         end
%     end
%     xlabel('Width [m]');
%     ylabel('Height [m]');
%     sdf('Polimi-ppt');
% end
%
