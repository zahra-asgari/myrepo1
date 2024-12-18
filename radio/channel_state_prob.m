function [probs] = channel_state_prob(length)
%CHANNEL_STATE_PROB This function returns the probability of LOS, NLOS, and
%outage for a given distance
% Based on akdeniz2014 for a carrier frequency of 28GHz
one_over_a_out = 30;
b_out = 5.2;
one_over_a_los = 67.1;


p_out = 1-exp(-(...
    1/one_over_a_out).*length+b_out);

p_out( p_out <= 0)=0;
p_los = (1-p_out).*exp(-(1/one_over_a_los).*length);
p_nlos = 1-p_out-p_los;

%probs = [p_los; p_nlos; p_out];
probs.p_los = p_los;
probs.p_nlos = p_nlos;
probs.p_out = p_out;
end

