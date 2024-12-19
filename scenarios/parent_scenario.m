function [default_scenario] = parent_scenario()
% $Author: Eugenio Moro $	$Date: 2020/11/30 16:25:24 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020

%this contains the default parameters, everything not set in the simulation
%scenario script is defaulted according to these values
default_scenario.name = mfilename;

%% site parameters

% misc options
site.singleRis = false;
site.tuplematic = false;
site.fakeris = false;
site.has_buildings = false;
site.ris_on_buildings = false;
site.ris_only = false;
site.has_relays = false;
site.starting_tp_positioning = 2;
site.fixed_donor_position = false;

% geometry
site.generation_policy = 'uniform';
site.site_shape = 'rectangular';
%site.site_shape = 'hexagonal';
site.site_height = 80; %meters
site.site_width  = 800; %meters
site.grid_factor = 1; %the total area is divided in grid_factor^2 sectors, useful for more homogenous random positions of tp and cs
site.building_surface_sampling = 2;

% cs and tp options
site.max_pregen_tp = 256;
site.max_pregen_cs = 256;

%tp and cs generated as poisson point processes
site.cs_density = 1e-4; %CSs per m^2
site.tp_density = 0.6e-4;  %TPs per m^2

%arbitrary number of sites and test points if uniform dist. is used
site.uniform_n_cs = 15;
site.uniform_n_tp = 3;

%% sim parameters
%angle
sim.max_angle_span = 80; %we hardcoded it as 160 degree FoV
sim.min_angle_sep = 30;

%multiobj
sim.mu = 0.5;

%budgeting
sim.budget = 30;
sim.sem_budget = 5;
sim.donor_price = 1;
sim.ris_price = sim.donor_price*0.1;
sim.af_price = sim.donor_price*0.05;

%minimum rates
sim.R_out_min = 0; %mbps
sim.R_dir_min = 0; %mbps

sim.uplink_ratio = 0.1;

%% snr model

radio.snr_model = 'advanced';

%% radio parameters for the base snr model
%radio - bs
radio.n_antennas = 64;
radio.ris_components = 800;
radio.p_tx = 30; %dBm
radio.noise_pwr = -90; %dBm
radio.rx_sensitivity = -78; %dBm
radio.snr_at_tx = 10^(0.1*(radio.p_tx-radio.noise_pwr));
radio.bandwidth = 200e6;
radio.rate_calc = 'shannon'; %options 'shannon' for simple shannon capacity or '3GPP' for table calculation of real FR2 bitrates
radio.bs_noise_fig = 8.5; % dB

%radio - af
radio.af_bf_gain = 29; % db
radio.af_tx_pwr = 27; % dbm
radio.af_noise_fig = 8; %db

%radio - ue
radio.ue_noise_fig = 8; %db

radio.mcs_count = 5; %this must be between 1 and 13, how many of the available mcs to include in the scenario


%% radio parameters for the advanced snr model

radio.ue_height = 1.5;
radio.ris_height = 3;
radio.iab_height = 6;
radio.donor_height = 1.5;

% propagation parameters
radio.radio_prm.BW = 200e6;
radio.radio_prm.fc = 28e9;                   % [Hz] carrier frequency
radio.radio_prm.a =1;                        % reflection amplitude at irs
%radio.c = physconst('lightspeed');     % lightspeed
radio.radio_prm.lambda =  physconst('lightspeed') / radio.radio_prm.fc;         % [m] wavelength
radio.radio_prm.ShadowingSTD = 0;
radio.radio_prm.ElementDirectivity = 'true';
% Config.InOut  = 'SISO'; % 'SISO' or 'MIMO'
radio.radio_prm.RIS_policy = 'FF_Assympt';

radio.ShadowingSTD = 0;

radio.radio_prm.PL_models.Tx2Rx = 'UMi';
radio.radio_prm.PL_models.Tx2AF = 'UMi';
radio.radio_prm.PL_models.AF2Rx = 'UMi';

default_scenario.site = site;
default_scenario.radio = radio;
default_scenario.sim = sim;

%% 
default_scenario.contains_vector = false;
end
