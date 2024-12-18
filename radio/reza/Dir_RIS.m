function  Element_Dir = Dir_RIS(RIS)
% Elevation in Radians
Mode = RIS.Mode;
AZ = RIS.AZ;
OR = RIS.Orientation;
EL = RIS.EL;
PiDiv2 = pi/2;
% RIS.Config.ElementDirectivity = 'false';

if isequal(RIS.Type,'Flat') &&(isequal(RIS.Config.Policy,'FF_Assympt'))
    AZ_Tx_Diff = AZ.RISC2TxC - OR;
    AZ_Rx_Diff = AZ.RISC2RxC - OR;
    Net_EL_Tx = EL.RISC2TxC;
    Net_EL_Rx = EL.RISC2RxC;
else
    
    AZ_Tx_Diff = AZ.RIS2Tx - OR;
    AZ_Rx_Diff = AZ.RIS2Rx - OR;
    Net_EL_Tx = EL.RIS2Tx;
    Net_EL_Rx = EL.RIS2Rx;
end

Wrp_AZ_2wrd_Tx = wrapToPi(AZ_Tx_Diff);
Wrp_AZ_2wrd_Rx = wrapToPi(AZ_Rx_Diff);

side_sign = zeros(1,2);
%%%%% Fix Net Az toward transmitter

if abs(Wrp_AZ_2wrd_Tx(1)) >= PiDiv2
    side_sign(1,1) =  -1;
    Net_AZ_2wrd_Tx =  pi - abs(Wrp_AZ_2wrd_Tx);
    
elseif abs(Wrp_AZ_2wrd_Tx(1)) < PiDiv2
    side_sign(1,1) = 1;
    Net_AZ_2wrd_Tx =  abs(Wrp_AZ_2wrd_Tx);
end


%%%%% Fix Net Az toward transmitter
if abs(Wrp_AZ_2wrd_Rx(1)) >= PiDiv2
    side_sign(1,2) =  -1;
    Net_AZ_2wrd_Rx =  pi - abs(Wrp_AZ_2wrd_Rx);
elseif abs(Wrp_AZ_2wrd_Rx(1)) < PiDiv2
    side_sign(1,2) = 1;
    Net_AZ_2wrd_Rx =  abs(Wrp_AZ_2wrd_Rx);
end

side = prod(side_sign);
front_flag = prod(side_sign+1);
q = 0.029;
% q = 0.029;
% q = 0.5;

Element_Dir = zeros(size(Wrp_AZ_2wrd_Tx));

if isequal(RIS.Config.ElementDirectivity,'true')
    impossible_to_serve = ...
        (isequal(Mode,'Star_R') && (side == -1)) || ...
        (isequal(Mode,'Star_T') && (side == +1)) || ...
        (isequal(Mode,'Conventional') && (front_flag == 0));
    
    if impossible_to_serve
        return
    else
        Element_Dir_Tx = 2 * (2*q + 1).* (cos(PiDiv2 - asin(cos(Net_AZ_2wrd_Tx).*sin(Net_EL_Tx))).^(2*q)) / pi;
        Element_Dir_Rx = 2 * (2*q + 1).* (cos(PiDiv2 - asin(cos(Net_AZ_2wrd_Rx).*sin(Net_EL_Rx))).^(2*q)) / pi;
    end
    Element_Dir = Element_Dir_Tx .* Element_Dir_Rx;
elseif  isequal(RIS.Config.ElementDirectivity,'false')
    Element_Dir = ones(size(Wrp_AZ_2wrd_Tx));
else
    error('Unknown Directivity Policy')
end
end