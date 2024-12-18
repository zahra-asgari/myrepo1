function  Element_Dir = Dir_RIS(Elevation,Config)
% Elevation in Radians
Wrapped_Elev = wrapToPi(Elevation);
q = 0.29;
% q = 0.5;
Element_Dir = zeros(size(Wrapped_Elev));

if isequal(Config,'true')
    Indexes = find(abs(Wrapped_Elev)<(pi/2));
    Element_Dir(Indexes) = 2 * (2*q + 1).* (cos(Wrapped_Elev(Indexes)).^(2*q)) / pi;
%     Element_Dir(Indexes) =  (cosd(Wrapped_Elev(Indexes))).^(2*q);
    %     Element_Dir(~Indexes) = 0;
elseif  isequal(Config,'false')
    Element_Dir = ones(size(Elevation));
else
    error('Unknown Directivity Policy')
end
end