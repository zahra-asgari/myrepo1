af_bf_gain_lin = 10^(0.1*af_bf_gain);
af_tx_pwr_lin = 10^(0.1*af_tx_pwr); %mwatt
af_noise = -174 + 10*log10(bandwidth) + af_noise_fig; %db
af_noise_lin = 10^(0.1*af_noise);
ue_noise_lin = 10^(0.1 * ( -174 + 10*log10(bandwidth) + ue_noise_fig));

af_rel_snr = zeros(n_tp, n_cs, n_cs);

for r = 1:n_cs
    for d = 1:n_cs
        if r == d
            continue;
        end
        % beta depends only on donor-relay channel
        beta_sqrd = ( af_tx_pwr_lin * af_bf_gain_lin )...
            /(ptx_lin * af_bf_gain_lin * cs_cs_pathloss_LOS(r,d) + af_noise_lin);
        for t = 1:n_tp
            af_rel_snr(t,d,r)=...
                ptx_lin * af_bf_gain_lin * ( (beta_sqrd * cs_cs_pathloss_LOS(r,d) * cs_tp_pathloss_LOS(r,t)) /...
                (beta_sqrd * cs_tp_pathloss_LOS(r,t) * af_noise_lin + ue_noise_lin ));
        end
    end
end

af_rel_rate = bandwidth.*log2(1+af_rel_snr)./1e6;
af_rel_rate(isnan(af_rel_rate)) = 0;