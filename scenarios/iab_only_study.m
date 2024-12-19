function [scenario] = iab_only_study()
% $Author: Eugenio Moro $	$Date: 2020/11/30 16:25:24 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020

%inherit all the default parameters
addpath('simulation_scenarios')
scenario = default_scenario();
scenario.grid_factor = 4;

scenario.name = mfilename;

scenario.has_buildings = false;
%scenario.build_descr = [[10 20 10 80]; ...
%    [40 20 10 80]];
%     scenario.build_descr = [10 40 40 20]; ...
%     [40 20 10 80]];
%scenario.ris_on_buildings = true;
%scenario.build_descr = [];

scenario.OF_weight = 1;
scenario.rate_ratio = 0.5;
scenario.ris_budget = 3;
scenario.iab_budget = 10;

% geometry
scenario.generation_policy = 'uniform';
scenario.site_height = 600; %meters
scenario.site_width  = 800; %meters

scenario.tp_km2 = 125;
scenario.cs_km2 = 208;
scenario.site_area = scenario.site_height*scenario.site_width*1e-6;

%arbitrary number of sites and test points if uniform dist. is used
scenario.uniform_n_cs = round(scenario.site_area*scenario.cs_km2);
scenario.uniform_n_tp = round(scenario.tp_km2*scenario.site_area);


%depl costs
scenario.donor_price = 9;
scenario.iab_price = 1;
scenario.rel_price = 0.15;
scenario.budget = 10;



%L_acc and L_bh are used for variable pruning. Loose pruning will set L to
%zero if the rx_power at the link is lower than sensitivity. Strict
%pruning will set L to zero if MISO cannot guarantee min peak rate
%PRUNING = 'strict';
scenario.PRUNING = 'loose';

%k coverage
scenario.K=1;

%angle
scenario.min_angle_threshold = 60;
scenario.ris_components = 1e4;

%budgeting

% scenario.donor_price = 1;
% scenario.ris_price = scenario.donor_price*0.05;

%minimum rates
scenario.R_dir_min = 10:10:100; %mbps
scenario.mcs_count = 12; %this must be between 1 and 12, how many of the available mcs to include in the scenario

%compute size
scenario.size = 1;
f_names = fieldnames(scenario);
for fn=1:numel(f_names)
    %if field is not numeric then multiply by 1
%     if fn == 47
%         disp('debug');
%     end
%     disp([f_names{fn} num2str(...
%         numel(scenario.(f_names{fn}))*isnumeric(scenario.(f_names{fn}))...
%         + ~isnumeric(scenario.(f_names{fn})))])
    scenario.size = scenario.size*(...
        numel(scenario.(f_names{fn}))*isnumeric(scenario.(f_names{fn}))...
        + ~isnumeric(scenario.(f_names{fn}))...
        );
end
scenario.contains_vector = scenario.size > 1;

end
