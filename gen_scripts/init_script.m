
addpath('utils', 'radio', 'gen_scripts');
%these are local options that should be set to 1 only for debug
PLOT_SITE = 0;
PLOT_DISTANCE_STATISTICS = 0;


%unpack scenario into workspace
scenario.rng_seed = rng_seed;
v2struct(scenario);
clear size;
rng(rng_seed);