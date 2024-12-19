scenario_struct = hexagonal_area_iab_ris_fixedDonor_fakeRis_blockageModel();
for sol=1:30
            
            site_cache_id = DataHash([DataHash(scenario_struct.site) num2str(sol)]); % hash is salted with rng_seed, since the site data is generated randomly
            radio_cache_id = DataHash([DataHash(scenario_struct.radio) site_cache_id]);
            site_cache_path = ['cache/' site_cache_id '.mat'];
            radio_cache_path = ['cache/' radio_cache_id '.mat'];
            if isfile(site_cache_path)
                load(site_cache_path,...
                    'cs_tp_distance_matrix','smallest_angles','n_cs','n_tp','scenario');
            else
                disp("Site cache not found!!")
                continue;
                
            end
            if isfile(radio_cache_path)
                load(radio_cache_path,...
                    'bh_rates','weighted_rates','ris_rates','direct_rates','reflected_rates','state_probs','ris_better_mask','ris_p_mask');
                ris_fullrates = sum(reflected_rates.*state_probs,4);
            else
                disp("Site cache not found!!")
                continue;
                
            end
            disp([sum(ris_p_mask(:,:,1),'all') sol]);
end