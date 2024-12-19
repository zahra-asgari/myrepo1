clearvars;
addpath('utils');
sim_folder = 'mat_results/';
sim_id = 'Sim_2';

%%
plot(str2num(char(ticks_labels)),avg_ang_sep);
hold on;
grid on;

xlabel('Available RIS slots');
ylabel('Average angular separation [degrees]');
sdf('Polimi-ppt');

%%
plot(str2num(char(ticks_labels)),avg_linlen);
hold on;
grid on;

xlabel('Available RIS slots');
ylabel('Average SRC link length [m]');
sdf('Polimi-ppt');

%%
plot(str2num(char(ticks_labels)),avg_ris);
hold on;
grid on;

xlabel('Available RIS slots');
ylabel('Installed RIS');
sdf('Polimi-ppt');