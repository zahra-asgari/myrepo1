function [parameters] = getBaseParameters()
%GETPARAMETERS This function returns a string containing the opl definition
%of the parameters
% $Author: Eugenio Moro $	$Date: 2020/12/10 10:19:59 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020

parameters = fileread('model_builder/assets/parameters/base_parameters.txt');

end
