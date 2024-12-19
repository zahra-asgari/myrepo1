string output_filename = ...;
execute{
  output_filename = "../solutions/"+"complete_fixedDonor_blockageModel_sum_mean_"+output_filename;
}
execute PARAMS {

  cplex.epgap = 0.05;                   // Tolerated Optimality Gap
  cplex.tilim = 1800;                   // Time Limit in Seconds
}

float temp;                        // Initial time
execute{
  var before = new Date();
  temp = before.getTime();
}
//----------PARAMETERS----------------
int n_cs = ...; //Candidate Sites
int n_tp = ...; //Test Points
int n_sd = 2;   //2 Smart Devices, RIS and NCR

range C = 1..n_cs;  //set of CSs
range T = 1..n_tp;  //set of TPs
range S = 1..n_sd;  //set of SDs

float ris_price=...;    //price of installing one RIS in c
float ncr_price=...;    //price of installing one NCR in c
float iab_price=...;    //price of installing one IAB node in c
float budget=...;       //planning budget

int delta_bh[C][C] = ...;       //binary parameter checking if a backahul link can be phisically activated
int delta_src[T][C][C][S]=...;  //binary parameter checking if a SRC can be phisically activated

float min_rate_dl=...; //minimum downlink demand per user
float min_rate_ul=...; //minimum uplink demand per user

float C_bh[C][C]=...;           //capacity of a backhaul link
float C_src_dl[T][C][C][S]=...; //average capacity of a downlink SRC
float C_src_ul[T][C][C][S]=...; //average capacity of an uplink SRC
float C_sd_dl[T][C][C][S]=...; //average capacity of a downlink SD-only link (when it is convenient to use it)
float C_sd_ul[T][C][C][S]=...; //average capacity of an uplink SD-only link (when it is convenient to use it)

//angles
float cs_tp_angles[C][T]=...;   //angle between a CS and a TP
float cs_cs_angles[C][C]=...;   //angle between two CSs
float ncr_minangle[C][C]=...;   //min angle of NCR
float ncr_maxangle[C][C]=...;   //max angle of NCR
float max_angle_span=...;       //field of view of a RIS


float M=...; //big M pertaining the maximum incoming/outcoming network traffic

float alpha=...; //fraction of frame dedicated to downlink

int donor_cs_id=...;
int fakeris_cs_id=...;
int ris_id=...;
int ncr_id=...;
//-------VARIABLES-------------

//DEVICE INSTALLATION
dvar boolean y_don[C]; //donor installation
dvar boolean y_iab[C]; //iab node installation
dvar boolean y_ris[C]; //ris installation
dvar boolean y_ncr[C]; //ncr installation

//LINK ACTIVATION
dvar boolean z[C][C]; //backhaul link
dvar boolean x[T][C][C][S]; //src
dvar boolean b[C][C]; //exclusive association of sd to bs

//TRAFFIC FLOW
dvar float+ w_dl[C]; //downlink core traffic
dvar float+ w_ul[C]; //uplink core traffic
dvar float+ f_dl[C][C]; //downlink backhaul traffic
dvar float+ f_ul[C][C]; //uplink backhaul traffic
dvar float+ g_dl[T][C][C][S]; //downlink access traffic
dvar float+ g_ul[T][C][C][S]; //uplink access traffic

//RESOURCE SHARING
dvar float+ t_dl[C] in 0..1; //downlink timeslots ratio
dvar float+ t_ul[C] in 0..1; //uplink timeslots ratio

//SD ORIENTATION
dvar float+ phi[C] in 0..360; //sd panel orientation (ris/ncr)

//MAXMIN
dvar float+ d_min; //demand of worst case ue, total
dvar float+ d_min_dl; //demand of worst case ue, downlink
dvar float+ d_min_ul; //demand of worst case ue, uplink



//---------OBJECTIVE----------

maximize sum(t in T, c in C, r in C,s in S)(g_dl[t][c][r][s]/min_rate_dl + g_ul[t][c][r][s]/min_rate_ul);

subject to{
//______________________________TOPOLOGY SECTION_____________________________

    forall(c in C)
        one_tech:
            y_iab[c] + y_ris[c] + y_ncr[c] <= 1;
    forall(c in C)
        donor_up:
            y_don[c] <= y_iab[c];
    forall(c in C, d in C)
        bh_link1:
            z[c][d] <= delta_bh[c][d]*y_iab[c];
    forall(c in C, d in C)
        bh_link2:
            z[c][d] <= delta_bh[c][d]*y_iab[d];
    forall(t in T, c in C, r in C)
        src_ris_1:
            x[t][c][r][ris_id] <= delta_src[t][c][r][ris_id]*y_iab[c];
    forall(t in T, c in C, r in C)
        src_ris_2:
            x[t][c][r][ris_id] <= delta_src[t][c][r][ris_id]*y_ris[r];
    forall(t in T, c in C, r in C)
        src_ncr_1:
            x[t][c][r][ncr_id] <= delta_src[t][c][r][ncr_id]*y_iab[c];
    forall(t in T, c in C, r in C)
        src_ncr_2:
            x[t][c][r][ncr_id] <= delta_src[t][c][r][ncr_id]*y_ncr[r];
    forall(t in T)
        one_src_per_tp:
            sum(c in C, r in C, s in S)(x[t][c][r][s]) == 1;
    forall(c in C)
        tree_topology:
            sum(d in C)(z[d][c]) <= 1 - y_don[c];
        single_donor:
            sum(c in C) y_don[c] == 1;
    forall(t in T, c in C, r in C)
        exclusive_use_1:
            sum(s in S)x[t][c][r][s] <= b[c][r];
    forall(r in C: r != fakeris_cs_id)
        exclusive_use_2:
            sum(c in C)b[c][r] <= 1;

//______________________________FLOW SECTION_____________________________

    forall(c in C,d in C)
        flow_dl_act:
            f_dl[c][d] <= C_bh[c][d]*z[c][d];
    forall(c in C,d in C)
        flow_ul_act:
            f_ul[d][c] <= C_bh[d][c]*z[c][d];
    forall(c in C)
        node_flow_balance_dl:
            w_dl[c] + sum(d in C)(f_dl[d][c] - f_dl[c][d]) - sum(t in T, r in C, s in S)(g_dl[t][c][r][s]) == 0;
    forall(c in C)
        node_flow_balance_ul:
            -w_ul[c] + sum(d in C)(f_ul[d][c] - f_ul[c][d]) + sum(t in T, r in C, s in S)(g_ul[t][c][r][s]) == 0;
    forall(t in T, c in C, r in C, s in S)
       minimum_dl_demand:
            g_dl[t][c][r][s] >= min_rate_dl * x[t][c][r][s];
    forall(t in T, c in C, r in C, s in S)
       minimum_ul_demand:
            g_ul[t][c][r][s] >= min_rate_ul * x[t][c][r][s];
    forall(t in T, c in C, r in C, s in S)
        maximum_dl_demand:
            g_dl[t][c][r][s] <= C_src_dl[t][c][r][s] * x[t][c][r][s];
    forall(t in T, c in C, r in C, s in S)
        maximum_ul_demand:
            g_ul[t][c][r][s] <= C_src_ul[t][c][r][s] * x[t][c][r][s];
    forall(c in C)
        donor_total_traffic:
            w_dl[c] + w_ul[c]<= M * y_don[c];

    forall(c in C: c!=fakeris_cs_id)
        bs_dl_def:
            t_dl[c] == sum(d in C: (C_bh[c][d] != 0))(f_dl[c][d]/C_bh[c][d]) + sum(d in C: (C_bh[d][c] != 0))(f_dl[d][c]/C_bh[d][c])  + sum(t in T, r in C,s in S: C_src_dl[t][c][r][s]!=0)(g_dl[t][c][r][s]/C_src_dl[t][c][r][s]);
    forall(c in C: c!=fakeris_cs_id)
        bs_dl_bound:
            t_dl[c] <= alpha*y_iab[c];
    forall(c in C: c!=fakeris_cs_id)
        bs_ul_def:
            t_ul[c] == sum(d in C: (C_bh[c][d] != 0))(f_ul[c][d]/C_bh[c][d]) + sum(d in C: (C_bh[d][c] != 0))(f_ul[d][c]/C_bh[d][c])  + sum(t in T, r in C,s in S: C_src_ul[t][c][r][s]!=0)(g_ul[t][c][r][s]/C_src_ul[t][c][r][s]);
    forall(c in C: c!=fakeris_cs_id)
        bs_ul_bound:
            t_ul[c] <= (1 - alpha)*y_iab[c];
//______________________________ANGLES SECTION_____________________________

    forall(t in T, c in C, r in C : r != fakeris_cs_id)
        SD_orientation1:
            phi[r] >= cs_tp_angles[r][t] - max_angle_span - (cs_tp_angles[r][t] - max_angle_span)*(1-sum(s in S)x[t][c][r][s]);
    forall(t in T, c in C, r in C : r != fakeris_cs_id)
        SD_orientation2:
            phi[r] <= cs_tp_angles[r][t] + max_angle_span + (360 - cs_tp_angles[r][t] - max_angle_span)*(1-sum(s in S)x[t][c][r][s]);
    forall(t in T, c in C, r in C : r != fakeris_cs_id)        
        RIS_orientation3:
            phi[r] >= cs_cs_angles[r][c] - max_angle_span - (cs_cs_angles[r][c] - max_angle_span)*(1-x[t][c][r][ris_id]);
    forall(t in T, c in C, r in C : r != fakeris_cs_id)
        RIS_orientation4:
            phi[r] <= cs_cs_angles[r][c] + max_angle_span + (360 - cs_cs_angles[r][c] - max_angle_span)*(1-x[t][c][r][ris_id]);
    forall(t in T, c in C, r in C : r != fakeris_cs_id)        
       NCR_orientation3:
            phi[r] >= ncr_minangle[r][c] - (ncr_minangle[r][c])*(1-x[t][c][r][ncr_id]);
    forall(t in T, c in C, r in C : r != fakeris_cs_id)
        NCR_orientation4:
            phi[r] <= ncr_maxangle[r][c] + (360 - ncr_maxangle[c][r])*(1-x[t][c][r][ncr_id]);

//______________________________BUDGET SECTION_____________________________

    budget_constraint:
        sum(c in C : c != donor_cs_id && c != fakeris_cs_id)(y_iab[c]*iab_price + y_ris[c]*ris_price + y_ncr[c]*ncr_price) <= budget;
//______________________________FIXED DEVICES SECTION_____________________________

        fixed_donor:
            y_don[donor_cs_id] >= 1;

        fixed_fakeris:
            y_ris[fakeris_cs_id] >= 1;

        no_fakesd:
           y_ncr[fakeris_cs_id] == 0;

}

//---------POST PROCESSING----------

execute{

var ofile = new IloOplOutputFile(output_filename);
var output = "";

var after = new Date();
var output = "time = "
output += after.getTime()-temp
output += ";"
ofile.writeln(output);

//------variable y_don

output = "y_don = [";

for(var c in thisOplModel.C){
    output+= thisOplModel.y_don[c];
    output+= ";";
}  
output += "];"

ofile.writeln(output);

//------variable y_iab

output = "y_iab = [";
for(var c in thisOplModel.C){
    output+= thisOplModel.y_iab[c];
    output+= ";";
}
output += "];"
ofile.writeln(output);

//------variable y_ris

output = "y_ris = [";
for(var c in thisOplModel.C){
    output+= thisOplModel.y_ris[c];
    output+= ";";
}
output += "];"
ofile.writeln(output);

//------variable y_ncr

output = "y_ncr = [";
for(var c in thisOplModel.C){
    output+= thisOplModel.y_ncr[c];
    output+= ";";
}
output += "];"
ofile.writeln(output);

//-------variable z
output = "z = [";
    for(var c in thisOplModel.C){
        for(var d in thisOplModel.C){
            output+= thisOplModel.z[c][d];
            if(d == thisOplModel.n_cs){
                output += ";"
            } else {
            output += " "
            }
        }
    }
    output += "];"
    ofile.writeln(output);

//------variable x
//this is a 4D variable, we need to write 2D slices
for(var s in thisOplModel.S){//outer slices loop
for(var r in thisOplModel.C){ //inner slices loop
    output = "x(:,:,";
    output += r;
    output += ","
    output += s;
    output += ") = ["

    //print slice
    for(var t in thisOplModel.T){
        for(var c in thisOplModel.C){
            output+= thisOplModel.x[t][c][r][s];
            if(c == thisOplModel.n_cs){
                output += ";"
            } else {
            output += " "
            }
        }
    }
    output += "];"
    ofile.writeln(output);
}}

//-------variable b
output = "b = [";
    for(var c in thisOplModel.C){
        for(var r in thisOplModel.C){
            output+= thisOplModel.b[c][r];
            if(r == thisOplModel.n_cs){
                output += ";"
            } else {
            output += " "
            }
        }
    }
    output += "];"
    ofile.writeln(output);

//------variable w_dl

output = "w_dl = [";
for(var c in thisOplModel.C){
    output+= thisOplModel.w_dl[c];
    output+= ";";
}
output += "];"
ofile.writeln(output);

//------variable w_ul

output = "w_ul = [";
for(var c in thisOplModel.C){
    output+= thisOplModel.w_ul[c];
    output+= ";";
}
output += "];"
ofile.writeln(output);

//-------variable f_dl
output = "f_dl = [";
    for(var c in thisOplModel.C){
        for(var d in thisOplModel.C){
            output+= thisOplModel.f_dl[c][d];
            if(d == thisOplModel.n_cs){
                output += ";"
            } else {
            output += " "
            }
        }
    }
    output += "];"
    ofile.writeln(output);

//-------variable f_ul
output = "f_ul = [";
    for(var c in thisOplModel.C){
        for(var d in thisOplModel.C){
            output+= thisOplModel.f_ul[c][d];
            if(d == thisOplModel.n_cs){
                output += ";"
            } else {
            output += " "
            }
        }
    }
    output += "];"
    ofile.writeln(output);

//------variable g_dl
//this is a 4D variable, we need to write 2D slices
for(var s in thisOplModel.S){//outer slices loop
for(var r in thisOplModel.C){ //inner slices loop
    output = "g_dl(:,:,";
    output += r;
    output += ","
    output += s;
    output += ") = ["

    //print slice
    for(var t in thisOplModel.T){
        for(var c in thisOplModel.C){
            output+= thisOplModel.g_dl[t][c][r][s];
            if(c == thisOplModel.n_cs){
                output += ";"
            } else {
            output += " "
            }
        }
    }
    output += "];"
    ofile.writeln(output);
}}

//------variable g_ul
//this is a 4D variable, we need to write 2D slices
for(var s in thisOplModel.S){//outer slices loop
for(var r in thisOplModel.C){ //inner slices loop
    output = "g_ul(:,:,";
    output += r;
    output += ","
    output += s;
    output += ") = ["

    //print slice
    for(var t in thisOplModel.T){
        for(var c in thisOplModel.C){
            output+= thisOplModel.g_ul[t][c][r][s];
            if(c == thisOplModel.n_cs){
                output += ";"
            } else {
            output += " "
            }
        }
    }
    output += "];"
    ofile.writeln(output);
}}

//------variable t_dl
output = "t_dl = [";
for (var c in thisOplModel.C){
    output+=thisOplModel.t_dl[c];
    output+=";";
}
output += "];"
ofile.writeln(output);

//------variable t_ul
output = "t_ul = [";
for (var c in thisOplModel.C){
    output+=thisOplModel.t_ul[c];
    output+=";";
}
output += "];"
ofile.writeln(output);

//------variable phi
output = "phi = [";
for (var c in thisOplModel.C){
    output+=thisOplModel.phi[c];
    output+=";";
}
output += "];"
ofile.writeln(output);

//------variable d_min
output = "d_min = ";
output+=thisOplModel.d_min;
output+=";";
ofile.writeln(output);

ofile.writeln("obj="+cplex.getObjValue()+";")

ofile.close();

}
