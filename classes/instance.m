classdef (Abstract) instance < handle & debug_methods
    %INSTANCE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        instance_struct;            % structure containing opl data
        workspace_struct;           % structure containing the workspace variables needed to create the opl data
        solution_struct;             % scructure containing the optimal variables after solution

        scenario;                   % contains all the simulation parameters
        rng_seed;

        instance_folder;            % folder where the instance should be saved
        dataname;                   % name of the saved instance datafile

        model_folder;
        model_name;
        model_string;

        is_generated = false;
        is_solved = false;

        opl_status;
        opl_log;

        site_cache;
        site_cache_path;
        site_cache_found=false;
        site_cache_var_list;

        radio_cache;
        radio_cache_path;
        radio_cache_found=false;
        radio_cache_var_list;

        % these come from global options
        PLOT_SITE;                  % if true then the site will be plotted as soon as it is generated
        USE_CACHING;                % if true caching is enabled
        VERBOSE;                    % if true print debug messages
        FIGURE_EXPORT_STYLE;
        CACHE_FOLDER;
    end

    methods (Abstract)
        [instance_struct, workspace_struct] = generate_inner(obj);
        plot_solution(obj);
        [var_list] = get_site_cache_var_list(obj);
        [var_list] = get_radio_cache_var_list(obj);
    end

    methods
        function obj = instance(scenario,global_options,instance_folder,dataname,model_folder,model_name,rng_seed)
            % CONSTRUCTOR

            % path to functions
            %addpath('simulation_scenarios','utils','gen_functions');

            % warn if scenario contains vectorial parameters
            if scenario.contains_vector
                warning('Scenario contains vectorial parameters. Set all parameters to scalar to avoid undefined behaviors');
            end

            % set properties as input
            obj.scenario = scenario;
            obj.instance_folder = instance_folder;
            obj.dataname = dataname;
            obj.rng_seed = rng_seed;

            obj.model_folder = model_folder;
            obj.model_name = model_name;

            % set global options
            obj.PLOT_SITE = global_options.PLOT_SITE;
            obj.USE_CACHING = global_options.USE_CACHING;
            obj.VERBOSE = global_options.VERBOSE;
            obj.FIGURE_EXPORT_STYLE = global_options.FIGURE_EXPORT_STYLE;
            obj.CACHE_FOLDER = global_options.CACHE_FOLDER;
            % set rng_seed into scenario such that cache search is based
            % also on rng seed
            obj.scenario.rng_seed = rng_seed;

            % set cache variables list
            obj.site_cache_var_list = obj.get_site_cache_var_list();
            obj.radio_cache_var_list = obj.get_radio_cache_var_list();

        end

        function obj = save_data(obj)
            if ~obj.is_generated
                obj.generate()
            end
            %unpack workspace and save
            %obj.debug_msg(['Saving workspace as ' strcat(obj.instance_folder, obj.dataname)],obj.VERBOSE);
            %ws = obj.workspace_struct;
            %save(strcat(obj.instance_folder, obj.dataname),'ws');
            obj.debug_msg(['Generating OPL dat file and saving it in ' obj.instance_folder],obj.VERBOSE);
            %generate and save opl dat file
            save_datafile(obj.instance_struct, strcat(obj.instance_folder, [obj.dataname '.dat']));
            obj.debug_msg('Done saving',obj.VERBOSE);
        end

        function [] = open_cache(obj)

            % look for site cache
            site_cache_id = DataHash([DataHash(obj.scenario.site) num2str(obj.rng_seed)]); % hash is salted with rng_seed, since the site data is generated randomly
            obj.site_cache_path = [obj.CACHE_FOLDER site_cache_id];

            if isfile([obj.site_cache_path '.mat']) % check if site cache exists
                % check if it contains all the required variables
                obj.site_cache_found = true;
                cache_content = who('-file',obj.site_cache_path);
                for var=1:numel(obj.site_cache_var_list)
                    if ~ismember(obj.site_cache_var_list{var},cache_content)
                        obj.site_cache_found = false;
                        break;
                    end
                end
            end
            if obj.site_cache_found
                obj.site_cache = load(obj.site_cache_path);
                obj.debug_msg('Site cache found and loaded',obj.VERBOSE);
            else
                obj.debug_msg('Site cache not found',obj.VERBOSE);
            end

            % look for radio cache
            radio_cache_id = DataHash([DataHash(obj.scenario.radio) site_cache_id]); % hash is salted with site hash, since radio data is generated accordingly to the site
            obj.radio_cache_path = [obj.CACHE_FOLDER radio_cache_id];

            if isfile([obj.radio_cache_path '.mat']) && obj.site_cache_found % we don't load radio cache if the site cache is not found
                obj.radio_cache_found = true;
                cache_content = who('-file',obj.radio_cache_path);
                for var=1:numel(obj.radio_cache_var_list)
                    if ~ismember(obj.radio_cache_var_list{var},cache_content)
                        obj.radio_cache_found = false;
                        break;
                    end
                end
            end
            if obj.radio_cache_found
                obj.radio_cache = load(obj.radio_cache_path);
                obj.debug_msg('Radio cache found and loaded',obj.VERBOSE);
            else
                obj.debug_msg('Radio cache not found',obj.VERBOSE);
            end
        end

        function [] = save_cache(obj)
            % use this method to save or update the cache files according
            % to the variable list. We also save the scenario and the
            % rng_seed
            ws=obj.workspace_struct;
            scenario = obj.scenario;
            rng_seed = obj.rng_seed;
            if ~obj.site_cache_found
                obj.debug_msg('Saving site cache...',obj.VERBOSE);
                %varnames = strcat('obj.workspace_struct.',obj.site_cache_var_list);
                save(obj.site_cache_path,'-struct','ws',obj.site_cache_var_list{:});
                save(obj.site_cache_path,'-append','scenario','rng_seed');
            end
            if ~obj.radio_cache_found
                obj.debug_msg('Saving radio cache...',obj.VERBOSE);
                %varnames = strcat('obj.workspace_struct.',obj.radio_cache_var_list);
                save(obj.radio_cache_path,'-struct','ws',obj.radio_cache_var_list{:});
                save(obj.radio_cache_path,'-append','scenario','rng_seed');
            end
        end

        function [] = generate(obj)
            if ~obj.is_generated
                if obj.USE_CACHING
                    obj.open_cache();
                end
                obj.debug_msg('Generating instance structure...',obj.VERBOSE);
                [obj.instance_struct, obj.workspace_struct]...
                    = obj.generate_inner();
                obj.is_generated = true;
                obj.debug_msg('Instance structure generated',obj.VERBOSE);
                if obj.USE_CACHING
                    obj.save_cache();
                end
            else
                obj.debug_msg('Instance structure was already generated',obj.VERBOSE);
            end
        end

        function [model_string] = build_save_model(obj)
            %obj.debug_msg('Building and saving the model file');
            full_model_path = [pwd '/' obj.model_folder];
            model_string = buildModel(obj.model_name, full_model_path);
            obj.model_string = model_string;
        end

        function [solution_struct] = solve(obj)
            solution_struct = [];
            obj.generate();
            obj.save_data();
            obj.build_save_model();
            [obj.opl_status, obj.opl_log] = obj.run_opl();

            % check if solution file exists, note that the solution
            % variables are saved in a .m file whose name is [model_name '_'
            % dataname]
            %obj.debug_msg([pwd '/' obj.model_folder '../solutions/' obj.model_name obj.dataname '.m'], obj.VERBOSE);
            if isfile([pwd '/' obj.model_folder '../solutions/' obj.model_name '_' obj.dataname '.m'])
                obj.is_solved = true;
                obj.solution_struct = load_solution(obj);
                obj.debug_msg('Solution found and loaded', obj.VERBOSE);
            else
                obj.debug_msg('Instance could not be solved, check instance.opl_log', obj.VERBOSE);
            end
        end

    end

    methods (Access=private)
        function [opl_status, opl_out] = run_opl(obj)
            obj.debug_msg('Running opl',obj.VERBOSE)
            full_instance_path = [pwd '/' obj.instance_folder obj.dataname '.dat'];
            %opl_command = ['./utils/run_oplrun.sh',' ', [pwd '/' obj.model_folder obj.model_name '.mod'],' ', full_instance_path];
            opl_command = ['sudo ./utils/run_oplrun.sh',' ', '/home/paolo/projects/RIS-Planning-Instance-Generator/models/iab_ris_fixedDonor_fakeRis_blockageModel_sumMCS.mod',' ', full_instance_path];
            %opl_command = ['./utils/run_oplrun.sh',' ', '/Users/eugenio/no_indexing/RIS_planning_generator/RIS_Planning_Instance_Generator/models/singleris_maxavgrate.mod',' ', full_instance_path];
            [opl_status, opl_out]=system(opl_command);
        end
        function sol_struct = load_solution(obj)
            run([pwd '/' obj.model_folder '/solutions/' obj.model_name '_' obj.dataname '.m']);
            sol_struct = v2struct();
        end
    end

end

