
%alpha and beta parameters of the model
%alpha = n_antennas*ris_components^2*(4/pi) +n_antennas*ris_components*(4-pi);
alpha = n_antennas*ris_components^2*(pi/4) + n_antennas*ris_components*(1-pi/4);
beta  = 2*ris_components*sqrt(n_antennas);


%PHI parameters
phi_LOS = n_antennas.*cs_tp_pathloss_LOS;
phi_NLOS = n_antennas.*cs_tp_pathloss_NLOS;

%THETA parameters
%we have one theta for each donor-rs-tp triplet
theta_LOS = ones(n_tp,n_cs,n_cs).*pi/4;
theta_NLOS = theta_LOS;

for d=1:n_cs
    for r=1:n_cs
        for t=1:n_tp
            theta_LOS(t,d,r) = ...
                sqrt(cs_cs_pathloss_LOS(d,r))*sqrt(pi)/2*...  %this is donor-ris
                sqrt(cs_tp_pathloss_LOS(d,t))*...              %this is ris-tp
                sqrt(cs_tp_pathloss_LOS(r,t));                 %this is donor-tp
        end
    end
end
for d=1:n_cs
    for r=1:n_cs
        for t=1:n_tp
            theta_NLOS(t,d,r) = ...
                sqrt(cs_cs_pathloss_LOS(d,r))*sqrt(pi)/2*...  %this is donor-ris
                sqrt(cs_tp_pathloss_LOS(d,t))*...              %this is ris-tp
                sqrt(cs_tp_pathloss_NLOS(r,t));                %this is donor-tp
        end
    end
end

% GAMMA parameters
%we have one gamma for each donor-rs-tp triplet
gamma_radio = ones(n_tp,n_cs,n_cs);

for d=1:n_cs
    for r=1:n_cs
        for t=1:n_tp
            gamma_radio(t,d,r) = ...
                cs_tp_pathloss_LOS(r,t)*... ris_tp
                cs_cs_pathloss_LOS(d,r);
        end
    end
end

%finally we multiply by ptx_lin and alpha or beta in order to rx_power
%contributions (linear)
ptx_lin = 10^(0.1*p_tx);
gamma_radio = gamma_radio.*ptx_lin.*alpha;
theta_LOS = theta_LOS.*ptx_lin.*beta;
theta_NLOS = theta_NLOS.*ptx_lin.*beta;
phi_LOS = phi_LOS.*ptx_lin;
phi_NLOS = phi_NLOS.*ptx_lin;
