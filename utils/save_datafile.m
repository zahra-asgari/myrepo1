%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPL datafile creation
%
% Author: Eugenio Moro, Politecnico di Milano
% Date:   Feb. 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = save_datafile(instance,filename)
% save_datafile saves the content of the struct data to the datafile
% filename
% data structure: fieldname is converted in the parameter name
%                 fieldvalue is converted in the parameter value

%%
%open destination file
fid = fopen(filename, 'w');

fields = fieldnames(instance);
for f=1:numel(fields)
    
    %check if logical, fprintf has problems with it -> cast it to int8
    if islogical(instance.(fields{f}))
        instance.(fields{f}) = int8(instance.(fields{f}));
    end
    
    if ischar(instance.(fields{f}))
        %print string parameter
        fprintf(fid, '%s = "%s";\n', fields{f}, instance.(fields{f}));
    elseif isscalar(instance.(fields{f}))
        %print variable name
        fprintf(fid, '%s = ', fields{f});
        fprintf(fid, '%.4d;\n', instance.(fields{f}));
    elseif isvector(instance.(fields{f})) && isnumeric(instance.(fields{f}))
        %print variable name
        fprintf(fid, '%s = ', fields{f});
        print_row(instance.(fields{f}),fid);
        fprintf(fid, ';\n');
    elseif ismatrix(instance.(fields{f})) && isnumeric(instance.(fields{f}))
        %print variable name
        fprintf(fid, '%s = ', fields{f});
        print_matrix(instance.(fields{f}),fid)
        fprintf(fid, ';\n');
    elseif ndims(instance.(fields{f})) == 3 && isnumeric(instance.(fields{f}))
        %print variable name
        fprintf(fid, '%s = ', fields{f});
        %open outer 3d matrix
        fprintf(fid, '[');
        for outer_dim = 1:size(instance.(fields{f}),1)
            %open 2d inner matrix
            %fprintf(fid, '[');
            %print inner matrix
            print_matrix(squeeze(instance.(fields{f})(outer_dim,:,:)),fid);
            %close inner matrix
            fprintf(fid, ',\n');
        end
        %close 3d outer matrix
        fprintf(fid, '];\n');
    elseif ndims(instance.(fields{f})) == 4 && isnumeric(instance.(fields{f}))
        %print variable name
        fprintf(fid, '%s = ', fields{f});
        %open outer 4d matrix
        fprintf(fid, '[');
        for frt_dim = 1:size(instance.(fields{f}),1)
            %open outer 3d matrix
            fprintf(fid, '[');
            for trd_dim = 1:size(instance.(fields{f}),2)
                %open 2d inner matrix
                %fprintf(fid, '[');
                %print inner matrix
                print_matrix(squeeze(instance.(fields{f})(frt_dim,trd_dim,:,:)),fid);
                %close inner matrix
                fprintf(fid, ',\n');
            end
            %close 3d outer matrix
            fprintf(fid, '],\n');
        end
        %close 4d outer matix
        fprintf(fid, '];\n');
    end
    
    
end
end

function [] = print_matrix(matrix,fid)
%open matrix
fprintf(fid, '[');
for r=1:size(matrix,1)-1
    print_row(squeeze(matrix(r,:)), fid);
    fprintf(fid, ',\n');
end
%close_matrix
print_row(matrix(end,:),fid);
fprintf(fid, ']');
end

function [] = print_row(row, fid)
%open row
fprintf(fid, '[');
fprintf(fid, ' %.4d,', row(1:end-1));
%close row
fprintf(fid, ' %.4d]', row(end));
end




