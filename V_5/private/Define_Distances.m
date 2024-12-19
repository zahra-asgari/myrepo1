function [Dis,Ang,Params] = Define_Distances(Params)
Tx = Params.Tx;
Rx = Params.Rx;
% RIS = Params.RIS;
AF = Params.AF;


RelayPos = AF.Center; % could also use the one in the next line, center of any relay in general
TxPos = Tx.Center;
RxPos = Rx.Center;

Dis.Tx.Rx = pdist2(TxPos,  RxPos);
Dis.Tx.Rx_2D = pdist2(TxPos(1:2),  RxPos(1:2));

Dis.Tx.Relay = pdist2(TxPos,  RelayPos);
Dis.Tx.Relay_2D = pdist2(TxPos(1:2),  RelayPos(1:2));

Dis.Rx.Relay = pdist2(RxPos,  RelayPos);
Dis.Rx.Relay_2D = pdist2(RxPos(1:2),  RelayPos(1:2));

Ang.Tx.Relay =  atan2(RelayPos(2)-TxPos(2), RelayPos(1)-TxPos(1));
Ang.Relay.Tx = wrapToPi(Ang.Tx.Relay + pi);
Ang.Tx.Rx =  atan2(RxPos(2)-TxPos(2), RxPos(1)-TxPos(1));
Ang.Rx.Tx =  wrapToPi(Ang.Tx.Rx + pi);
Ang.Rx.Relay = atan2(RelayPos(2) - RxPos(2),  RelayPos(1) - RxPos(1));
Ang.Relay.Rx = wrapToPi(Ang.Rx.Relay + pi);
end




