mcs_struct = get_mcs(mcs_count);
n_mcs = numel(mcs_struct.data_rates);
pwr_thr = mcs_struct.pwr_thr;
mcs_rate = mcs_struct.data_rates;
max_rate = mcs_struct.data_rates(end);