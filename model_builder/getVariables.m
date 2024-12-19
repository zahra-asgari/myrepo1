function [variables] = getVariables(varargin)
%GETPARAMETERS This function returns a string containing the opl definition
%of the parameters
% $Author: Eugenio Moro $	$Date: 2020/12/10 10:19:59 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020

if numel(varargin) == 0
    variables = fileread('model_builder/assets/variables/variables.txt');
else
    variables = [];
    for i=1:numel(varargin{1})
        variables = [variables fileread(['model_builder/assets/variables/' cell2mat(varargin{1}(i)) '.txt']) newline];
    end
end
