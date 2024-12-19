function [old_scenario] = convert_scenario_new2old(new_scenario)
%CONVERT_SCENARIO_NEW2OLD This function converts the new scenario object to
%the old scenario object, to be used for retrocompatibility if needed.
%Author: Eugenio Moro

f = fieldnames(new_scenario.site);
for i = 1:length(f)
    old_scenario.(f{i}) = new_scenario.site.(f{i});
end

f = fieldnames(new_scenario.site);
for i = 1:length(f)
    old_scenario.(f{i}) = new_scenario.site.(f{i});
end

f = fieldnames(new_scenario.radio);
for i = 1:length(f)
    old_scenario.(f{i}) = new_scenario.radio.(f{i});
end

f = fieldnames(new_scenario.sim);
for i = 1:length(f)
    old_scenario.(f{i}) = new_scenario.sim.(f{i});
end

old_scenario.name = new_scenario.name;
old_scenario.contains_vector = new_scenario.contains_vector;
if isfield(new_scenario,'size')
    old_scenario.size = new_scenario.size;
end
end

