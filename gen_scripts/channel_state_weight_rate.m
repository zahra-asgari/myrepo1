if scenario.singleRis
    %here for each cs-cs-tp triplet we compute the expected rate (i.e.
    %the expected rate considering the probabilitites of los nlos outage)
    %and the deterministic rates when all channels a re los and when only
    %cs_tp is in outage
    
    expected_rate_wris  = zeros(n_tp, n_cs, n_cs);
    expected_rate_woris = zeros(n_tp, n_cs);
    
    los_rate = zeros(n_tp, n_cs, n_cs);
    outage_rate = zeros(n_tp, n_cs, n_cs);
    
    STATE_LOS   = 0;
    STATE_NLOS  = 1;
    STATE_OUT   = 2;
    
    states      = permn([STATE_LOS STATE_NLOS STATE_OUT], 3);
    %compute state mask
    los_mask    = (states == STATE_LOS);
    nlos_mask   = (states == STATE_NLOS);
    
    for t=1:n_tp
        for d=1:n_cs
            d_direct = cs_tp_distance_matrix(d,t);
            for r=1:n_cs
                if d==r
                    expected_rate_wris(t,d,r) = nan;
                    continue;
                end
                d_inc       = cs_cs_distance_matrix(d,r);
                d_ref       = cs_tp_distance_matrix(r,t);
                
                %sum of masks, each of one multiplied by pathloss, gives the
                %pathloss of all 3 channels in all states. Note that these
                %masks are orthogonal. Outage mask needs not to be multiplied
                %and added since all the outage channel pathloss are set to
                %zero by the other 2 masks
                states_pathloss = ...
                    los_mask.*...
                    repmat([pathloss(d_direct, 'los', 'linear') pathloss(d_inc, 'los', 'linear') pathloss(d_ref, 'los', 'linear')],size(states,1), 1)+...
                    nlos_mask.*...
                    repmat([pathloss(d_direct, 'nlos', 'linear') pathloss(d_inc, 'nlos', 'linear') pathloss(d_ref, 'nlos', 'linear')],size(states,1), 1);
                
                %now for each state we compute the rx power
                states_rxpwr = states_pathloss(:,1).*n_antennas+... %phi
                    sqrt(states_pathloss(:,1)).*sqrt(states_pathloss(:,2)).*sqrt(states_pathloss(:,3)).*sqrt(pi)./2.*beta+...%theta
                    states_pathloss(:,2).*states_pathloss(:,3).*alpha;
                states_rxpwr = states_rxpwr.*ptx_lin;
                
                %now the rate selecting the best available mcs
                states_rate = zeros(numel(states_rxpwr),1);
                pt = [pwr_thr; inf]; %this trick makes the following loop work
                for p=1:numel(pt)-1
                    states_rate = states_rate+mcs_rate(p).*(states_rxpwr >= repmat(pt(p), numel(states_rxpwr),1) & states_rxpwr < repmat(pt(p+1), numel(states_rxpwr),1));
                end
                
                %compute the state probabilities using masks
                prob_matrix = channel_state_prob([d_direct d_inc d_ref]);
                
                states_prob = prob_matrix(states(:,1)+1,1).*... direct link
                    prob_matrix(states(:,2)+1,2).*... incident link
                    prob_matrix(states(:,3)+1,3); %reflected link
                assert(abs(sum(states_prob) -1) < 0.05, 'State probabilities sum not equal 1. In generateInstance');
                
                expected_rate_wris(t,d,r) = sum(states_prob.*states_rate);
                
                %now we also compute the deterministic rates when every channel is los
                %and when only the cs-tp channel is nlos
                los_rate(t,d,r)    = states_rate(1); %state 1 is where all is los
                outage_rate(t,d,r) = states_rate(10); %state 10 is where ris is los and bs is outage
                
            end
            %now we also compute the expected rate without any RIS
            expected_rate_woris(t,d) = ...
                sum(states_prob(1:9)).*max(mcs_rate.*(phi_LOS(d,t) >= pwr_thr))+... los
                sum(states_prob(10:18)).*max(mcs_rate.*(phi_NLOS(d,t) >= pwr_thr)); %nlos
        end
    end
    
    %compute the dirrerential rate
    differential_rate = expected_rate_wris - repmat(expected_rate_woris,1,1,n_cs);
    %delete very small negative differential rates
    assert(min(differential_rate(:)) > -1e-10, 'Too large negative differental rates. In generateInstance');
    differential_rate(differential_rate < 0) = 0;
    %substitute nan since in cplex these values will never be used (i am not
    %sure cplex understands nan)
    differential_rate(isnan(differential_rate)) = 0;
    %     disp(['Max rate gain: ' num2str(max(differential_rate(:)))]);
    %     disp(['Mean rate gain: ' num2str(mean(differential_rate(:)))]);
    
end