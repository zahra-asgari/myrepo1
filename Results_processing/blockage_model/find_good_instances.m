%% init
clear all;
addpath('utils/','cache/','scenarios/');
sim_folder = 'extra_100/';
%sim_folder = 'forced_bottleneck_avg/';
model_name = {  'sumextra';
    'sumrate';
    };
%model_name = 'sumextra';
STAR = 0;
GAP = 1;
common_string = 'iab_ris_fixedDonor_fakeRis_blockageModel_';
scenario_struct = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel();
folder_names_root = 'hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel';
%% open results folder and list files curresponding to the model
load('/home/paolo/projects/RIS-Planning-Instance-Generator/Mat_files_solutions/buildings_test/bottleneck/data_sumextra_all.mat', 'peak_rate_sum','star_degree')
extra_peaks = peak_rate_sum;
extra_stars = star_degree;
load('/home/paolo/projects/RIS-Planning-Instance-Generator/Mat_files_solutions/buildings_test/bottleneck/data_sumrate_all.mat', 'peak_rate_sum','star_degree')
avg_peaks = peak_rate_sum;
avg_stars = star_degree;
cons_inst = 10;

if STAR
    best_stars.name = zeros(size(extra_stars,1),cons_inst);
    best_stars.value = zeros(size(extra_stars,1),cons_inst);
    for di=1:size(extra_stars,1)
        for inst=1:size(extra_stars,2)
            if isnan(extra_stars(di,inst)) || isnan(avg_stars(di,inst))
                continue;
            else
                best_stars = check_ranking(best_stars,extra_stars(di,inst)-avg_stars(di,inst),cons_inst,di,inst);
                %disp([best_stars.name(di,:); best_stars.value(di,:)]);
            end
            
        end
    end
end
star_podium = [best_stars.name(31:51,1) best_stars.value(31:51,1) (6:0.2:10)'];
[~,x] = max(star_podium(:,2));
star_podium = floor(star_podium);
disp(star_podium)

disp(['Widest star degree difference is ' num2str(star_podium(x,2)) ' in instance ' num2str(star_podium(x,1)) ' with budget ' num2str(6 + 0.2*(x-1))]);

if GAP
    best_gaps.name = zeros(size(extra_peaks,1),cons_inst);
    best_gaps.value = zeros(size(extra_peaks,1),cons_inst);
    for di=1:size(extra_peaks,1)
        for inst=1:size(extra_peaks,2)
            if isnan(extra_peaks(di,inst)) || isnan(avg_peaks(di,inst))
                continue;
            else
                best_gaps = check_ranking(best_gaps,extra_peaks(di,inst)-avg_peaks(di,inst),cons_inst,di,inst);
                %disp([best_gaps.name(di,:); best_gaps.value(di,:)]);
            end
            
        end
    end
end
gap_podium = [best_gaps.name(31:51,:) best_gaps.value(31:51,:)/scenario_struct.site.uniform_n_tp (6:0.2:10)'];
[~,x] = max(gap_podium(:,2));
gap_podium = floor(gap_podium);
disp(gap_podium)

disp(['Widest peak rate gap per user is ' num2str(gap_podium(x,2)) ' Mbps in instance ' num2str(gap_podium(x,1)) ' with budget ' num2str(6 + 0.2*(x-1))]);

function [top_x]= check_ranking(top_x,value,loop_no,di,inst)
if loop_no > 1
    if value > top_x.value(di,loop_no)
        top_x = check_ranking(top_x,value,loop_no -1,di,inst);
    elseif loop_no < numel(top_x.value(di,:))
        top_x.value(di,loop_no+2:numel(top_x.value(di,:))) = ...
            top_x.value(di,loop_no+1:numel(top_x.value(di,:))-1);
        top_x.name(di,loop_no+2:numel(top_x.name(di,:))) = ...
            top_x.name(di,loop_no+1:numel(top_x.name(di,:))-1);
        top_x.value(di,loop_no+1) = value;
        top_x.name(di,loop_no+1) = inst;
        %disp([top_x.name(di,:); top_x.value(di,:)]);
        
    end
else
    if value > top_x.value(di,loop_no)
        top_x.value(di,loop_no+1:numel(top_x.value(di,:))) = ...
            top_x.value(di,loop_no:numel(top_x.value(di,:))-1);
        top_x.name(di,loop_no+1:numel(top_x.name(di,:))) = ...
            top_x.name(di,loop_no:numel(top_x.name(di,:))-1);
        top_x.value(di,loop_no) = value;
        top_x.name(di,loop_no) = inst;
        %disp([top_x.name(di,:); top_x.value(di,:)]);
    else
        top_x.value(di,loop_no+2:numel(top_x.value(di,:))) = ...
            top_x.value(di,loop_no+1:numel(top_x.value(di,:))-1);
        top_x.name(di,loop_no+2:numel(top_x.name(di,:))) = ...
            top_x.name(di,loop_no+1:numel(top_x.name(di,:))-1);
        top_x.value(di,loop_no+1) = value;
        top_x.name(di,loop_no+1) = inst;
        %disp([top_x.name(di,:); top_x.value(di,:)]);
        
    end
end
end

