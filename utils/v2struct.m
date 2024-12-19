function [varargout] = v2struct(varargin)
% v2struct has dual functionality in packing & unpacking variables into structures and
%   vice versa, according to the syntax and inputs.
%   Function features:
%     * Pack variables to structure with enhanced field naming
%     * Pack and update variables in existing structure
%     * Unpack variables from structure with enhanced variable naming
%     * Unpack only specific fields in a structure to variables
%     * Unpack without over writing existing variables in work space
%   In addition to the obvious usage, this function could by highly useful for example in
%   working with a function with multiple inputs. Packing variables before the call to
%   the function, and unpacking it in the beginning of the function will make the function
%   call shorter, more readable, and you would not have to worry about arguments order any
%   more. Moreover you could leave the function as it is and you could pass same inputs to
%   multiple functions, each of which will use its designated arguments placed in the
%   structure.
% parse input for field names
if isempty(varargin)
   gotCellArrayOfStrings = false;
   toUnpackRegular = false;
   toUnpackFieldNames = false;
   gotFieldNames = false;
else
   gotCellArrayOfStrings = iscellstr(varargin{end});

   toUnpackRegular = (nargin == 1) && isstruct(varargin{1});
   if toUnpackRegular
      fieldNames = fieldnames(varargin{1})';
      nFields = length(fieldNames);
   end

   gotFieldNames = gotCellArrayOfStrings & any(strcmpi(varargin{end},'fieldNames'));
   if gotFieldNames
      fieldNamesRaw = varargin{end};
      % indices of cells with actual field names, leaving out the index to 'fieldNames' cell.
      indFieldNames = ~strcmpi(fieldNamesRaw,'fieldNames');
      fieldNames = fieldNamesRaw(indFieldNames);
      nFields = length(fieldNames);
   end
   toUnpackFieldNames = (nargin == 2) && isstruct(varargin{1}) && gotFieldNames;
end


% Unpack
if toUnpackRegular || toUnpackFieldNames

   struct = varargin{1};
   assert(isequal(length(struct),1) , 'Single input nust be a scalar structure.');
   CallerWS = evalin('caller','whos'); % arguments in caller work space

   % update fieldNames according to 'avoidOverWrite' flag field.
   if isfield(struct,'avoidOverWrite')
      indFieldNames = ~ismember(fieldNames,{CallerWS(:).name,'avoidOverWrite'});
      fieldNames = fieldNames(indFieldNames);
      nFields = length(fieldNames);
   end

   if toUnpackRegular % Unpack with regular fields order
      if nargout == 0 % assign in caller
         for iField = 1:nFields
            assignin('caller',fieldNames{iField},struct.(fieldNames{iField}));
         end
      else % dump into variables
         for iField = 1:nargout
            varargout{iField} = struct.(fieldNames{iField});
         end
      end

   elseif toUnpackFieldNames % Unpack with fields according to fieldNames
      if nargout == 0 % assign in caller, by comparing fields to fieldNames
         for iField = 1:nFields
            assignin('caller',fieldNames{iField},struct.(fieldNames{iField}));
         end
      else % dump into variables
         assert( isequal(nFields, nargout) , ['Number of output arguments',...
            ' does not match number of field names in cell array']);
         for iField = 1:nFields
            varargout{iField} = struct.(fieldNames{iField});
         end
      end
   end

% Pack
else
   % build cell array of input names
   CallerWS = evalin('caller','whos');
   inputNames = cell(1,nargin);
   for iArgin = 1:nargin
      inputNames{iArgin} = inputname(iArgin);
   end
   nInputs = length(inputNames);

      % look for 'nameOfStruct2Update' variable and get the structure name
   if ~any(strcmpi(inputNames,'nameOfStruct2Update')) % no nameOfStruct2Update
      nameStructArgFound = false;
      validVarargin = varargin;
   else % nameOfStruct2Update found
      nameStructArgFound = true;
      nameStructArgLoc = strcmp(inputNames,'nameOfStruct2Update');
      nameOfStruct2Update = varargin{nameStructArgLoc};
      % valid varargin with just the inputs to pack and fieldNames if exists
      validVarargin = varargin(~strcmpi(inputNames,'nameOfStruct2Update'));
      % valid inputNames with just the inputs name to pack and fieldNames if exists
      inputNames = inputNames(~strcmpi(inputNames,'nameOfStruct2Update'));
      nInputs = length(inputNames);
      % copy structure from caller workspace to enable its updating
      if ismember(nameOfStruct2Update,{CallerWS(:).name}) % verify existance
         S = evalin('caller',nameOfStruct2Update);
      else
         error(['Bad input. Structure named ''',nameOfStruct2Update,...
            ''' was not found in workspace'])
      end
   end

   % when there is no input or the input is only variables and perhaps
   % also nameOfStruct2Update
   if ~gotFieldNames
      % no input, pack all of variables in caller workspace
      if isequal(nInputs, 0)
         for iVar = 1:length(CallerWS)
            S.(CallerWS(iVar).name) = evalin('caller',CallerWS(iVar).name);
         end
         % got input, check input names and pack
      else
         for iInput = 1:nInputs
            if gotCellArrayOfStrings % called with a cell array of strings
               errMsg = sprintf(['Bad input in cell array of strings.'...
                           '\nIf you want to pack (or unpack) using this cell array as'...
                           ' designated names'...
                           '\nof the structure''s fields, add a cell with the string'...
                           ' ''fieldNames'' to it.']);
            else
               errMsg = sprintf(['Bad input in argument no. ', int2str(iArgin),...
                                 ' - explicit argument.\n'...
                          'Explicit arguments can only be called along with a matching'...
                          '\n''fieldNames'' cell array of strings.']);
            end
            assert( ~isempty(inputNames{iInput}), errMsg);
            S.(inputNames{iInput}) = validVarargin{iInput};
         end

         % issue warning for possible wrong usage when packing with an input of cell array of
         % strings as the last input without it containing the string 'fieldNames'.
         if gotCellArrayOfStrings
            name = inputNames{end};
            % input contains structure and a cell array of strings
            if (nargin == 2) && isstruct(varargin{1})
               msgStr = [inputNames{1},''' and ''',inputNames{2},''' were'];
               % input contains any arguments with an implicit cell array of strings
            else
               msgStr = [name, ''' was'];
            end
            warnMsg = ['V2STRUCT - ''%s packed in the structure.'...
               '\nTo avoid this warning do not put ''%s'' as last v2struct input.'...
               '\nIf you want to pack (or unpack) using ''%s'' as designated names'...
               ' of the'...
               '\nstructure''s fields, add a cell with the string ''fieldNames'' to'...
               ' ''%s''.'];
            fprintf('\n')
            warning('MATLAB:V2STRUCT:cellArrayOfStringNotFieldNames',warnMsg,msgStr,...
                     name,name,name)
         end
      end
   % fieldNames cell array exists in input
   elseif gotFieldNames
      nVarToPack = length(varargin)-1-double(nameStructArgFound);
      if nVarToPack == 0 % no variables to pack
         for iField = 1:nFields
            S.(fieldNames{iField}) = evalin('caller',fieldNames{iField});
         end

         % else - variables to pack exist
         % check for correct number of fields vs. variables to pack
      elseif ~isequal(nFields,nVarToPack)
         error(['Bad input. Number of strings in fieldNames does not match',...
                'number of input arguments for packing.'])
      else
         for iField = 1:nFields
            S.(fieldNames{iField}) = validVarargin{iField};
         end
      end

   end % if ~gotFieldNames

if nargout == 0
   assignin( 'caller', 'Sv2struct',S );
else
   varargout{1} = S;
end

end % if nargin
end

