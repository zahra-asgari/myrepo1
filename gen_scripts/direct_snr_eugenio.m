direct_snr = zeros(n_tp,n_cs);
p_tx_lin = 10^(0.1*p_tx);
bs_noise = -174 + 10*log10(bandwidth) + bs_noise_fig;
bs_noise_lin = 10^(0.1*bs_noise);

for t=1:n_tp
    for d = 1:n_cs
        direct_snr(t,d) = (n_antennas * p_tx_lin * cs_tp_pathloss_LOS(d,t))/bs_noise_lin;
    end
end

direct_rate = bandwidth.*log2(1+direct_snr)./1e6;