

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

model_name = 'RISSRmaxAngDivMinLenUL_NEW';

sim_folder='rissr_mu1_angle/';
folder_names_root = 'tesipaolo0.0';

directories=dir(['move2antilion/' sim_folder folder_names_root '*'])
n_dir = numel(directories);
dir_name_list = {directories.name};
dir_name_list = natsort(dir_name_list);


    %enter solution folders and get all the solved .mfiles
    disp(['Processing ' dir_name_list]);
    %waitbar(d/numel(dir_name_list),wb,dir_name_list{d});
    solutions = dir(['move2antilion/' sim_folder directories.name '/solutions/' model_name '*.m']);
    
    
    solved_count = numel(solutions);
    
    distance_samples_count_covered = 0;
    distance_samples_count_uncovered = 0;
    
    no_sr=0;
    %for each solution...
    for sol=1:numel(solutions)
        %run the solution
        run([solutions(sol).folder '/' solutions(sol).name]);
        %run .mat for angles and length
        data_name = split(solutions(sol).name, '_'); %split the string
        data_name = data_name{end}; %get the run
        data_name = data_name(1:end-2); %truncate .m to get the .mat data name
        load(['move2antilion/' sim_folder directories.name '/instances/' data_name]);

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


        legend('Construction Sites', 'Test Points', 'Donors', 'IAB nodes', 'RIS','SR');

        %% backhaul links
        first = 1;
        for c=1:n_cs
            for d=1:n_cs
                if z(c,d) == 1
                    if first
                        plot([cs_positions(c,1) cs_positions(d,1)],[cs_positions(c,2) cs_positions(d,2)],'k', 'DisplayName', 'BH Link','LineWidth',1.5);
                        first = 0;
                    else
                        plot([cs_positions(c,1) cs_positions(d,1)],[cs_positions(c,2) cs_positions(d,2)],'k', 'HandleVisibility','off','LineWidth',1.5);
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
                            plot([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)], 'b', 'DisplayName', 'SRC Link');
                            plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], 'r-.', 'HandleVisibility','off');
                            %plot([cs_positions(r,1) cs_positions(c,1)],[cs_positions(r,2) cs_positions(c,2)], 'r-.', 'HandleVisibility','off');
                            %secdraw(delta(r)-60,180,10, cs_positions(r,:),'b');
                            first=0;
                        else
                            plot([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)], 'b',  'HandleVisibility','off');
                            plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], 'r-.', 'HandleVisibility','off');
                            %plot([cs_positions(r,1) cs_positions(c,1)],[cs_positions(r,2) cs_positions(c,2)], 'r-.', 'HandleVisibility','off');
                            %secdraw(delta(r)-60,180,10, cs_positions(r,:),'b');
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
                            plot([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)], 'b', 'DisplayName', 'SRC Link');
                            plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], 'g-.', 'HandleVisibility','off');
                            plot([cs_positions(r,1) cs_positions(c,1)],[cs_positions(r,2) cs_positions(c,2)], 'm-.', 'HandleVisibility','off');
                            secdraw(delta(r)-60,120,10, cs_positions(r,:),'b');
                            first=0;
                        else
                            plot([cs_positions(c,1) tp_positions(t,1)],[cs_positions(c,2) tp_positions(t,2)], 'b',  'HandleVisibility','off');
                            plot([cs_positions(r,1) tp_positions(t,1)],[cs_positions(r,2) tp_positions(t,2)], 'g-.', 'HandleVisibility','off');
                            plot([cs_positions(r,1) cs_positions(c,1)],[cs_positions(r,2) cs_positions(c,2)], 'm-.', 'HandleVisibility','off');
                            secdraw(delta(r)-60,120,10, cs_positions(r,:),'b');
                        end
                    end
                end
            end
        end

        

        %sdf('Polimi-ppt');
    end
    clear('x')
