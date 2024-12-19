src_dir_rate = zeros(n_tp,n_cs,n_cs);
src_back_rate= zeros(n_tp,n_cs,n_cs);

mcs_count = 12;
mcs_struct = get_mcs(mcs_count);
n_mcs = numel(mcs_struct.data_rates);
pwr_thr = mcs_struct.pwr_thr;
mcs_rate = mcs_struct.data_rates;
max_rate = mcs_struct.data_rates(end);
pt = [pwr_thr; inf]; 

for t=1:n_tp
        for d=1:n_cs
        for r=1:n_cs
            
            if d==r
                continue;
            end
            src_dir_rate(t,d,r)  = mcs_rate(find(phi_LOS(d,t) > pt,1,'last'));
            src_back_rate(t,d,r) = mcs_rate(find(gamma_radio(t,d,r) > pt,1,'last'));
            
        end
    end
end
