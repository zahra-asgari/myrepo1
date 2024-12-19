function [go] = get_global_options()
%GET_GLOBAL_OPTIONS This function returns a struct containing the global
%options of the campaign 
%   Global options are specified in GLOBAL_OPTIONS 

% import global options from definition file
GLOBAL_OPTIONS;

% pack variables into struct for convenience
go = v2struct();

end

