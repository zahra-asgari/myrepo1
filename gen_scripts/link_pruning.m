
switch PRUNING
    case 'loose'
        %link cannot be established if MISO rx power less than sensitivity
        MISO_rx_power = p_tx + 10*log10(cs_tp_pathloss_LOS*n_antennas);
        links_cs_tp = (MISO_rx_power >= rx_sensitivity);
        MISO_rx_power = p_tx + 10*log10(cs_cs_pathloss_LOS*n_antennas);
        links_cs_cs = (MISO_rx_power >= rx_sensitivity);
    case 'strict'
        %link cannot be established if MISO rate is less than minimum rate
        if scenario.fakeris
            s_angle_ok = s_angle_ok & (expected_rate_wris >= R_out_min);
        else
            MISO_rx_power = p_tx + 10*log10(cs_tp_pathloss_LOS*n_antennas);
            MISO_rate = bw.*log2(1+10.^(0.1*(MISO_rx_power-noise_pwr)));
            links_cs_tp = (MISO_rate >= rate_peak_LOS);
            MISO_rx_power = p_tx + 10*log10(cs_cs_pathloss_LOS*n_antennas);
            MISO_rate = bw.*log2(1+10.^(0.1*(MISO_rx_power-noise_pwr)));
            links_cs_cs = (MISO_rate >= rate_peak_LOS);
        end
    otherwise
        error('Unrecognized pruning option in instance generation')
end

%print max and min achiveable capacity
%disp(['Max achiveable rate: ' num2str(bw*log2(10^(0.1*(p_tx-noise_pwr))*n_antennas*max(cs_tp_pathloss_LOS(:))))]);
%disp(['Min achiveable rate: ' num2str(bw*log2(10^(0.1*(p_tx-noise_pwr))*n_antennas*min(cs_tp_pathloss_LOS(:))))]);

