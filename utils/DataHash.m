function H = DataHash(Data)
Engine = java.security.MessageDigest.getInstance('MD5');
H = CoreHash(Data, Engine);
H = sprintf('%.2x', H);   % To hex string
function H = CoreHash(Data, Engine)
% Consider the type of empty arrays:
S = [class(Data), sprintf('%d ', size(Data))];
Engine.update(typecast(uint16(S(:)), 'uint8'));
H = double(typecast(Engine.digest, 'uint8'));
if isa(Data, 'struct')
   n = numel(Data);
   if n == 1  % Scalar struct:
      F = sort(fieldnames(Data));  % ignore order of fields
      for iField = 1:length(F)
         H = bitxor(H, CoreHash(Data.(F{iField}), Engine));
      end
   else  % Struct array:
      for iS = 1:n
         H = bitxor(H, CoreHash(Data(iS), Engine));
         %debugHash(H, Data);
      end
   end
elseif isempty(Data)
   % No further actions needed
elseif isnumeric(Data)
   Engine.update(typecast(Data(:), 'uint8'));
   H = bitxor(H, double(typecast(Engine.digest, 'uint8')));
   %debugHash(H, Data);
   
elseif ischar(Data)  % Silly TYPECAST cannot handle CHAR
   Engine.update(typecast(uint16(Data(:)), 'uint8'));
   H = bitxor(H, double(typecast(Engine.digest, 'uint8')));
   %debugHash(H, Data);
elseif iscell(Data)
   for iS = 1:numel(Data)
      H = bitxor(H, CoreHash(Data{iS}, Engine));
      %debugHash(H, Data);
   end
elseif islogical(Data)
   Engine.update(typecast(uint8(Data(:)), 'uint8'));
   H = bitxor(H, double(typecast(Engine.digest, 'uint8')));
   %debugHash(H, Data);
elseif isa(Data, 'function_handle')
   H = bitxor(H, CoreHash(functions(Data), Engine));
   %debugHash(H, Data);
else
   warning(['Type of variable not considered: ', class(Data)]);
end

function debugHash(H, Data)
    fid = fopen('/home/paolo/L250.txt', 'a+');
    fprintf(fid, [mat2str(Data) '\n']);
    fprintf(fid, [mat2str(H) '\n']);
    fclose(fid);

