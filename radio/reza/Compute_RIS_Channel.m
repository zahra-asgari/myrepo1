function [H_RIS,Blockage] = Compute_RIS_Channel(Params,RIS,Phi_D)
% RIS = P.RIS;

lambda = Params.comm.lambda;
Phi_D = reshape(Phi_D,1,size(Phi_D,1),size(Phi_D,2));
dx = RIS.d;
dy = RIS.d;
M = RIS.Nh;
N = RIS.Nv;
OR = RIS.Orientation;
Theta_i = RIS.AZ.RISC2TxC - OR;
Phi_i = RIS.EL.RISC2TxC;

Theta_O  = RIS.AZ.RISC2RxC - OR;
Phi_O   = RIS.EL.RISC2RxC;

EffAreaCoeff =1;

Normalized_Dir_Tx = 0;

RIS2TX_Dir = Dir_RIS(RIS);
% RIS2TX_Dir = Dir_RIS( RIS.EL.RIS2Tx , RIS.AZ.RIS2Tx , RIS.Config.ElementDirectivity, RIS.q);
% RIS2RX_Dir = Dir_RIS( RIS.EL.RIS2Rx , RIS.AZ.RIS2Rx , RIS.Config.ElementDirectivity, RIS.q);
F_comb =  db2pow(Normalized_Dir_Tx) .* RIS2TX_Dir;

% F_comb = ones(size(F_comb));
% F_comb = 1;
switch RIS.Config.Policy
    case 'Focus'
        PropagChLength_Real = RIS.Dis.Tx2RIS + RIS.Dis.Rx2RIS;
        Phase_RIS_Real  = mod(2.*pi.*(PropagChLength_Real(:,1,1))/lambda,2*pi);
        TotCHPhase = exp(-1j.* ((2.*pi.*(PropagChLength_Real) - lambda * Phase_RIS_Real) /lambda - Phi_D));
        H_RIS = squeeze(sum(TotCHPhase./(RIS.Dis.Rx2RIS .* RIS.Dis.Tx2RIS) .* ...
            sqrt(F_comb .* EffAreaCoeff * dx.*dy.*(lambda^2) / (64 * (pi.^3))),1));
    case 'Specular'
        PropagChLength_Real = RIS.Dis.Tx2RIS + RIS.Dis.Rx2RIS;
        TotCHPhase = exp(-1j.* (2.*pi.*(PropagChLength_Real)) /lambda );
        H_RIS = squeeze(sum(TotCHPhase./(RIS.Dis.Rx2RIS .* RIS.Dis.Tx2RIS) .* ...
            sqrt(F_comb .* EffAreaCoeff * dx.*dy.*(lambda^2) / (64 * (pi.^3))),1));
        
        % %     case 'Bare'
        % %         PropagChLength_Real = RIS.Dis.Tx2RIS + RIS.Dis.Rx2RIS;
        % %         TotCHPhase = exp(-1j.* (2.*pi.*(PropagChLength_Real)) /lambda );
        % %         H_RIS = squeeze(sum(TotCHPhase./(RIS.Dis.Rx2RIS .* RIS.Dis.Tx2RIS) .* ...
        % %             sqrt(F_comb .* EffAreaCoeff * dx.*dy.*(lambda^2) / (64 * (pi.^3))),1));
        
    case 'An_Curved'
        PropagChLength_Real = RIS.Dis.Tx2RIS + RIS.Dis.Rx2RIS;
        RIS_Indexes_H = 1- M/2:1:(M/2);
        RIS_Indexes_V = 1j.*((1-N/2:1:(N/2))).';
        RIS_Indexes = RIS_Indexes_H + RIS_Indexes_V;
        R = RIS.CurveRadius;
        phi_m = 2 * ((0:M-1)'-M/2) * asin(dy/(2*R));
        PHI_m = repmat(phi_m,N,1);
        P1 = R * (cos(PHI_m) - 1)* (cos(Theta_O)*sin(Phi_O) + cos(Theta_i)*sin(Phi_i));
        P2 = dx * (real(RIS_Indexes(:)-0.5))* (+sin(Theta_O)*sin(Phi_O) + sin(Theta_i)*sin(Phi_i));
        P3 = R * sin(PHI_m)*(cos(Phi_O) + cos(Phi_i));
        PropagChLength_FF_Assump = (RIS.Dis.Tx2RISC) + (RIS.Dis.RX2RISC)+...
            (-P1 -P2 - P3);
        Phase_RIS_FF_Assump  = (mod(2.*pi.*(PropagChLength_FF_Assump)/lambda,2*pi));
        TotCHPhase = exp(-1j.* ((2.*pi.*(PropagChLength_Real) - lambda .* Phase_RIS_FF_Assump) /lambda  - Phi_D));
        % % %         AA = squeeze(TotCHPhase(:,1,1));
        % % %         BB = reshape(AA,100,100);
        % % %         imagesc(angle(BB))
        % % %         colorbar
        H_RIS = squeeze(sum(TotCHPhase./(RIS.Dis.Rx2RIS .* RIS.Dis.Tx2RIS) .* ...
            sqrt(F_comb .* EffAreaCoeff .* dx.*dy.*(lambda^2) / (64 * (pi.^3))),1));
    case 'SmSk'
        PropagChLength_Real = RIS.Dis.Tx2RIS + RIS.Dis.Rx2RIS;
        R = RIS.CurveRadius;
        
        N_Panels = numel(RIS.Fix_Azim);
        FixAngs = RIS.Fix_Azim;
        AngleVector = zeros(1,M*N);
        for Ang_Iter = 1:N_Panels
            ThisAngle =  FixAngs(Ang_Iter);
            AngleVector(1,(Ang_Iter-1)*M*N/N_Panels+1:(Ang_Iter)*M*N/N_Panels) =  ThisAngle;
        end
        
        phi_m = 2 * ((0:M-1)'-M/2) * asin(dy/(2*R));
        PHI_m = repmat(phi_m,N,1);
        
        PropagChLength_FF_Assump = (RIS.Dis.Tx2RISC) + (RIS.Dis.RX2RISC)+...
            -2*R*(cos(PHI_m)-1).*cosd(AngleVector.');
        
        % %         phi_m = 2 * ((0:M-1)'-M/2) * asin(dy/(2*R));
        % %         PHI_m = repmat(phi_m,N,1);
        % %         PropagChLength_FF_Assump = (RIS.Dis.Tx2RISC) + (RIS.Dis.RX2RISC)+...
        % %             -2*R*(cos(PHI_m)-1)*cosd(RIS.Fix_Azim);
        
        Phase_RIS_FF_Assump  = (mod(2.*pi.*(PropagChLength_FF_Assump)/lambda,2*pi));
        TotCHPhase = exp(-1j.* ((2.*pi.*(PropagChLength_Real) - lambda .* Phase_RIS_FF_Assump) /lambda  - Phi_D));
        H_RIS = squeeze(sum(TotCHPhase./(RIS.Dis.Rx2RIS .* RIS.Dis.Tx2RIS) .* ...
            sqrt(F_comb .* EffAreaCoeff .* dx.*dy.*(lambda^2) / (64 * (pi.^3))),1));
        
    case 'An_Flat'
        PropagChLength_Real = RIS.Dis.Tx2RIS + RIS.Dis.Rx2RIS;
        RIS_Indexes_H = 1- M/2:1:(M/2);
        RIS_Indexes_V = 1j.*((1-N/2:1:(N/2))).';
        RIS_Indexes = RIS_Indexes_H + RIS_Indexes_V;
        
        %         PropagChLength_FF_Assump = (RIS.Dis.Tx2RISC) + (RIS.Dis.RX2RISC)+...
        %             dx * (real(RIS_Indexes(:)-0.5))*(+sin(Theta_O)*sin(Phi_O) + sin(Theta_i)*sin(Phi_i)) + ...
        %             dy .* imag(RIS_Indexes(:)-0.5) .* (cos(Phi_O) + cos(Phi_i));
        
        PropagChLength_FF_Assump = (RIS.Dis.Tx2RISC) + (RIS.Dis.RX2RISC)-...
            dx * (real(RIS_Indexes(:)-0.5))*(+sin(Theta_O)*sin(Phi_O) + sin(Theta_i)*sin(Phi_i)) - ...
            dy .* imag(RIS_Indexes(:)-0.5) .* (cos(Phi_O) + cos(Phi_i));
        
        
        Phase_RIS_FF_Assump  = (mod(2.*pi.*(PropagChLength_FF_Assump)/lambda,2*pi));
        TotCHPhase = exp(-1j.* ((2.*pi.*(PropagChLength_Real) - lambda .* Phase_RIS_FF_Assump) /lambda  - Phi_D));
        H_RIS = squeeze(sum(TotCHPhase./(RIS.Dis.Rx2RIS .* RIS.Dis.Tx2RIS) .* ...
            sqrt(F_comb .* EffAreaCoeff .* dx.*dy.*(lambda^2) / (64 * (pi.^3))),1));
        
        
    case 'FF_Assympt'
        Dist_Tx = RIS.Dis.TxC2RISC;
        Dist_Rx = RIS.Dis.RxC2RISC;
%         Sigma1 = - sin(theta_t) .* cos(phi_t) - sin(theta_des) .* cos(phi_des);
%         Sigma2 = - sin(theta_t) .* sin(phi_t) - sin(theta_des) .* sin(phi_des);
%         Sinc_Arg1 = sin(theta_t) * cos(phi_t) + sin(theta_des) * cos(phi_des) + Sigma1;
%         Sinc_Arg2 = sin(theta_t) * sin(phi_t) + sin(theta_des) * sin(phi_des) + Sigma2;
%         SincTerm1 = sinc(M.*pi .* (Sinc_Arg1) .* dx./lambda) ./ sinc(pi .* (Sinc_Arg1) .* dx./lambda);
%         SincTerm2 = sinc(N.*pi .* (Sinc_Arg2) .* dy./lambda) ./ sinc(pi .* (Sinc_Arg2) .* dy./lambda);
        
        H_RIS = sqrt(Params.Tx.ArrSize * Params.Rx.ArrSize) * squeeze(M.*N.*sqrt(dx.*dy .* F_comb) .* lambda  ...
            ./(sqrt(64 .* (pi.^3) .* (Dist_Tx.*Dist_Rx).^2)));
end

H_RIS  = H_RIS  .*  sqrt(db2pow(Params.Tx.Ptx + 10*log10(Params.Tx.Efficiency) + 10*log10(Params.Rx.Efficiency)));

if Params.Config.Check_Dynamic_Blockage
    Blockage = Params.Blockage.Handle(RIS.Dis.RxC2RISC,Params.Blockage);
elseif ~Params.Config.Check_Dynamic_Blockage
    Blockage.Loss = 0;
    Blockage.PB = 0;
else
    error('Undefined Dynamic Blockage Status')
end
Blockage.Event = false;
end

