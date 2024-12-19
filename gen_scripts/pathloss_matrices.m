%cs_tp pathloss matrix
cs_tp_pathloss_LOS = pathloss(cs_tp_distance_matrix,'linear','los');
cs_tp_pathloss_NLOS = pathloss(cs_tp_distance_matrix,'linear','nlos');

%cs_cs pathloss matrix
cs_cs_pathloss_LOS = pathloss(cs_cs_distance_matrix,'linear','los');
cs_cs_pathloss_nLOS = pathloss(cs_cs_distance_matrix,'linear','nlos');

%k = 1.38064852e-23;
%T=290;


