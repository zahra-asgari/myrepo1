function [mcs] = get_mcs(varargin)
%GET_MCS This function returns the MCS struct containing index, rate and
%SINR thresholds. Requires noise power in dBm. Values taken from "S. Sur,
%V. Venkateswaran, X. Zhang and P. Ramanathan, "60 GHz indoor networking
%through flexible beams: A link-level profiling". Data rates are in mbps.
%mcs_count is how many of the available mcs have to be included. This
%number should be between 1 and the tot mcs count. The function makes sure
%that if mcs_count>1 then both the least and most performing schemes are
%included. 

%mcs.pwr_thr = 10.^(0.1.*([-78; -68; -66; -65; -64; -62; -63; -62; -61; -59; -55; -54; -53]));
%mcs.data_rates = [27.5 385 770 962.5 1155 1251.25 1540 1925 2310 2502.5 3080 3850 4620]';

mcs.pwr_thr = 10.^(0.1.*([-78; -68; -66; -65; -64; -63; -62; -61; -59; -55; -54; -53]));
mcs.data_rates = [27.5 385 770 962.5 1155 1540 1925 2310 2502.5 3080 3850 4620]';
    
if nargin > 0
      mcs.pwr_thr = mcs.pwr_thr(floor(linspace(1,numel(mcs.pwr_thr),varargin{1})));
      mcs.data_rates = mcs.data_rates(floor(linspace(1,numel(mcs.data_rates),varargin{1})));
end 
end


