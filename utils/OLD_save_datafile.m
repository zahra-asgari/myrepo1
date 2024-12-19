%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPL datafile creation
%
% Author: Francesco Devoti francesco.devoti@polimi.it
% Date:   November 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function save_datafile(data,filename, varargin)
% save_datafile saves the content of the struct data to the datafile
% filename
% data structure: fieldname is converted in the parameter name
%                 fieldvalue is converted in the parameter value

% initialization
string_to_file = char.empty(1,0);
parameters_name = fieldnames(data);
parameters_content = struct2cell(data);
N_parameters = numel(parameters_name);

for par = 1:N_parameters
    % Getting the specific parameter
    par_name = parameters_name{par};
    par_content = parameters_content{par};
    % write parameter name
    string_to_file = cat(2,string_to_file,par_name,' = ');
    
    if isstruct(par_content) && numel(par_content) > 1
        par_content_tmp = par_content;
        par_content = cell(size(par_content));
        for i = 1:numel(par_content)
            par_content{i} = par_content_tmp(i);
        end
    end
    
    is_array = false();
    if numel(varargin)
    for i = 1:numel(varargin{1})
        if strcmp(varargin{1}{i}, par_name)
            is_array = true();
            break
        end
    end
    end
    
     is_matrix = false();
    if numel(varargin) >=2
    for i = 1:numel(varargin{2})
        if strcmp(varargin{2}{i}, par_name)
            is_matrix = true();
            break
        end
    end
    end
    
    string_to_file = write_element(string_to_file, par_content, numel(par_name)+3, is_array, is_matrix);
    
    % close the parameter
    string_to_file=cat(2,string_to_file,[';',newline,newline]);
end
% write datafile
fid = fopen(filename, 'w');
fprintf(fid, string_to_file);

fclose(fid);

end


function [string_to_file] = write_element(string_to_file, par_content, varargin)

if ischar(par_content)
    if numel(varargin)
    if ~varargin{2}
    % a string
    string_to_file=cat(2,string_to_file,'"',par_content,'"');
    return
    end
    end
end

if iscell(par_content)
    % a set
    string_to_file=cat(2,string_to_file,'{',newline);
    if length(par_content) == 1
        tmp_content = par_content{1};
        par_content = cell(size(tmp_content));
        for i=1:length(par_content)
            par_content{i} = tmp_content(i);
        end
    end
    for i=1:length(par_content)
        [string_to_file] = write_element(string_to_file, par_content{i});
        if i < numel(par_content)
            string_to_file =  cat(2, string_to_file, ', ');
        end
    end
    string_to_file=cat(2,string_to_file, newline, '}');
    return
end

if isstruct(par_content)
    % a tuple
    string_to_file=cat(2,string_to_file,'<');
    fields = fieldnames(par_content);
    for i=1:numel(fields)
        [string_to_file] = write_element(string_to_file, par_content.(fields{i}));
        if i < numel(fields)
            string_to_file =  cat(2, string_to_file, ', ');
        end
    end
    string_to_file=cat(2,string_to_file,'>');
    return
end


if numel(par_content) == 0
    % an empty array
    string_to_file =  cat(2, string_to_file, '[]');
    return
end

if numel(par_content) == 1
    % a scalar
    if numel(varargin) < 2
        is_array = 0;
    else
        is_array = varargin{2};
    end
    if is_array
        string_to_file =  cat(2, string_to_file,'[', num2str(par_content),']');        
        return
    end
    string_to_file =  cat(2, string_to_file, num2str(par_content));
    return
end

if numel(par_content) > 1 && numel(size(par_content)) == 2 && any(size(par_content) == 1)
    % an array
    if numel(varargin) < 3
        is_matrix = 0;
    else
        is_matrix = varargin{3};
    end
    if is_matrix
        string_to_file =  cat(2, string_to_file,'[');
    end
    
    string_to_file =  cat(2, string_to_file, '[');
    for i=1:numel(par_content)
        [string_to_file] = write_element(string_to_file, par_content(i));
        if i < numel(par_content)
            string_to_file =  cat(2, string_to_file, ', ');
        end
    end
    string_to_file =  cat(2, string_to_file, ']');
    if is_matrix
        string_to_file =  cat(2, string_to_file,']');
    end
    return
end

if numel(size(par_content)) >= 2
    % a matrix
    string_to_file =  cat(2, string_to_file, '[');
    tmp_size = size(par_content);
    for i=1:tmp_size(1)
        tmp_content = zeros([tmp_size(2:end),1]);
        tmp_content(:) = par_content(i,:);
        [string_to_file] = write_element(string_to_file, tmp_content, varargin{1} + 1);
        if i < tmp_size(1)
            string_to_file =  cat(2, string_to_file, ',', newline, repmat(' ', [1, varargin{1} + 1]));
        end
    end
    string_to_file =  cat(2, string_to_file, ']');
    return
end

end

