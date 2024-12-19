function [max_airtime,reflected_airtime,bh_rate] ...
    = compute_rates_basemodel(scenario,cs_tp_distance_matrix,cs_cs_distance_matrix,cache_found, cache_path)
%COMPUTE_RATES_BASEMODEL This function generates the backhaul and access
%rates according to the basic pathloss and snr models (see documentation)

if nargin ==3
    cache_found = false;
    save_to_cache = false;
elseif nargin <3
    error('Not enough input arguments');
else
    save_to_cache = true;
end

if cache_found
    load(cache_path, 'max_airtime', 'reflected_airtime','bh_rate');
else
    [direct_rate,reflected_rate,bh_rate] =...
        channel_computation_eugenio(cs_tp_distance_matrix,cs_cs_distance_matrix,scenario);
    
    n_cs = size(cs_cs_distance_matrix,1);
    %n_tp = size(cs_tp_distance_matrix,2);
    
    direct_airtime = repmat(scenario.sim.R_dir_min./direct_rate, 1,1,n_cs);
    reflected_airtime = (scenario.sim.R_dir_min*scenario.sim.rate_ratio)./reflected_rate;
    max_airtime = max(direct_airtime, reflected_airtime);
    
    
    max_airtime(max_airtime == Inf) = 0;
    reflected_airtime(reflected_airtime == Inf) = 0;
    
    % save into cache
    if save_to_cache
        save(cache_path,'max_airtime','reflected_airtime','bh_rate','-append');
    end
end

bh_rate(bh_rate == 0) = 1; % zeros will break cplex
end

