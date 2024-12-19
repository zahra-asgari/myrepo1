function [scenario] = a300x300_24cs_15tp()
% $Author: Eugenio Moro $	$Date: 2020/11/30 16:25:24 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020

%inherit all the default parameters
addpath('scenarios')
scenario = parent_scenario();
scenario.site.grid_factor = 4;

scenario.name = mfilename;

scenario.has_buildings = false;
%scenario.build_descr = [[10 20 10 80]; ...
%    [40 20 10 80]];
%     scenario.build_descr = [10 40 40 20]; ...
%     [40 20 10 80]];
%scenario.ris_on_buildings = true;
%scenario.build_descr = [];

scenario.sim.OF_weight = 0;
scenario.sim.ris_budget = 7;
scenario.sim.iab_budget = 6;
scenario.sim.rate_ratio = 1;
%scenario.rate_ratio = 0.0:0.2:1;
% geometry
scenario.site.generation_policy = 'uniform';
scenario.site.site_height = 300; %meters
scenario.site.site_width  = 300; %meters

%arbitrary number of sites and test points if uniform dist. is used
scenario.site.uniform_n_cs = 25;
scenario.site.uniform_n_tp = 15;



%depl costs
scenario.sim.donor_price = 9;
scenario.sim.iab_price = 1;
scenario.sim.af_price = 0.5;



%L_acc and L_bh are used for variable pruning. Loose pruning will set L to
%zero if the rx_power at the link is lower than sensitivity. Strict
%pruning will set L to zero if MISO cannot guarantee min peak rate
%PRUNING = 'strict';
scenario.PRUNING = 'loose';

%k coverage
scenario.K=1;

%angle
scenario.sim.min_angle_threshold = 60;
scenario.radio.ris_components = 1e4;

%budgeting

% scenario.donor_price = 1;
% scenario.ris_price = scenario.donor_price*0.05;
scenario.sim.ris_price=0.1;
%minimum rates
scenario.sim.R_dir_min = 100; %mbps
scenario.sim.uplink_ratio=0.1;
scenario.mcs_count = 12; %this must be between 1 and 12, how many of the available mcs to include in the scenario

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
