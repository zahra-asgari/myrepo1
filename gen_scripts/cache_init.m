%% check in databank if a  instance of this particular scenario was already generated and saved in the cache
% we do this by using md5 hashes of the entire struct, since the name is
% not relaible enough

scenario_hash = DataHash(scenario);
cache_folder = 'cache/instances/';
cache_path = strcat(cache_folder,scenario_hash);
cache_found = isfile([cache_path '.mat']);

if ~cache_found
    % initialize cache
    save(cache_path, 'name');
    %disp('cache not found');
end