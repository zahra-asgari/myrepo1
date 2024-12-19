function [scenario] = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel()
% $Author: Eugenio Moro $	$Date: 2020/11/30 16:25:24 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020

%inherit all the default parameters
%addpath('simulation_scenarios')
scenario = parent_scenario();
scenario.name = mfilename;

sc_id = "small";  %"comparison";
%% site parameters

scenario.site.grid_factor = 4;

scenario.site.generation_policy = 'uniform';
scenario.site.site_height = 300; %meters
scenario.site.site_width  = 300; %meters
scenario.site.site_shape = 'hexagonal';
scenario.site.fixed_donor_position = true;
scenario.site.fakeris = true;
%scenario.site.ris_only = true;
 % scenario.site.coord_lim = [510584 5031547;518651 5039514]; %coordinate
 % limits used for the PIMRC 2023 paper. Use if you want to compute the
 % cache datahash correctly
scenario.site.coord_lim = [0.503210396303463 5.026366915335777; 0.521581559008898 5.042559474905842]*1e6; 
%preset UTM coordinate limit in the city of Milan to randomize realistic static blockage


scenario.site.generation_policy = 'uniform';
scenario.site.uniform_n_cs = 25; %25
scenario.site.uniform_n_tp = 15; %15
scenario.site.max_pregen_tp = 256;
scenario.site.max_pregen_cs = 256;

%% sim parameters

scenario.sim.OF_weight = 0.5;
scenario.sim.ris_budget = 3;
scenario.sim.iab_budget = 6;
% scenario.sim.budget = 10;
scenario.sim.budget = 0:0.2:20;
%scenario.sim.budget = old_budget(mod(old_budget,0.5)~=0);
scenario.sim.rate_ratio = 1;

%depl costs
scenario.sim.donor_price = 9;
scenario.sim.iab_price = 1;
scenario.sim.af_price = 0.5;
scenario.sim.ris_price=0.1;
%minimum rates
scenario.sim.alpha = 0.8; %alpha factor is the percentage of frame dedicated to DL, accepted values are:
                          %0.8 (4:1) and 0.4 (2:3)
scenario.sim.R_dir_min = 60; %150; %mbps left for checking the old solutions with only the downlink
% scenario.sim.R_dir_min = 0:2.5:250;
scenario.sim.R_dir_min_DL = scenario.sim.alpha*scenario.sim.R_dir_min; %Downlink Demand, mbps
scenario.sim.R_dir_min_UL = scenario.sim.R_dir_min - scenario.sim.R_dir_min_DL; %Uplink Demand, mbps

scenario.sim.SD_list = ["RIS","NCR"]; %list of smart devices so that they're addressed in the right order in the model

%% misc

scenario.radio.snr_model = 'advanced';
scenario.radio.rate_calc = '3GPP'; %use the Huawei tables
scenario.radio.donor_height = 25;
scenario.radio.bandwidth = 400e6;

%quick switch between default and small scenario
if sc_id == "small"
        scenario.site.site_height = 190;
        scenario.site.site_width  = 190;
        scenario.site.uniform_n_cs = 10;
        scenario.site.uniform_n_tp =  6;
        scenario.sim.budget =   0:.2:10;
        scenario.sim.R_dir_min = 60; %400;
        scenario.sim.R_dir_min_DL = scenario.sim.alpha*scenario.sim.R_dir_min; %Downlink Demand, mbps
        scenario.sim.R_dir_min_UL = scenario.sim.R_dir_min - scenario.sim.R_dir_min_DL; %Uplink Demand, mbps
end
disp(['The minimum demand is ' num2str(scenario.sim.R_dir_min) ' mbps']);


%% utils code
%compute size
scenario.size = 1;
f_names = fieldnames(scenario.sim);
for fn=1:numel(f_names)
    %if field is not numeric then multiply by 1
%     if fn == 47
%         disp('debug');
%     end
%     disp([f_names{fn} num2str(...
%         numel(scenario.(f_names{fn}))*isnumeric(scenario.(f_names{fn}))...
%         + ~isnumeric(scenario.(f_names{fn})))])
    scenario.size = scenario.size*(...
        numel(scenario.sim.(f_names{fn}))*isnumeric(scenario.sim.(f_names{fn}))...
        + ~isnumeric(scenario.sim.(f_names{fn}))...
        );
end
scenario.contains_vector = scenario.size > 1;

end
