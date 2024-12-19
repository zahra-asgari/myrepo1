% for each movement, we should:
% .1 check if no violation
% .1 update the less violation movement (if no violation, then this is 0)
% .1 update the best sum rates

movs = [clk_movement cnt_movement];

sum_rates = zeros(numel(movs),1);
largest_violations = zeros(numel(movs),1);
satisfied_tps = zeros(numel(movs),1);

[cov_t, cov_d] = ind2sub(size(squeeze(s(:,:,ris))),find(squeeze(s(:,:,ris))));

for mov_index = 1:numel(movs)
    
    mov=movs(mov_index);
    l_v = 0;
    for i = 1:length(cov_t) %for each tp
        
        tp = cov_t(i);
        don= cov_d(i);
        
        %compute rate
        phi_inc = abs(cs_cs_angles(ris, don)-(delta(ris)+mov));
        phi_ref = abs(cs_tp_angles(ris, tp)-(delta(ris)+mov));
        tp_rate = src_rate(...
            cs_tp_distance_matrix(don,tp),...
            cs_cs_distance_matrix(don,ris),...
            cs_tp_distance_matrix(ris,tp),...
            phi_inc, phi_ref)...
            .*tau_ris(tp,don,ris);
        
        %disp(['TP ' num2str(tp) ' rate ' num2str(tp_rate)]);
       
        % add rate to sum_rates
        sum_rates(mov_index) = sum_rates(mov_index) + tp_rate;
        
        %if rate is violation the update the largest violation
        if tp_rate < R_out_min
            l_v = max([l_v R_out_min-tp_rate]);
        else
            satisfied_tps(mov_index) = satisfied_tps(mov_index) + 1;
        end
    end
    largest_violations(mov_index) = max([largest_violations(mov_index) l_v]);
end

if sum(largest_violations) == 0
    [~, delta_offset] = max(sum_rates);
    satisfied_tps = satisfied_tps(delta_offset);
    delta_offset = movs(delta_offset);
    
%disp(['RIS ' num2str(ris) ' needed no correction, maximizing mov selected: ' num2str(delta_offset)]);
else
    [lv, delta_offset] = min(largest_violations);
    satisfied_tps = satisfied_tps(delta_offset);
    delta_offset = movs(delta_offset);
%    disp(['RIS ' num2str(ris) ' needed correction, best mov selected: ' num2str(delta_offset) ' which brought the worst violation to ' num2str(lv)]);
end