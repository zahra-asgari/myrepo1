function [scenario] = hexagonal_area()
% $Author: Eugenio Moro $	$Date: 2020/11/30 16:25:24 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020

%inherit all the default parameters
addpath('simulation_scenarios')
scenario = parent_scenario();
scenario.name = mfilename;

%% site parameters 

scenario.site.grid_factor = 4;

scenario.site.generation_policy = 'uniform';
scenario.site.site_height = 400; %meters
scenario.site.site_width  = 400; %meters
scenario.site.site_shape = 'hexagonal';
scenario.site.fixed_donor_position = true;

scenario.site.generation_policy = 'uniform';
scenario.site.uniform_n_cs = 25;
scenario.site.uniform_n_tp = 15;


%% sim parameters

scenario.sim.OF_weight = 0.5;
scenario.sim.ris_budget = 3;
scenario.sim.iab_budget = 6;
scenario.sim.rate_ratio = 0.5;

%depl costs
scenario.sim.donor_price = 9;
scenario.sim.iab_price = 1;
scenario.sim.af_price = 0.5;
scenario.sim.ris_price=0.1;
%minimum rates
scenario.sim.R_dir_min = 100; %mbps

%% misc

scenario.radio.snr_model = 'advanced';

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
