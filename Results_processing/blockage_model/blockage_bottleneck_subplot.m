clear all;
addpath('utils');
sim_folder = 'Mat_files_solutions/';
sim_id = 'journal100_rightsbz_mean_vs_peak';
test_folder = '';
%test_folder = 'free_space_all/';
%test_folder = 'free_space_vs_urban/';
export_style = 'Polimi-ppt';
%export_style = 'ieee_large_lines';

mat_files = dir([sim_folder sim_id '/mat_results/'  test_folder '*.mat']);
num_files = numel(mat_files);
grid = num_files;
if isprime(num_files) && mod(num_files,2)>0
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
        case 'data_maxminMCS.mat'
            mat_files(n).title = 'OF: max $c^{MIN} \leq \sum_{c,r \in C}C_{t,c,r}^{SRC}x_{t,c,r} \forall t \in T$';
        case 'data_minmaxt.mat'
            mat_files(n).title = 'OF: min $t^{MAX} \geq t_{c}^{tx} + t_{c}^{rx} \forall c \in C$';
        case 'data_sumMCS.mat'
            mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}C_{t,c,r}^{SRC}x_{t,c,r}$';
        case 'data_sumairtime.mat'
            mat_files(n).title = 'OF: min $\sum_{c \in C}t_{c}^{tx} + t_{c}^{rx}$';
        case 'data_sumall.mat'
            mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}C_{t,c,r}^{SRC}x_{t,c,r} + \sum_{c,d \in C}C_{c,d}^{BH}z_{c,d}$';
        case 'data_sumextra.mat'
            %mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}g_{t,c,r}^{EXTRA}$';
            mat_files(n).title = 'Peak Rate model Bottleneck link distribution';

        case 'data_sumfree.mat'
            mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}\frac{C_{t,c,r}^{SRC}x_{t,c,r} - g_{t,c,r}}{C_{t,c,r}^{SRC}} + \sum_{c,d \in C}\frac{C_{c,d}^{BH}z_{c,d} - f_{c,d}}{C_{c,d}^{BH}}$';
        case 'data_sumfreeMCS.mat'
            mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}\frac{C_{t,c,r}^{SRC}x_{t,c,r} - g_{t,c,r}}{C_{t,c,r}^{SRC}}$';
        case 'data_sumlen.mat'
            mat_files(n).title = 'OF: min $\sum_{t \in T,c \in C}\lambda_{t,c}x_{t,c,\hat{c}} + \sum_{t \in T,c,r \in C:r\neq\hat{c}}(\frac{\lambda_{t,c} + \lambda_{t,r}}{2}x_{t,c,r})$';
        case 'data_sumfreeabs.mat'
            mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}(C_{t,c,r}^{SRC}x_{t,c,r} - g_{t,c,r}) + \sum_{c,d \in C}C_{c,d}^{BH}z_{c,d} - f_{c,d}$';
        case 'data_maxminrate.mat'
            mat_files(n).title = 'OF: max $r^{MIN} \leq \sum_{c,r \in C}g_{t,c,r} \forall t \in T$';
        case 'data_sumrate.mat'
            %mat_files(n).title = 'OF: max $\sum_{t \in T, c,r \in C}g_{t,c,r}$';
            mat_files(n).title = 'Avg Rate model Bottleneck link distribution';

        case 'data_minmaxlen.mat'
            mat_files(n).title = 'OF: min $l_acc + l_bh$';
        
        case 'MTF.mat'
            mat_files(n).title = 'Bottleneck distribution, MTF';

        case 'PTF.mat'
            mat_files(n).title = 'Bottleneck distribution, PTF';
                    
           
    end
end


for m=1:num_files
    handle(m) = subplot(sides(1),sides(2),m);
    hold on;
    legend('Location', 'best'); 
    if ~strcmp(export_style(1:num_files), 'ieee')
    %title('$a^2$', 'Interpreter', 'latex');

    end
end

% line_options = {''; '--'; ':'};
%color_options= {'k'; 'k'; 'k'};
%color_options = distinguishable_colors(numel(mat_files));

bar_names = {'Access Donor';'Access IAB';'IAB';'Donor';'RIS'};
if contains(sim_id,'journal')
    bar_names(end+1) = {'NCR'};
end

for mf = 1:numel(mat_files)
    %load the file
    load([mat_files(mf).folder '/' mat_files(mf).name]);
    devices = [bn.avg_accdon.DL bn.avg_acciab.DL bn.avg_pathiab.DL bn.avg_don.DL bn.avg_ris.DL];
    if contains(sim_id,'journal')
        devices(:,end+1) = bn.avg_ncr.DL;
    end

    bar(handle(mf),str2num(char(ticks_labels)), devices ,'stacked','EdgeColor','none');
    legend(handle(mf),bar_names);
    %title(handle(mf),mat_files(mf).title, 'Interpreter', 'latex');
    title(handle(mf),mat_files(mf).title);
    xlabel(handle(mf),'Budget');
    ylabel(handle(mf),'Test Points');

    %sdf(export_style); 
    if (min(solved_count)<=10)
        xlim(handle(mf),[str2double(ticks_labels{find(solved_count>min(solved_count),1,'first')}),str2double(ticks_labels{end})])
    else
        xlim(handle(mf),'auto')
    end
    ylim(handle(mf),[0 15]);
    % ylim(handle(mf), [0 sum([bn.avg_accdon.DL bn.avg_acciab.DL bn.avg_pathiab.DL bn.avg_don.DL bn.avg_ris.DL bn.avg_ncr.DL],'all')/size(bn.avg_accdon.DL,1)]);
    
    
end
