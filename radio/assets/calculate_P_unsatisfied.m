
function P_unsatisfied = calculate_P_unsatisfied(rates_per_state, state_probabilities, C_min_DL, C_min_UL)

    % Get dimensions from inputs
    [n_tp, n_cs, ~, n_states] = size(rates_per_state.ris);

    % Initialize the unsatisfied probability matrix
    P_unsatisfied = zeros(n_tp, n_cs, n_cs); % For each TP, CS, and RIS/NCR

    % Loop through all TPs, Candidate Sites (CS), and Smart Devices (RIS/NCR)
    for t = 1:n_tp
        for c = 1:n_cs
            for r = 1:n_cs
                for s = 1:n_states
                    % Extract rates for the current state
                    direct_rate_DL = rates_per_state.dir(t, c, s); % Direct DL rate
                    direct_rate_UL = rates_per_state.dir(t, c, s); % Direct UL rate (same as DL in current structure)
                    ris_rate_DL = rates_per_state.ris(t, c, r, s); % RIS DL rate
                    ris_rate_UL = rates_per_state.ris(t, c, r, s); % RIS UL rate
                    ncr_rate_DL = rates_per_state.ncr(t, c, r, s); % NCR DL rate
                    ncr_rate_UL = rates_per_state.ncr(t, c, r, s); % NCR UL rate

                    % Check if both DL and UL capacities are unsatisfied for direct links
                    direct_unsatisfied = (direct_rate_DL < C_min_DL || direct_rate_UL < C_min_UL);

                    % Check if both DL and UL capacities are unsatisfied for RIS
                    ris_unsatisfied = (ris_rate_DL < C_min_DL || ris_rate_UL < C_min_UL);

                    % Check if both DL and UL capacities are unsatisfied for NCR
                    ncr_unsatisfied = (ncr_rate_DL < C_min_DL || ncr_rate_UL < C_min_UL);

                    % Combine conditions for unsatisfaction (Direct and RIS/NCR links)
                    if direct_unsatisfied && (ris_unsatisfied || ncr_unsatisfied)
                        P_unsatisfied(t, c, r) = P_unsatisfied(t, c, r) + ...
                            state_probabilities(t, c, r, s); % Add the state probability
                    end
                end
            end
        end
    end
end
