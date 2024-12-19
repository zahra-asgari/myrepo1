mod_template = 'fakeris_maxavgrate';
%mod_template = 'noris_maxavgrate';
clear('size'); %clearing variable size loaded from solution such that we avoid bugs when callinng function size

site_scatter = figure();
hold on;
grid on;

%sites
scatter(cs_positions(:,1),cs_positions(:,2), 'x');
scatter(tp_positions(:,1),tp_positions(:,2),'d');

%populated sites
scatter(cs_positions(y_don == 1,1),cs_positions(y_don == 1,2),'r');

legend('Construction Sites', 'Test Points', 'Donors', 'RIS');

if strcmp(mod_template, 'fakeris_maxavgrate')
    scatter(cs_positions(y_ris == 1,1),cs_positions(y_ris == 1,2),'g');
    %connections
    for d=1:n_cs
        for t=1:n_tp
            if( sum(tau_ris(t,d,:)) > 0) %this tp is served by this donor, we will use the same color for each plot
                plot([cs_positions(d,1) tp_positions(t,1)],[cs_positions(d,2) tp_positions(t,2)], 'DisplayName', ['SRC ' num2str(t) '-' num2str(d)]);
                %and we plot the ris connection in this particular src
                for r=1:n_cs
                    if (tau_ris(t,d,r) > 0)
                        %-1 on the color index and then plot
                        set(gca, 'ColorOrderIndex', mod(get(gca, 'ColorOrderIndex')-2, size(get(gca, 'ColorOrder'),1))+1)
                        %set(gca, 'ColorOrderIndex', get(gca, 'ColorOrderIndex')-1)
                        plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], '--', 'HandleVisibility','off');
                    end
                end
            end
        end
    end
    xlabel('Width [m]');
    ylabel('Height [m]');
    sdf('Polimi-ppt');
elseif strcmp(mod_template, 'noris_maxavgrate')
    %connections
    for d=1:n_cs
        for t=1:n_tp
            if( tau_don(t,d) > 0) %this tp is served by this donor, we will use the same color for each plot
                plot([cs_positions(d,1) tp_positions(t,1)],[cs_positions(d,2) tp_positions(t,2)], 'DisplayName', ['SRC ' num2str(t) '-' num2str(d)]);
            end
        end
    end
    xlabel('Width [m]');
    ylabel('Height [m]');
    sdf('Polimi-ppt');
end