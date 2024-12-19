clear all;
addpath('utils');
sim_folder = 'Mat_files_solutions/';
sim_id = 'buildings_test';
test_folder = '';
%test_folder = 'free_space_all/';
%test_folder = 'free_space_vs_urban/';
export_style = 'Polimi-ppt';
%export_style = 'ieee_large_lines';

mat_files = dir([sim_folder sim_id '/blockage_probs/'  test_folder '*.mat']);
num_files = numel(mat_files);
grid = num_files*2;
if isprime(num_files) && num_files~=2
    grid = grid + 1;
end
square = sqrt(grid);
div=divisors(grid);
sides=zeros(2,1);
mindist = Inf;
for cy=1:numel(div)
    if (abs(square - div(cy)) < mindist)
        mindist = abs(square - div(cy));
        if div(cy) > num_files/div(cy)
            sides(1) = div(cy);
            sides(2) = grid/div(cy);
        else
            sides(2) = div(cy);
            sides(1) = grid/div(cy);
        end
    end
    
end
figure_handle = figure('units','normalized','outerposition',[0 0 1 1]);
for n=1:num_files
    switch mat_files(n).name
        case 'states_maxminMCS.mat'
            mat_files(n).title = 'OF: max $c^{MIN} \leq \sum_{c,r \in C}C_{t,c,r}^{SRC}x_{t,c,r} \forall t \in T$';
        case 'states_minmaxt.mat'
            mat_files(n).title = 'OF: min $t^{MAX} \geq t_{c}^{tx} + t_{c}^{rx} \forall c \in C$';
        case 'states_sumMCS.mat'
            mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}C_{t,c,r}^{SRC}x_{t,c,r}$';
        case 'states_sumairtime.mat'
            mat_files(n).title = 'OF: min $\sum_{c \in C}t_{c}^{tx} + t_{c}^{rx}$';
        case 'states_sumall.mat'
            mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}C_{t,c,r}^{SRC}x_{t,c,r} + \sum_{c,d \in C}C_{c,d}^{BH}z_{c,d}$';
        case 'states_sumextra.mat'
            %mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}g_{t,c,r}^{EXTRA}$';
            mat_files(n).title = 'Peak Rate model blockage states distribution';
            
        case 'states_sumfree.mat'
            mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}\frac{C_{t,c,r}^{SRC}x_{t,c,r} - g_{t,c,r}}{C_{t,c,r}^{SRC}} + \sum_{c,d \in C}\frac{C_{c,d}^{BH}z_{c,d} - f_{c,d}}{C_{c,d}^{BH}}$';
        case 'states_sumfreeMCS.mat'
            mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}\frac{C_{t,c,r}^{SRC}x_{t,c,r} - g_{t,c,r}}{C_{t,c,r}^{SRC}}$';
        case 'states_sumlen.mat'
            mat_files(n).title = 'OF: min $\sum_{t \in T,c \in C}\lambda_{t,c}x_{t,c,\hat{c}} + \sum_{t \in T,c,r \in C:r\neq\hat{c}}(\frac{\lambda_{t,c} + \lambda_{t,r}}{2}x_{t,c,r})$';
        case 'states_sumfreeabs.mat'
            mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}(C_{t,c,r}^{SRC}x_{t,c,r} - g_{t,c,r}) + \sum_{c,d \in C}C_{c,d}^{BH}z_{c,d} - f_{c,d}$';
        case 'states_maxminrate.mat'
            mat_files(n).title = 'OF: max $r^{MIN} \leq \sum_{c,r \in C}g_{t,c,r} \forall t \in T$';
        case 'states_sumrate.mat'
            %mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}g_{t,c,r}$';
            mat_files(n).title = 'Avg Rate model blockage states distribution';
            
        case 'states_minmaxlen.mat'
            mat_files(n).title = 'OF: min $l_acc + l_bh$';
            
            
    end
end


for m=1:num_files
    handle(2*m -1) = subplot(sides(1),sides(2),2*m-1);
    hold on;
    grid on;
    legend('Location', 'best');
    handle(2*m) = subplot(sides(1),sides(2),2*m);
    grid on;
    
    legend('Location', 'best');
    if ~strcmp(export_style(1:num_files), 'ieee')
        %title('$a^2$', 'Interpreter', 'latex');
        
    end
end

bar_names = {'Free Space';'Obst Dir';'Obst Ref';'Obst Dir&Ref';'SBZ Dir';'All Dir';'SBZ Dir Obst Ref';'All Dir Obst Ref';'SBZ Ref';'Obst Dir SBZ Ref';'All Ref';'All Ref Obst Dir';'SBZ Dir&Ref';'All Dir SBZ Ref';'All Ref SBZ Dir';'All Blocked'};


for mf = 1:numel(mat_files)
    %load the file
    load([mat_files(mf).folder '/' mat_files(mf).name]);
    
    %installed IAB Nodes plot
    
    bar(handle(2*mf -1),str2num(char(ticks_labels)), avg_probs_dir ,'stacked');
    legend(handle(2*mf -1),bar_names);
    %title(handle(2*mf -1),mat_files(mf).title, 'Interpreter', 'latex');
    title(handle(2*mf -1),mat_files(mf).title);
    xlabel(handle(2*mf -1),'Budget');
    ylabel(handle(2*mf -1),'Blockage States');
    
    %sdf(export_style);
    if (min(solved_count)<=10)
        xlim(handle(2*mf -1),[str2double(ticks_labels{find(solved_count>min(solved_count),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(handle(2*mf -1),'auto')
    end
    ylim(handle(2*mf -1),[0 1]);
    
    bar(handle(2*mf),str2num(char(ticks_labels)), avg_probs_src ,'stacked');
    legend(handle(2*mf),bar_names);
    %title(handle(2*mf),mat_files(mf).title, 'Interpreter', 'latex');
    title(handle(2*mf),mat_files(mf).title);
    xlabel(handle(2*mf),'Budget');
    ylabel(handle(2*mf),'Blockage States');
    
    %sdf(export_style);
    if (min(solved_count)<=10)
        xlim(handle(2*mf),[str2double(ticks_labels{find(solved_count>min(solved_count),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(handle(2*mf),'auto')
    end
    ylim(handle(2*mf -1),[0 1]);

    
% % %     index = find(avg_state_probs);
% % %     %labels = dec2bin(0:15);
% % %     pct = avg_state_probs;
% % %     title('Average Link State Blockage Probability');
% % %     
% % %     lgd = legend(labels(index),'Location','eastoutside');
    
    
end
