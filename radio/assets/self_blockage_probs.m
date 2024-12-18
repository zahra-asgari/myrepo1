function [rsbz_probs, r_n_sbz_probs, d_sbz_prob] = self_blockage_probs(min_angles,cache_found, cache_path)
%%calculate the two probabilities of having the reflected link inside the
%%self_blockage zone conditioned on the direct link being in the SBZ (rsbz_probs), and
%%the reflected link being outside the SBZ conditioned on the direct link
%%being outside the SBZ (r_n_sbz_probs)


if nargin ==1
    cache_found = false;
    save_to_cache = false;
elseif nargin <1
    error('Not enough input arguments');
else
    save_to_cache = true;
end

if cache_found
    load(cache_path, 'rsbz_probs', 'r_n_sbz_probs');
else

    rsbz_probs = zeros(size(min_angles));
    r_n_sbz_probs = rsbz_probs;
    n_tp = size(min_angles,1);
    n_cs = size(min_angles,2);

    portrait_angle = 120;
    portrait_prob = 0.5;
    landscape_angle = 160;
    landscape_prob = 1 - portrait_prob;
    d_sbz_prob = portrait_prob*(portrait_angle/360) + landscape_prob*(landscape_angle/360);


    for t=1:n_tp
        for c=1:n_cs
            if (c == 1)
                continue;
            end
            for r=1:n_cs
                if (c~=r && r~=1)
                    rsbz_probs(t,c,r) = portrait_prob * (max(((portrait_angle - min_angles(t,c,r))/portrait_angle),0))...
                                      + landscape_prob * (max(((landscape_angle - min_angles(t,c,r))/landscape_angle),0));
                    r_n_sbz_probs(t,c,r) = portrait_prob * (((360 - portrait_angle) - min_angles(t,c,r))/(360 - portrait_angle))...
                                      + landscape_prob * (((360 - landscape_angle) - min_angles(t,c,r))/(360 - landscape_angle));
                                  
                else
                    
                    rsbz_probs(t,c,r) = 0;
                    r_n_sbz_probs(t,c,r) = 1;
                                  
                end

    %how to manage the probabilities of the fake RIS? I have to find it in the
    %matrix. Better management, it's not clear. In any case
    %rsbz_probs(t,c,fake_ris) = 0 and r_n_sbz_probs(t,c,fake_ris) = 1 for any t
    %and c.

            end
        end
    end
    if save_to_cache
        save(cache_path, 'rsbz_probs', 'r_n_sbz_probs', 'd_sbz_prob', '-append');
    end
end
end
