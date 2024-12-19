
function Validity = ValidOrientations (x)
ExpectedOrienations = {'Optimum','Random','Tx','Rx','Relay'};
if ~isnumeric(x)
    Validity = any(validatestring(x, ExpectedOrienations));
elseif isnumeric(x)
    Validity = true;
end
end