function bitrate = table_rate_calc(BW,SNR,mu,table)
if not(exist('mu','var'))
    %default numerology
    mu = 3;
end
bits_per_symbol= zeros(size(SNR));
coding_rate = zeros(size(SNR));
bitrate_raw= zeros(size(SNR));
bitrate_pol = zeros(size(SNR));
bitrate = zeros(size(SNR));

%1 datastream 2 datastreams Index Mod.order CodeRate(over 1024) Sp.Eff.
%data from Huawei
QAM64_table = [
    -3.19 -0.38  0 2 120 0.2344;
    -2.15  0.55  1 2 157 0.3066;
    -1.12  1.48  2 2 193 0.377;
    -0.08  2.41  3 2 251 0.4902;
    0.95  3.34  4 2 308 0.6016;
    1.73  4.22  5 2 379 0.7402;
    2.52  5.10  6 2 449 0.877;
    3.30  5.98  7 2 526 1.0273;
    4.08  6.85  8 2 602 1.1758;
    4.87  7.73  9 2 679 1.3262;
    5.27  8.04 10 4 340 1.3281;
    6.11  8.92 11 4 378 1.4766;
    6.95  9.80 12 4 434 1.6953;
    7.79 10.68 13 4 490 1.9141;
    8.52 11.58 14 4 553 2.1602;
    9.25 12.49 15 4 616 2.4063;
    9.98 13.39 16 4 658 2.5703;
    10.87 14.23 17 6 438 2.5664;
    11.69 15.06 18 6 466 2.7305;
    12.51 15.89 19 6 517 3.0293;
    13.33 16.72 20 6 567 3.3223;
    14.15 17.56 21 6 616 3.6094;
    14.97 18.39 22 6 666 3.9023;
    16.20 19.63 23 6 719 4.2129;
    17.43 20.87 24 6 772 4.5234;
    18.66 22.11 25 6 822 4.8164;
    19.89 23.35 26 6 873 5.1152;
    21.13 24.59 27 6 910 5.332;
    22.36 25.84 28 6 948 5.5547;
    ];

QAM256_table = [
    NaN -1 0 2 120 0.2344;
    NaN 0 1 2 193 0.377;
    NaN 1 2 2 308 0.6016;
    NaN 3 3 2 449 0.877;
    NaN 5 4 2 602 1.1758;
    NaN 7 5 4 378 1.4766;
    NaN 8 6 4 434 1.6953;
    NaN 9 7 4 490 1.9141;
    NaN 10 8 4 553 2.1602;
    NaN 11 9 4 616 2.4063;
    NaN 12 10 4 658 2.5703;
    NaN 13 11 6 466 2.7305;
    NaN 14 12 6 517 3.0293;
    NaN 15 13 6 567 3.3223;
    NaN 16 14 6 616 3.6094;
    NaN 17 15 6 666 3.9023;
    NaN 18 16 6 719 4.2129;
    NaN 19 17 6 772 4.5234;
    NaN 20 18 6 822 4.8164;
    NaN 21 19 6 873 5.1152;
    NaN 22 20 8 682.5 5.332;
    NaN 23 21 8 711 5.5547;
    NaN 24 22 8 754 5.8906;
    NaN 25 23 8 797 6.2266;
    NaN 26 24 8 841 6.5703;
    NaN 27 25 8 885 6.9141;
    NaN 28 26 8 916.5 7.1602;
    NaN 29 27 8 948 7.4063;
    ];


if not(exist('table','var'))
    sel_table = QAM256_table;
else
    switch table
        case '64QAM'
            sel_table = QAM64_table;
        case '256QAM'
            sel_table = QAM256_table;
    end
end



%table from 3GPP 38.101-2 v17.6 Table 5.3.2-1: Resource Block allocation
%based on sub-carrier spacing and total bandwidth
%rows: mu=2 (SCS 60 kHz), mu=3 (SCS 120 kHz), mu=5 (SCS 480 kHz), mu=6 (SCS
%960 kHz); mu=5,6 are optional
%columns: B = [50 100 200 400 800 1600 2000] MHz; bandwiths >400 MHz are
%not of our interest for now
%default mu=3, considered bandwidths = 100,200,400 MHz
N_RB = [  66 132 264 NaN NaN NaN NaN;
    32  66 132 264 NaN NaN NaN;
    NaN NaN NaN  66 124 248 NaN;
    NaN NaN NaN  33  62 124 148;
    ];
N_RB_mu = [2 3 5 6]; %numerology in tables
N_RB_BW = [50 100 200 400 800 1600 2000]; %considered bandwidths
rank = 2; %number of independent datastreams
ind_x = N_RB_mu==mu;
ind_y = N_RB_BW==(BW/1e6);
subframes_per_frame = 10;
subcarriers_per_RB = 12;
symbols_per_slot = 14;
slots_per_subframe = 2^mu;
slots_per_frame = slots_per_subframe*subframes_per_frame;
frame_length = 1e-2; % 10 ms
num_pol = 2; %2T-2R polarization gain
overhead_5G = 0.28; %overhead of control messages
N_RE_tot = N_RB(ind_x,ind_y)*subcarriers_per_RB*symbols_per_slot*slots_per_frame;

selected_MCS = sum(SNR >= sel_table(:,rank)',2);
blockage_states = find(selected_MCS);
bits_per_symbol(blockage_states) = sel_table(selected_MCS(blockage_states),4);
coding_rate(blockage_states) = sel_table(selected_MCS(blockage_states),5)/1024;
bitrate_raw(blockage_states) = (N_RE_tot*bits_per_symbol(blockage_states).*coding_rate(blockage_states))/(frame_length*1e6);
bitrate_pol(blockage_states) = bitrate_raw(blockage_states)*num_pol;
bitrate(blockage_states) = bitrate_pol(blockage_states)*(1-overhead_5G);

end