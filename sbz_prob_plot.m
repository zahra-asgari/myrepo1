clear all; clc; close all;
portrait_angle = 120;
portrait_prob = 0.5;
landscape_angle = 160;
landscape_prob = 1 - portrait_prob;
step = 0.001;
delta_theta = 0:step:180;
tot_delta = numel(delta_theta); 
rsbz_probs = portrait_prob * (max(((portrait_angle - delta_theta)/portrait_angle),0))...
    + landscape_prob * (max(((landscape_angle - delta_theta)/landscape_angle),0));
r_n_sbz_probs = portrait_prob * (((360 - portrait_angle) - delta_theta)/(360 - portrait_angle))...
    + landscape_prob * (((360 - landscape_angle) - delta_theta)/(360 - landscape_angle));

plot(delta_theta,rsbz_probs,'DisplayName','both in sbz');
hold on;
plot(delta_theta,r_n_sbz_probs, 'DisplayName','only r in sbz');
legend
dir_angle_p = 0:step:portrait_angle;
dir_angle_l = 0:step:landscape_angle;
tot_p = numel(dir_angle_p);
tot_l = numel(dir_angle_l);
rsbz_mc = zeros(size(rsbz_probs));
for i=1:tot_delta
    p_count = 0;
    l_count = 0;
    for j=1:tot_l
        if dir_angle_l(j) < portrait_angle
            if dir_angle_p(j) + delta_theta(i) < portrait_angle
                p_count = p_count + 1;
            end
        end
        if dir_angle_l(j) + delta_theta(i) < landscape_angle
            l_count = l_count + 1;
        end    
    end
    rsbz_mc(i) = portrait_prob*(p_count/tot_p) + landscape_prob*(l_count/tot_l);
end

n_dir_angle_p = 0:0.01:(360 - portrait_angle);
n_dir_angle_l = 0:0.01:(360 - landscape_angle);
n_tot_p = numel(n_dir_angle_p);
n_tot_l = numel(n_dir_angle_l);
r_n_sbz_mc = zeros(size(r_n_sbz_probs));
for i=1:tot_delta
    n_p_count = 0;
    n_l_count = 0;
    for j=1:n_tot_p
        if n_dir_angle_p(j) < 360 - landscape_angle
            if n_dir_angle_l(j) + delta_theta(i) < 360 - landscape_angle
                n_l_count = n_l_count + 1;
            end
        end
        if n_dir_angle_p(j) + delta_theta(i) < 360 - portrait_angle
            n_p_count = n_p_count + 1;
        end    
    end
    r_n_sbz_mc(i) = portrait_prob*(n_p_count/n_tot_p) + landscape_prob*(n_l_count/n_tot_l);
end
plot(delta_theta,rsbz_mc,'DisplayName','both in sbz-mc');
plot(delta_theta,1 - r_n_sbz_mc,'DisplayName','only r in sbz-mc');

figure
plot(delta_theta,rsbz_probs - rsbz_mc,'DisplayName','Error for sbz');
figure
plot(delta_theta,(1 - r_n_sbz_probs) - (1 - r_n_sbz_mc),'DisplayName','Error for nsbz');