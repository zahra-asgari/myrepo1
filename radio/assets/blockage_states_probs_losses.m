function [final_probs, direct_losses, reflected_losses] = blockage_states_probs_losses(sbz_d,sbz_r,n_sbz_r,obst_d,obst_r,sbz_loss,cache_found, cache_path)
%%This function computes the final state probabilities. This states are
%%determined by the blockage events and are in total 16, the overall
%%combination of 4 events: direct link in sbz, reflected link in sbz,
%%direct link in obstacle blockage, reflected link in obstacle blockage.
%%The order is obst_d (1), obst_r (2), sbz_d (4), sbz_r (8) in binary
%%notation. For example 9=1001 is the state in which the direct link is
%%blocked by a moving obstacle (1) and the reflected link is in the self
%%blockage zone. 0 = (0000) is all good, 15 (1111) is every possible
%%blockage event at once.

if nargin ==6
    cache_found = false;
    save_to_cache = false;
elseif nargin <6
    error('Not enough input arguments');
else
    save_to_cache = true;
end

if cache_found
    load(cache_path, 'final_probs','additive_losses');
else


    final_probs = zeros (1,16);
    direct_losses = zeros (1,16);
    reflected_losses = zeros (1,16);

    for state=0:15

       state_bin = dec2bin(state,4); %4-bit state representation

       if state_bin(4) == '1'

           four = obst_d.PB;
           four_loss = obst_d.Loss;

       elseif state_bin(4) == '0'

           four = 1 - obst_d.PB;
           four_loss = 0;

       end

       if state_bin(3) == '1'

           three = obst_r.PB;
           three_loss = obst_r.Loss;

       elseif state_bin(3) == '0'

           three = 1 -obst_r.PB;
           three_loss = 0;

       end

       if state_bin(2) == '1'

           two = sbz_d;
           two_loss = sbz_loss;

           if state_bin(1) == '1'

               one = sbz_r;
               one_loss = sbz_loss;

           elseif state_bin(1) == '0'

               one = 1 - sbz_r;
               one_loss = 0;

           end

       elseif state_bin(2) == '0'

           two = 1 -sbz_d;
           two_loss = 0;

           if state_bin(1) == '1'

               one = 1 - n_sbz_r;
               one_loss = sbz_loss;

           elseif state_bin(1) == '0'

               one = n_sbz_r;
               one_loss = 0;

           end

       end

       final_probs(1,state + 1) = one*two*three*four;
       direct_losses(1,state + 1) = two_loss + four_loss;
       reflected_losses(1,state + 1) = one_loss + three_loss;
    end
    if save_to_cache
        save(cache_path, 'final_probs', 'direct_losses', 'reflected_losses',  '-append');
    end

end
end