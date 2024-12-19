                %% unpack scenario into workspace
                v2struct(obj.scenario);
                clear size;
                rng(obj.rng_seed);