%% init
clearvars;
addpath('utils/');
%sim_folder = 'step_2_iab_mu0.5/';
%sim_folder = 'step_2_iab_mu0_sr_UL/';
sim_folder = 'rissr_mu0_angle/';
%sim_folder = 'SR_a200x200_20cs_30tp_5mcs_1e4el_D60_maxR_minRout/';
%sim_folder = 'small_5mcs_1e5el_rout0-1e6_maxr_50runs/';
%model_name = 'IABmaxAngDivMinLen_UL';
model_name = 'RISSRmaxAngDivMinLenUL_NEW';
%model_name = 'noris_maxavgrate';
%folder_names_root = 'small_minRout';
%folder_names_root = 'SR_a400x300_52cs_5mcs_1e4el_D60_maxR_100mbps_CS';
folder_names_root = 'tesipaolo';
%% open results folder and list files curresponding to the model
%files = dir(['solved_instances/5mcs_small/' folder_names_root '_50r/solutions/' model_name '*.m']);
directories = dir(['move2antilion/' sim_folder folder_names_root '*']);
n_dir = numel(directories);

%nat sort forlder such that the are sorted in increasing parameter
%variations
dir_name_list = {directories.name};
dir_name_list = natsort(dir_name_list);


%% execute some data processing for each folder, over all the runs in the folder

avg_donors      = zeros(n_dir,1);
avg_ris         = zeros(n_dir,1);
avg_cost        = zeros(n_dir,1);
avg_ang_sep     = zeros(n_dir,1);
avg_linlen    = zeros(n_dir,1);
avg_iab= zeros(n_dir,1);
avg_sr=zeros(n_dir,1);
solved_count    = zeros(n_dir,1);
avg_obj         = zeros(n_dir,1);
avg_ris_distance= zeros(n_dir,1);
avg_covered_don_distance= zeros(n_dir,1);
avg_uncovered_don_dist= zeros(n_dir,1);
avg_aided_percent =zeros(n_dir,1);
avg_tau_ris=zeros(n_dir,1);
% avg_src_dist_ris = zeros(n_dir,1);
% avg_src_dist_sr = zeros(n_dir,1);
avg_dist_tp_bs_ifris=zeros(n_dir,1);
avg_dist_tp_bs_ifsr=zeros(n_dir,1);
avg_dist_tp_ris=zeros(n_dir,1);
avg_dist_tp_sr=zeros(n_dir,1);
avg_dist_ris_bs=zeros(n_dir,1);
avg_dist_sr_bs=zeros(n_dir,1);
avg_rate_ris=zeros(n_dir,1);
avg_rate_sr=zeros(n_dir,1);


avg_ang_sep_ris     = zeros(n_dir,1);
avg_linlen_ris    = zeros(n_dir,1);
avg_ang_sep_sr     = zeros(n_dir,1);
avg_linlen_sr    = zeros(n_dir,1);


wb = waitbar(0);

for d = 1:numel(dir_name_list)
    %enter solution folders and get all the solved .mfiles
    disp(['Processing ' dir_name_list{d}]);
    waitbar(d/numel(dir_name_list),wb,dir_name_list{d});
    solutions = dir(['move2antilion/' sim_folder dir_name_list{d} '/solutions/' model_name '*.m']);
    
    
    if numel(solutions) < 20
        disp([dir_name_list{d} ' has ' num2str(30-numel(solutions)) ' unsolved instances']);
    end
    solved_count(d) = numel(solutions);
    
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
        load(['move2antilion/' sim_folder dir_name_list{d} '/instances/' data_name],...
            'n_tp', 'n_cs' ,'cs_tp_distance_matrix',...
            'cs_cs_distance_matrix', 'smallest_angles','cs_tp_distance_matrix','OF_weight','reflected_rate','af_rel_rate');
        
        avg_donors(d)      = avg_donors(d) + sum(y_don);
        avg_iab(d) = avg_iab(d) + sum(y_iab);
        avg_ris(d)         = avg_ris(d) + sum(y_ris);
        avg_sr(d) = avg_sr(d) + sum(y_sr);
        
        
        if OF_weight==0.5
            avg_ang_sep(d)     = avg_ang_sep(d) + mean(min_angle);
            avg_linlen(d)    = avg_linlen(d) + mean(avg_lin_len);
        end
        if OF_weight==0
            avg_linlen(d)    = avg_linlen(d) + mean(avg_lin_len);
            temp_angle = 0;
            for t=1:n_tp
                for c=1:n_cs
                    for r=1:n_cs
                        if c==r
                            continue;
                        end
                        if x_ris(t,c,r) | x_sr(t,c,r) ==1
                            temp_angle = temp_angle + smallest_angles(t,c,r);
                        end
                    end
                end
            end
            temp_angle = temp_angle/n_tp;
            avg_ang_sep(d)     = avg_ang_sep(d) + temp_angle;
        end
        if OF_weight==1
            avg_ang_sep(d)     = avg_ang_sep(d) + mean(min_angle);
            temp_len = 0;
            for t=1:n_tp
                for c=1:n_cs
                    for r=1:n_cs
                        if c==r
                            continue;
                        end
                        if x_ris(t,c,r) | x_sr(t,c,r)==1
                            temp_len = temp_len + 0.5*(...
                                cs_tp_distance_matrix(c,t)+cs_tp_distance_matrix(r,t));
                        end
                    end
                end
            end
            temp_len = temp_len/n_tp;
            avg_linlen(d)     = avg_linlen(d) + temp_len;
        end
        
        
%         %separation and link length for RIS and SR separately
%         temp_angle_ris=0;
%         temp_angle_sr=0;
%         temp_no_sr=0;
%         for t=1:n_tp
%             for c=1:n_cs
%                 for r=1:n_cs
%                     if c==r
%                         continue;
%                     end
%                     if x_ris(t,c,r) ==1
%                         temp_angle_ris = temp_angle_ris + smallest_angles(t,c,r);
%                     end
%                     if x_sr(t,c,r) ==1
%                         temp_angle_sr = temp_angle_sr + smallest_angles(t,c,r);
%                        
%                     end
%                     
%                 end
%             end
%         end
%         
%         if sum(x_ris,'all')~=0
%             temp_angle_ris = temp_angle_ris/sum(x_ris,'all');
%             avg_ang_sep_ris(d)     = avg_ang_sep_ris(d) + temp_angle_ris;
%         end
%         
%         if sum(x_sr,'all')~=0
%             temp_angle_sr = temp_angle_sr/sum(x_sr,'all');
%             avg_ang_sep_sr(d)     = avg_ang_sep_sr(d) + temp_angle_sr;
%         
%         end
%         if sum(x_sr,'all')==0
%             temp_angle_sr=0;
%             avg_ang_sep_sr(d)     = avg_ang_sep_sr(d) + temp_angle_sr;
%             temp_no_sr=temp_no_sr+1;
%             no_sr=no_sr+temp_no_sr;
%             %disp(no_sr);
%            
%         end
% %         avg_ang_sep_ris(d)     = avg_ang_sep_ris(d) + temp_angle_ris;
% %         avg_ang_sep_sr(d)     = avg_ang_sep_sr(d) + temp_angle_sr;
%         
%         temp_len_ris = 0;
%         
%         temp_len_sr = 0;
%         for t=1:n_tp
%             for c=1:n_cs
%                 for r=1:n_cs
%                     if c==r
%                         continue;
%                     end
%                     if x_ris(t,c,r)==1
%                         temp_len_ris = temp_len_ris + 0.5*(...
%                             cs_tp_distance_matrix(c,t)+cs_tp_distance_matrix(r,t));
%                     end
%                     if x_sr(t,c,r)==1
%                         temp_len_sr = temp_len_sr + 0.5*(...
%                             cs_tp_distance_matrix(c,t)+cs_tp_distance_matrix(r,t));
%                     end
%                 end
%             end
%         end
%         
%         
%        temp_len_ris = temp_len_ris/sum(x_ris,'all'); 
%        if sum(x_sr,'all')~=0 
%        temp_len_sr = temp_len_sr/sum(x_sr,'all');
%        end
%        
%        if sum(x_sr,'all')==0
%            continue
%        end
% 
%        avg_linlen_ris(d)     = avg_linlen_ris(d) + temp_len_ris;
%        avg_linlen_sr(d)     = avg_linlen_sr(d) + temp_len_sr;
        
       %rates and distances of SRC
       
        temp_dist_tp_bs_ifris=0;
        temp_dist_tp_bs_ifsr=0;
        temp_dist_tp_ris=0;
        temp_dist_tp_sr=0;
        temp_dist_ris_bs=0;
        temp_dist_sr_bs=0;
        temp_rate_ris=0;
        temp_rate_sr=0;
        temp_no_sr = 0;
        for t= 1:n_tp
            for c=1:n_cs
                for r=1:n_cs
                    
                    if c == r
                        continue;
                    end
                    if x_ris(t,c,r)==1
                        temp_rate_ris=temp_rate_ris+reflected_rate(t,c,r);
                        
                        temp_dist_tp_bs_ifris= temp_dist_tp_bs_ifris + cs_tp_distance_matrix(c,t);
                        temp_dist_tp_ris= temp_dist_tp_ris + cs_tp_distance_matrix(r,t);
                        temp_dist_ris_bs= temp_dist_ris_bs + cs_cs_distance_matrix(c,r);
                    end
                    if x_sr(t,c,r)==1
                        temp_rate_sr=temp_rate_sr + af_rel_rate(t,c,r);
                        
                        temp_dist_tp_bs_ifsr= temp_dist_tp_bs_ifsr + cs_tp_distance_matrix(c,t);
                        temp_dist_tp_sr= temp_dist_tp_sr + cs_tp_distance_matrix(r,t);
                        temp_dist_sr_bs= temp_dist_sr_bs + cs_cs_distance_matrix(c,r);
                    end
                    
                end
            end
        
        end
        
        if sum(y_ris)==0
            continue
        end
        if sum(y_ris)~=0
 
            temp_rate_ris=sum(temp_rate_ris)/sum(y_ris);
            avg_rate_ris(d)=avg_rate_ris(d)+temp_rate_ris; 
            

            
            temp_dist_tp_ris=temp_dist_tp_ris/sum(y_ris);
            temp_dist_ris_bs=temp_dist_ris_bs/sum(y_ris);
            temp_dist_tp_bs_ifris=temp_dist_tp_bs_ifris/sum(y_ris);
            avg_dist_tp_bs_ifris(d)=avg_dist_tp_bs_ifris(d)+temp_dist_tp_bs_ifris;
            avg_dist_tp_ris(d)=avg_dist_tp_ris(d)+temp_dist_tp_ris;
            avg_dist_ris_bs(d)=avg_dist_ris_bs(d)+temp_dist_ris_bs;
        end
        if sum(y_sr)==0
            
            temp_no_sr=temp_no_sr+1;
            no_sr=no_sr+temp_no_sr;
            continue
        end
        if sum(y_sr)~=0
            temp_rate_sr=temp_rate_sr/sum(y_sr);
            avg_rate_sr(d)=avg_rate_sr(d)+temp_rate_sr;
            

            
            temp_dist_tp_sr=temp_dist_tp_sr/sum(y_sr);
            temp_dist_sr_bs=temp_dist_sr_bs/sum(y_sr);
            temp_dist_tp_bs_ifsr=temp_dist_tp_bs_ifsr/sum(y_sr);
            avg_dist_tp_bs_ifsr(d)=avg_dist_tp_bs_ifsr(d)+temp_dist_tp_bs_ifsr;
            avg_dist_tp_sr(d)=avg_dist_tp_sr(d)+temp_dist_tp_sr;
            avg_dist_sr_bs(d)=avg_dist_sr_bs(d)+temp_dist_sr_bs;
            
        end
        
        
            
        
        
    end
    %finish computing averages
    avg_donors(d) = avg_donors(d)/numel(solutions);
    avg_ris(d) = avg_ris(d)/numel(solutions);
    avg_cost(d) = avg_cost(d)/numel(solutions);
    avg_ang_sep(d) = avg_ang_sep(d)/numel(solutions);
    avg_linlen(d) = avg_linlen(d)/numel(solutions);
    
    avg_ang_sep_ris(d) = avg_ang_sep_ris(d)/numel(solutions);
    avg_linlen_ris(d) = avg_linlen_ris(d)/numel(solutions);
    avg_ang_sep_sr(d) = avg_ang_sep_sr(d)/(numel(solutions)-no_sr);
    avg_linlen_sr(d) = avg_linlen_sr(d)/(numel(solutions)-no_sr);
    disp(numel(solutions)-no_sr)
    
    avg_iab(d) = avg_iab(d)/numel(solutions);
    avg_sr(d) = avg_sr(d)/numel(solutions);
    avg_ris_distance(d)=avg_ris_distance(d)/distance_samples_count_covered;
    avg_uncovered_don_dist(d)= avg_uncovered_don_dist(d)/distance_samples_count_uncovered;
    avg_covered_don_distance(d) = avg_covered_don_distance(d)/distance_samples_count_covered;
    
    avg_obj(d) = avg_obj(d)/numel(solutions);
    
    avg_dist_tp_bs_ifris(d)=avg_dist_tp_bs_ifris(d)/numel(solutions);
    avg_dist_tp_bs_ifsr(d)=avg_dist_tp_bs_ifsr(d)/(numel(solutions));
    avg_dist_tp_ris(d)=avg_dist_tp_ris(d)/numel(solutions);
    avg_dist_tp_sr(d)=avg_dist_tp_sr(d)/(numel(solutions));
    avg_dist_ris_bs(d)=avg_dist_ris_bs(d)/numel(solutions);
    avg_dist_sr_bs(d)=avg_dist_sr_bs(d)/(numel(solutions));
    
    avg_rate_ris(d)=avg_rate_ris(d)/numel(solutions);
    avg_rate_sr(d)=avg_rate_sr(d)/(numel(solutions)-no_sr);
    
    clear('x')
end

%get the x ticks by splitting the folder names and getting the varying
%parameter
% ticks_labels = split([directories.name], '_');
% ticks_labels = ticks_labels(9:9:end);
% ticks_labels = natsort(cellfun(@(ticks)ticks(:,3:end), ticks_labels, 'uni', false));
% switch sim_folder
%     case 'Sim_1/'
%         ticks_labels = split([directories.name], '_');
%         ticks_labels = ticks_labels(9:9:end);
%         ticks_labels = natsort(cellfun(@(ticks)ticks(:,8:end), ticks_labels, 'uni', false));
%     case 'Sim_2/'
%         ticks_labels = split([directories.name], '_');
%         ticks_labels = ticks_labels(10:10:end);
%         ticks_labels = natsort(cellfun(@(ticks)ticks(:,7:end), ticks_labels, 'uni', false));
%     case 'Sim_3/'
%         ticks_labels = split([directories.name], '_');
%         ticks_labels = ticks_labels(9:9:end);
%         ticks_labels = natsort(cellfun(@(ticks)ticks(:,3:end), ticks_labels, 'uni', false));
%     case 'Sim_4/'
%         ticks_labels = split([directories.name], '_');
%         ticks_labels = ticks_labels(9:9:end);
%         ticks_labels = natsort(cellfun(@(ticks)ticks(:,5:end), ticks_labels, 'uni', false));
%     case 'Sim_5/'
%         ticks_labels = split([directories.name], '_');
%         ticks_labels = ticks_labels(9:9:end);
%         ticks_labels = natsort(cellfun(@(ticks)ticks(:,5:end), ticks_labels, 'uni', false));
% end

%ticks_labels = split([directories.name], '_');
ticks_labels = {directories.name};
%ticks_labels = ticks_labels(9:9:end);
ticks_labels = natsort(cellfun(@(ticks)ticks(:,10:end), ticks_labels, 'uni', false));
ticks_labels = natsort(cellfun(@(ticks)extractBefore(ticks,'_'), ticks_labels, 'uni', false));

%% save results
mkdir(['mat_results/' sim_folder ]);
save(['mat_results/' sim_folder 'results'], 'ticks_labels',...
    'avg_donors',...
    'avg_iab',...
    'avg_ris',...
    'avg_sr',...
    'avg_ang_sep',...
    'avg_dist_ris_bs',...
    'avg_dist_sr_bs',...
    'avg_dist_tp_bs_ifris',...
    'avg_dist_tp_bs_ifsr',...
    'avg_dist_tp_ris',...
    'avg_dist_tp_sr',...
    'avg_rate_ris',...
    'avg_rate_sr',...
    'avg_ang_sep_ris',...
    'avg_ang_sep_sr',...
    'avg_linlen_ris',...
    'avg_linlen_sr',...
    'avg_linlen');...
    
% %%
% %ticks = {'0', '1','10','50','100','200','500','700'};
% %ticks = {'0', '1','2','3','4','5','6','7','8','9','10'};
%
%
% ticks_labels = split([directories.name], '_');
% ticks_labels = ticks_labels(8:8:end);
% ticks_labels = natsort(cellfun(@(ticks)ticks(:,7:end), ticks_labels, 'uni', false));

 f1=figure();
 plot(str2num(char(ticks_labels)), avg_ang_sep);
 grid on;
 hold on;
 xlabel('Budget');
 ylabel('Average angular separation [degrees]');
 title('Average angular separation');
 %xlim([0 0.8])
 ylim([80 170])
 %sdf('Polimi-ppt');
 
 f2=figure();
 plot(str2num(char(ticks_labels)), avg_linlen);
 grid on;
 hold on;
 xlabel('Budget');
 ylabel('Average link length [m]');
 title('Average link length');
 ylim([40 150])
 %sdf('Polimi-ppt');
 
 f3=figure();
 plot(str2num(char(ticks_labels)), avg_ris);
 grid on;
 hold on;
 plot(str2num(char(ticks_labels)), avg_sr);
 title('avg ris and sr')
 legend('ris','sr')
%  
% f4=figure();
% plot(str2num(char(ticks_labels)),avg_rate_ris);
% hold on
% plot(str2num(char(ticks_labels)),avg_rate_sr);
% legend('rate ris','rate sr');
% %  
%  f5=figure();
%  plot(str2num(char(ticks_labels)), avg_iab);
%  grid on;
%  hold on;
%  xlabel('Budget');
%  ylabel('Average iab nodes');
%  title('Average iab nodes');
%  ylim([1 11])
%  %sdf('Polimi-ppt');
%  
 
%  %sdf('Polimi-ppt');
