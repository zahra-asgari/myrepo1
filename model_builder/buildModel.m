function [model_string] = buildModel(template_name, save_path,threads)
%BUILDMODEL This function builds and saves an optimization model given a template
%

% $Author: Eugenio Moro $	$Date: 2020/12/10 15:58:10 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020

addpath(genpath('model_builder/'));
run(template_name);

% preamble
if nargin < 3
    % threads are not specified
    model_string = getPreamble(opti_template.name,opti_template.cplex);
else 
    % use the specified number of threads
    model_string = getPreamble(opti_template.name,opti_template.cplex,threads);
end

%parameters
%model_string = [model_string newline getBaseParameters() newline];
for p=1:numel(opti_template.parameters_list)
    model_string = [model_string fileread(['assets/parameters/' cell2mat(opti_template.parameters_list(p)) '.txt']) newline];
end

%variables
if isfield(opti_template,'variables_list')
    model_string = [model_string getVariables(opti_template.variables_list) newline];
else
    model_string = [model_string getVariables() newline];
end

%objective
model_string = [model_string fileread(['assets/objectives/' opti_template.objective '.txt']) newline ];

%s.t.
model_string = [model_string 'subject to{' newline];

%constraints
for c=1:numel(opti_template.constraint_list)
    model_string = [model_string fileread([cell2mat(opti_template.constraint_list(c)) '.txt']) newline];
end

model_string = [model_string '}' newline];

%post processing
if isfield(opti_template,'preprocessing_list')
    model_string = [model_string fileread(['assets/postproc_scripts/' opti_template.preprocessing_list{1} '.txt'])];
else
    model_string = [model_string fileread('assets/postproc_scripts/full_post_processing.txt')];
end

%save
fid = fopen([save_path opti_template.name '.mod'], 'w');
fprintf(fid, '%s', model_string);
fclose(fid);

end
