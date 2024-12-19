
function [H_RIS,Blockage] = Compute_RIS_Channel(A,D,P,Phi_D)
RIS = P.RIS;
Tx = P.Tx;
% Rx = P.Rx;
lambda = P.comm.lambda;
Phi_D = reshape(Phi_D,1,size(Phi_D,1),size(Phi_D,2));
dx = P.RIS.d;
dy = P.RIS.d;
M = P.RIS.Nh;
N = P.RIS.Nv;
theta_t = RIS.EL.RISCenter2TxCenter;
phi_t = RIS.AZ.RISCenter2TxCenter;
theta_des = RIS.EL.RISCenter2RxCenter;
phi_des = RIS.AZ.RISCenter2RxCenter;

EffAreaCoeff =1;



h_BS = P.Tx.Center(3);
h_RIS = P.RIS.Center(3);
Theta_v_Tx2Rx = atan2((h_RIS - h_BS),RIS.Dis.TxCenter2RISCenter_3D);

if isequal(Tx.Device,'BS')
    Normalized_Dir_Tx = Dir_Patch(wrapToPi(A.Tx.Relay - P.Tx.Selected.Orientation) ,wrapToPi(Theta_v_Tx2Rx -  P.Tx.DownTiltRad));
elseif isequal(Tx.Device,'UE')
    Normalized_Dir_Tx = Dir_Patch(wrapToPi(A.Tx.Relay - P.Tx.Panel.Orientation) ,wrapToPi(Theta_v_Tx2Rx -  P.Tx.DownTiltRad));
end

% Config.Policy = 'FF_Assympt';
if isequal(P.RIS.Config.Policy,'FF_Assympt')
    Cen2TX_Dir = Dir_RIS((RIS.EL.RISCenter2Tx ) ,RIS.Config.ElementDirectivity) ;
    Cen2RX_Dir = Dir_RIS((RIS.EL.RISCenter2Rx ) ,RIS.Config.ElementDirectivity) ;
    F_comb = db2pow(Normalized_Dir_Tx) .*  Cen2TX_Dir .* Cen2RX_Dir ;
else
    RIS2TX_Dir = Dir_RIS((RIS.EL.RIS2Tx ) ,RIS.Config.ElementDirectivity);
    RIS2RX_Dir = Dir_RIS((RIS.EL.RIS2Rx ) ,RIS.Config.ElementDirectivity);
    F_comb =  db2pow(Normalized_Dir_Tx) .* RIS2TX_Dir .* RIS2RX_Dir;
end


switch P.RIS.Config.Policy
    case 'Focus'
        PropagChLength_Real = RIS.Dis.Tx2RIS_3D + RIS.Dis.Rx2RIS_3D;
        Phase_RIS_Real  = mean(mean(mod(2.*pi.*(PropagChLength_Real)/lambda,2*pi),2),3);
        TotCHPhase = exp(-1j.* ((2.*pi.*(PropagChLength_Real) - lambda * Phase_RIS_Real) /lambda - Phi_D));
        H_RIS = squeeze(sum(TotCHPhase./(D.RX2RIS_3D .* D.Tx2RIS_3D) .* ...
            sqrt(F_comb .* EffAreaCoeff * dx.*dy.*(lambda^2) / (64 * (pi.^3))),1));
    case 'Specular'
        PropagChLength_Real = RIS.Dis.Tx2RIS_3D + RIS.Dis.Rx2RIS_3D;
        TotCHPhase = exp(-1j.* (2.*pi.*(PropagChLength_Real)) /lambda );
        H_RIS = squeeze(sum(TotCHPhase./(D.RX2RIS_3D .* D.Tx2RIS_3D) .* ...
            sqrt(F_comb .* EffAreaCoeff * dx.*dy.*(lambda^2) / (64 * (pi.^3))),1));
    case 'Anomalous'
        PropagChLength_Real = RIS.Dis.Tx2RIS_3D + RIS.Dis.Rx2RIS_3D;
        RIS_Indexes_H = 1- M/2:1:(M/2);
        RIS_Indexes_V = 1j.*((1-N/2:1:(N/2))).';
        RIS_Indexes = RIS_Indexes_H + RIS_Indexes_V;
        Sigma1 =  - sin(theta_t).* cos(phi_t)  - sin(theta_des) .* cos(phi_des);
        Sigma2 =  - sin(theta_t).* sin(phi_t) - sin(theta_des) .* sin(phi_des);
        PropagChLength_FF_Assump =  (RIS.Dis.Tx2RISCenter_3D) + (RIS.Dis.RX2RISCenter_3D) +((Sigma1 .* real(RIS_Indexes(:)-0.5) .* dx + Sigma2 .* imag(RIS_Indexes(:)-0.5) .* dy));
        Phase_RIS_FF_Assump  = (mod(2.*pi.*(PropagChLength_FF_Assump)/lambda,2*pi));
        TotCHPhase = exp(-1j.* ((2.*pi.*(PropagChLength_Real) - lambda .* Phase_RIS_FF_Assump) /lambda  - Phi_D));
        H_RIS = squeeze(sum(TotCHPhase./(RIS.Dis.Rx2RIS_3D .* RIS.Dis.Tx2RIS_3D) .* ...
            sqrt(F_comb .* EffAreaCoeff .* dx.*dy.*(lambda^2) / (64 * (pi.^3))),1));
        
    case 'FF_Assympt'
        Dist_Tx_3D = RIS.Dis.Tx2RISCenter_3D;
        Dist_Rx_3D = RIS.Dis.RX2RISCenter_3D;
        Sigma1 = - sin(theta_t) .* cos(phi_t) - sin(theta_des) .* cos(phi_des);
        Sigma2 = - sin(theta_t) .* sin(phi_t) - sin(theta_des) .* sin(phi_des);
        Sinc_Arg1 = sin(theta_t) * cos(phi_t) + sin(theta_des) * cos(phi_des) + Sigma1;
        Sinc_Arg2 = sin(theta_t) * sin(phi_t) + sin(theta_des) * sin(phi_des) + Sigma2;
        SincTerm1 = sinc(M.*pi .* (Sinc_Arg1) .* dx./lambda) ./ sinc(pi .* (Sinc_Arg1) .* dx./lambda);
        SincTerm2 = sinc(N.*pi .* (Sinc_Arg2) .* dy./lambda) ./ sinc(pi .* (Sinc_Arg2) .* dy./lambda);
        
        H_RIS = squeeze(M.*N.*sqrt(EffAreaCoeff * dx.*dy .* F_comb) .* lambda  ...
            .* (SincTerm1 .* SincTerm2).*  exp(-1j.* Phi_D) ...
            ./(sqrt(64 .* (pi.^3) .* (Dist_Tx_3D.*Dist_Rx_3D).^2)));
        
end
% H_RIS  = H_RIS  .*  sqrt(db2pow(P.Tx.Ptx + 10*log10(P.Tx.Efficiency) + 10*log10(P.Rx.Efficiency)));
H_RIS  = H_RIS  .*  sqrt(db2pow(P.Tx.Ptx + 10*log10(P.Tx.Efficiency) + 10*log10(P.Rx.Efficiency)));
% H_RIS  = H_RIS  .*  sqrt(db2pow(P.Tx.Ptx));
if P.Config.Check_Dynamic_Blockage
    Blockage = P.Blockage.Handle(D.Rx.Relay,P.Blockage);
elseif ~P.Config.Check_Dynamic_Blockage
    Blockage.Loss = 0;
    Blockage.PB = 0;
else
    error('Undefined Dynamic Blockage Status')
end

end
% end