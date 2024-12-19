ue_noise_lin = 10^(0.1 * ( -174 + 10*log10(bandwidth) + ue_noise_fig));
ris_snr = gamma_radio./ue_noise_lin;
ris_rate = bandwidth.*log2(1+ris_snr)./1e6;
ris_rate (ris_rate == inf) = 0;