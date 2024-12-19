load('Mat_files_solutions/buildings_test/blockage_probs/states_sumextra.mat')
sol_dir_extra = all_sol_dir{end};
sol_src_extra = all_sol_src{end};
load('Mat_files_solutions/buildings_test/blockage_probs/states_sumrate.mat')
sol_dir_rate = all_sol_dir{end};
sol_src_rate = all_sol_src{end};

bar(sort(sol_src_extra(16,:)));
