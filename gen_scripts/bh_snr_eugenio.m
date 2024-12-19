bh_snr = zeros(n_cs,n_cs);
p_tx_lin = 10^(0.1*p_tx);
bs_noise = -174 + 10*log10(bandwidth) + bs_noise_fig;
bs_noise_lin = 10^(0.1*bs_noise);

for c=1:n_cs
    for d = 1:n_cs
        if c == d
            continue;
        end
        bh_snr(c,d) = (n_antennas * p_tx_lin * cs_cs_pathloss_LOS(c,d))/bs_noise_lin;
    end
end

bh_rate = bandwidth.*log2(1+bh_snr)./1e6;