clear;
scenario_struct = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel();
EXTRA = 0;
SOLVED = 0; %check blockage state probability distribution for actual solved instances
if EXTRA
    sim_folder = 'extra_100/';
    model_name = 'iab_ris_fixedDonor_fakeRis_blockageModel_sumextra';
    
else
    sim_folder = 'avg_100/';
    model_name = 'iab_ris_fixedDonor_fakeRis_blockageModel_sumrate';
end
folder_names_root = 'hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel';
%% open results folder and list files curresponding to the model
num_inst=100;
if SOLVED
    all_probs_dir = [];
    all_probs_src = [];
    directories = dir(['solved_instances/' sim_folder folder_names_root '*']);
    n_dir = numel(directories);
    avg_probs_dir = zeros(16,n_dir);
    avg_probs_src = zeros(16,n_dir);
    
    dir_name_list = {directories.name};
    dir_name_list = natsort(dir_name_list, '\d+\.?\d*');
    solved_count    = zeros(n_dir,1); % how many solved instances for scenario, useful for mean calculation, under half shadow the plot
    for di = 1:numel(dir_name_list)
        disp(['Processing ' dir_name_list{di}]);
        solutions = dir(['solved_instances/' sim_folder dir_name_list{di} '/solutions/' model_name '*.m']);
        [~,sortidx]=natsort({solutions.name});
        solutions = solutions(sortidx);
        if numel(solutions) < 20
            disp([dir_name_list{di} ' has ' num2str(20-numel(solutions)) ' unsolved instances']);
            if numel(solutions) == 0

                continue;

            end
        end
        solved_count(di) = numel(solutions);
        for sol=1:numel(solutions)
            probs_dir = zeros(16, scenario_struct.site.uniform_n_tp);
            probs_src = zeros(16, scenario_struct.site.uniform_n_tp);
            run([solutions(sol).folder '/' solutions(sol).name]);
            %load needed variables from the curresponding .mat file
            data_name = split(solutions(sol).name, '_'); %split the string
            model_title = data_name{end -1};
            data_name = data_name{end}; %get the run
            data_name = data_name(4:end-2); %truncate .m and 'run' to get the .mat data name
            site_cache_id = DataHash([DataHash(scenario_struct.site) num2str(data_name)]); % hash is salted with rng_seed, since the site data is generated randomly
            radio_cache_id = DataHash([DataHash(scenario_struct.radio) site_cache_id]);
            radio_cache_path = ['cache/' radio_cache_id '.mat'];
            if isfile(radio_cache_path)
                load(radio_cache_path,...
                    'state_probs');
            else
                disp("Site cache not found!!")
                continue;
                
            end
            [row, col, depth] = ind2sub(size(x),find(x));
            for i=1:scenario_struct.site.uniform_n_tp
                if (depth(i)) == 1
                    probs_dir(:,i) = squeeze(state_probs(row(i),col(i),depth(i),:));
                else
                    probs_src(:,i) = squeeze(state_probs(row(i),col(i),depth(i),:));
                    
                end
            end
            probs_dir(:,all(probs_dir == 0))=[]; % removes column if the entire column is zero
            probs_src(:,all(probs_src == 0))=[]; % removes column if the entire column is zero            
            all_probs_dir = [all_probs_dir probs_dir];
            all_probs_src = [all_probs_src probs_src];
            
        end
        avg_probs_dir(:,di) = mean(all_probs_dir,2);
        avg_probs_src(:,di) = mean(all_probs_src,2);
    end
else
    avg_state_probs=zeros(16,1);
    avg_loss=zeros(16,1);
    bad_inst=0;
    for inst=1:num_inst
        site_cache_id = DataHash([DataHash(scenario_struct.site) num2str(inst)]); % hash is salted with rng_seed, since the site data is generated randomly
        radio_cache_id = DataHash([DataHash(scenario_struct.radio) site_cache_id]);
        radio_cache_path = ['cache/' radio_cache_id '.mat'];
        if isfile(radio_cache_path)
            load(radio_cache_path,...
                'state_probs','access_snr','sd_better_mask');
        else
            disp("Site cache not found!!")
            continue;

        end

        probs = state_probs.DL(:,2:end,2:end-1,:);
        probs = permute(probs,[4,1,2,3]);
        probs = reshape(probs,16,26*25*15);
        probs(:,all(probs == 0))=[]; % removes column if the entire column is zero
        snr = access_snr.DL.ncr(:,2:end,2:end-1,:);
        sd_check = sd_better_mask.DL.ncr(:,2:end,2:end-1,:);
        snr = permute(snr,[4,1,2,3]);
        sd_check = permute(sd_check,[4,1,2,3]);
        snr = reshape(snr,16,26*25*15);
        sd_check = reshape(sd_check,16,26*25*15);        
        sd_check(:,all(snr == 0))=[];
        snr(:,all(snr == 0))=[]; % removes column if the entire column is zero
        snr=db2pow(snr);
        sd_check(:,all(snr == -Inf))=[]; % removes column if the entire column is zero    
        probs(:,all(snr == -Inf))=[]; % removes column if the entire column is zero
        snr(:,all(snr == -Inf))=[]; % removes column if the entire column is zero
        
        sd_check(:,all(isnan(snr)))=[]; % removes column if the entire column is zero   
        probs(:,all(isnan(snr)))=[]; % removes column if the entire column is zero
        snr(:,all(isnan(snr)))=[]; % removes column if the entire column is zero
        
        sd_check(:,all(snr == 0))=[]; % removes column if the entire column is zero
        probs(:,all(snr == 0))=[]; % removes column if the entire column is zero
        snr(:,all(snr == 0))=[]; % removes column if the entire column is zero
                if isempty(snr)
            disp("there are no SRC available");
        end
        if inst==6
            disp('')
        end
        snr = pow2db(snr);
        ind_raw = snr.*sd_check;
        dir_raw = snr.*not(sd_check);
        dir_sel = zeros(1,size(dir_raw,2));
        dir_sel(sum(dir_raw == 0)==16)=NaN;
        ind_sel = zeros(1,size(ind_raw,2));
        ind_sel(sum(ind_raw == 0)==16)=NaN;
        dir_sel(dir_sel==0) = dir_raw(1,dir_sel==0);
        dir_sel(dir_sel==0) = dir_raw(3,dir_sel==0);
        dir_sel(dir_sel==0) = dir_raw(9,dir_sel==0);
        dir_sel(dir_sel==0) = dir_raw(11,dir_sel==0);

        dir_sel(dir_sel==0) = dir_raw(5,dir_sel==0)-20;
        dir_sel(dir_sel==0) = dir_raw(7,dir_sel==0)-20;
        dir_sel(dir_sel==0) = dir_raw(13,dir_sel==0)-20;
        dir_sel(dir_sel==0) = dir_raw(15,dir_sel==0)-20;

        ind_sel(ind_sel==0) = ind_raw(1,ind_sel==0);
        ind_sel(ind_sel==0) = ind_raw(2,ind_sel==0);
        ind_sel(ind_sel==0) = ind_raw(5,ind_sel==0);
        ind_sel(ind_sel==0) = ind_raw(6,ind_sel==0);

        ind_sel(ind_sel==0) = ind_raw(9,ind_sel==0)-20;
        ind_sel(ind_sel==0) = ind_raw(10,ind_sel==0)-20;
        ind_sel(ind_sel==0) = ind_raw(13,ind_sel==0)-20;
        ind_sel(ind_sel==0) = ind_raw(14,ind_sel==0)-20;

        if not(sum(dir_sel==0)==0) && not(sum(ind_sel==0)==0)
            disp('PROBLEM!!')
        end
        bad_index = sort([find(isnan(dir_sel)) find(isnan(ind_sel))]);
        sd_check(:,bad_index) = [];
        dir_sel(bad_index)=[];
        ind_sel(bad_index)=[];
        snr(:,bad_index)=[];
        probs(:,bad_index)=[];
        base = not(sd_check).*dir_sel + sd_check.*ind_sel;

        % if sum(not(any(sd_check([1 2 5 6 9 10 13 14],:)))) > 0
        %     continue;
        % else
        %     %avevo un idea di recuperare l'SNR base del link indiretto, ma
        %     %non funziona sempre, e comunque le statistiche di loss sono
        %     %rovinate dalla presenza degli edifici. Solo la probabilità
        %     %dello stato è imparziale
        %     dir_base = 1;
        %     ind_base = 2;
        % end
        snr = base - snr;

        snr = db2pow(snr);
        avg_loss = avg_loss + mean(snr,2);

        avg_state_probs = avg_state_probs + mean(probs,2);
    end
    avg_state_probs = avg_state_probs/(num_inst - bad_inst);
    avg_loss = avg_loss/(num_inst - bad_inst);
end
index = find(avg_state_probs);
% [val, idx] = sort(avg_state_probs,"descend");
idx = [1 2 5 6 3 4 7 8 9 10 13 14 11 12 15 16];
labels = {'1: ';'2: ';'3: ';'4: ';'5: ';'6: ';'7: ';'8: ';'9: ';'10: ';'11: ';'12: ';'13: ';'14: ';'15: ';'16: '};
pct = avg_state_probs;
%labels = {'Free Space';'Obst Dir';'Obst Ref';'Obst Dir&Ref';'SBZ Dir';'All Dir';'SBZ Dir Obst Ref';'All Dir Obst Ref';'SBZ Ref';'Obst Dir SBZ Ref';'All Ref';'All Ref Obst Dir';'SBZ Dir&Ref';'All Dir SBZ Ref';'All Ref SBZ Dir';'All Blocked'};
figure;
% pie(avg_state_probs(idx),pct(idx));
prf= pie(avg_state_probs(idx),[1 0 1 0 0 0 0 0 1 0 1 0 0 0 0 0]);
pax=gca;
% title('Average Link State Blockage Probability');

% lgd = legend(cellstr(num2str(idx)),'Location','eastoutside');
% lgd = legend(cellstr(num2str(index)),'Location','eastoutside');
figure;
blf = bar(1:16,pow2db(avg_loss(idx)'));
lax=gca;
figure;
cof = pie(avg_state_probs(idx).*avg_loss(idx),pct);
cax = gca;
pText = findobj(prf,'Type','text');
lText = findobj(blf,'Type','text');
cText = findobj(cof,'Type','text');
for i=1:16
    prob_labels{i} = [labels{i} num2str(round(avg_state_probs(idx(i))*100,2)) '%'];
    pText(i).String = prob_labels(i);
    % loss_labels{i} = [labels{i} num2str(round(pow2db(avg_loss(idx(i))),1)) ' dB'];
    % lText(i).String = loss_labels(i);
    comb_labels{i} = [labels{i} num2str(round(pow2db(avg_state_probs(idx(i))*avg_loss(idx(i))),1)) ' dB'];
    cText(i).String = comb_labels(i);
end
title(pax,'Probability distribution of the states of blockage')
title(lax,'Average blockage loss per state')

% lgd = legend(cellstr(num2str(index)),'Location','eastoutside');
%scrivere codice che modifica gli stati in modo che sono come quelli nel
%paper
