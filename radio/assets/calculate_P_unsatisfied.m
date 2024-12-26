function P_unsatisfied = calculate_P_unsatisfied(state_probabilities, state_rates, C_min_DL, C_min_UL)
    % state_probabilities: (n_tp, n_cs, n_cs, 16) probabilities for each blockage state
    % state_rates: structure with fields:
    %   - dir_DL: direct link DL rates (n_tp, n_cs, 16)
    %   - dir_UL: direct link UL rates (n_tp, n_cs, 16)
    %   - ris_DL: RIS link DL rates (n_tp, n_cs, n_cs, 16)
    %   - ris_UL: RIS link UL rates (n_tp, n_cs, n_cs, 16)
    %   - ncr_DL: NCR link DL rates (n_tp, n_cs, n_cs, 16)
    %   - ncr_UL: NCR link UL rates (n_tp, n_cs, n_cs, 16)
    % C_min_DL, C_min_UL: minimum required DL/UL capacities

    % Dimensions
    [n_tp, n_cs, ~, n_states] = size(state_probabilities);

    % Initialize P_unsatisfied
    P_unsatisfied = zeros(n_tp, n_cs, n_cs);

    % Iterate over test points, candidate sites, and blockage states
    for t = 1:n_tp
        for c = 1:n_cs
            for r = 1:n_cs
                % Iterate over blockage states
                for s = 1:n_states
                    % Capacity checks for the current blockage state
                    direct_unsatisfied = ...
                        state_rates.dir_DL(t, c, s) < C_min_DL || ...
                        state_rates.dir_UL(t, c, s) < C_min_UL;

                    ris_unsatisfied = ...
                        state_rates.ris_DL(t, c, r, s) < C_min_DL || ...
                        state_rates.ris_UL(t, c, r, s) < C_min_UL;

                    ncr_unsatisfied = ...
                        state_rates.ncr_DL(t, c, r, s) < C_min_DL || ...
                        state_rates.ncr_UL(t, c, r, s) < C_min_UL;

                    % Combine conditions: unsatisfied if all links fail
                    if direct_unsatisfied && (ris_unsatisfied && ncr_unsatisfied)
                        % Accumulate state probability
                        P_unsatisfied(t, c, r) = P_unsatisfied(t, c, r) + ...
                            state_probabilities(t, c, r, s);
                    end
                end
            end
        end
    end
end
