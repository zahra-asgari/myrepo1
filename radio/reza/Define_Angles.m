function [Ang] = Define_Angles(Dis,Vec)
PHI1 = 0;
PHI2 = 0;
%% RIS and TX
Ang.RIS2Tx_ELs =  abs(atan2(Dis.Tx2RIS_2D, Vec.RIS2Tx(:,:,:,1))- PHI1);
Ang.RIS2Tx_AZs =  (atan2(Vec.RIS2Tx(:,:,:,3) , Vec.RIS2Tx(:,:,:,2)));
Ang.RISCenter2Tx_EL =  abs(atan2(Dis.Tx2RISCenter_2D, Vec.RISCenter2Tx(:,:,:,1))- PHI1) ;
Ang.RISCenter2Tx_AZ =  (atan2(Vec.RISCenter2Tx(:,:,:,3), Vec.RISCenter2Tx(:,:,:,2)));
Ang.RISCenter2TxCenter_EL =  abs(atan2(Dis.TxCenter2RISCenter_2D, Vec.RISCenter2TxCenter(:,:,:,1))- PHI1) ;
Ang.RISCenter2TxCenter_AZ =  (atan2(Vec.RISCenter2TxCenter(:,:,:,3), Vec.RISCenter2TxCenter(:,:,:,2)));

%% RIS and RX

Ang.RIS2Rx_ELs =  abs(atan2(Dis.Rx2RIS_2D, Vec.RIS2Rx(:,:,:,1))- PHI2);
Ang.RIS2Rx_AZs = (atan2(Vec.RIS2Rx(:,:,:,3), Vec.RIS2Rx(:,:,:,2)));
Ang.RISCenter2Rx_EL =  abs(atan2(Dis.Rx2RISCenter_2D, Vec.RISCenter2Rx(:,:,:,1)) - PHI2) ;
Ang.RISCenter2Rx_AZ = (atan2(Vec.RISCenter2Rx(:,:,:,3), Vec.RISCenter2Rx(:,:,:,2)));
Ang.RISCenter2RxCenter_EL =  abs(atan2(Dis.RxCenter2RISCenter_2D, Vec.RISCenter2RxCenter(:,:,:,1)) - PHI2) ;
Ang.RISCenter2RxCenter_AZ = (atan2(Vec.RISCenter2RxCenter(:,:,:,3), Vec.RISCenter2RxCenter(:,:,:,2)));
end