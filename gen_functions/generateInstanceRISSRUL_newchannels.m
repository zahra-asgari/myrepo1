function [instance] = generateInstanceRISSRUL_newchannels(scenario, instance_folder, dataname, rng_seed)
%generateInstances this function generates a random instance to be later
%simulated
%
% [instance] = generateInstances()
%
% $Author: Eugenio Moro $	$Date: 2020/11/30 16:29:44 $	$Revision: 0.1 $
% Copyright: Politecnico di Milano 2020
addpath('utils', 'radio', 'gen_scripts');
genpath('radio');

%these are local options that should be set to 1 only for debug
PLOT_SITE = 0;
PLOT_DISTANCE_STATISTICS = 0;

%unpack scenario into workspace
v2struct(scenario);
clear size;
rng(rng_seed);

%% cs and tp
cs_tp_generation;
distances;

%% angles computation
angle_parameters;

%% Building collision
%if scenario.has_buildings
%    building_collisions;
%end

%% Radio channels computation
%TODO: put all this stuff into a different function?
iab_entity=radio_entity_par('iab',scenario.radio_prm);
donor_entity=radio_entity_par('donor',scenario.radio_prm);
ue_entity=radio_entity_par('ue_omni',scenario.radio_prm);
ris_entity=radio_entity_par('ris',scenario.radio_prm);
af_entity=radio_entity_par('af_type_1',scenario.radio_prm);
% rx_entity = get_rx_entities('omni_ue',scenario.radio_prm);
% tx_entity1 = get_tx_entities('donor',scenario.radio_prm);
% tx_entity2 = get_tx_entities('iab',scenario.radio_prm);
% ris_entity = get_srd_entities('ris',scenario.radio_prm);
% af_entity = get_srd_entities('af_type_1',scenario.radio_prm);

iab_positions_3d = [cs_positions, repmat(6,n_cs,1)]; %add height to CS positions, same for TP, RIS and AF
ue_positions_3d = [tp_positions, repmat(1.5,n_tp,1)];
ris_positions_3d = [cs_positions, repmat(3,n_cs,1)];
af_positions_3d = ris_positions_3d;

%downlink snr matrices
direct_snr_donor_dl=zeros(n_tp,n_cs);
ris_snr_donor_dl=zeros(n_tp,n_cs,n_cs);
af_snr_donor_dl=zeros(n_tp,n_cs,n_cs);
direct_snr_iab_dl=zeros(n_tp,n_cs);
ris_snr_iab_dl=zeros(n_tp,n_cs,n_cs);
af_snr_iab_dl=zeros(n_tp,n_cs,n_cs);

%uplink snr matrices
direct_snr_donor_ul=zeros(n_tp,n_cs);
ris_snr_donor_ul=zeros(n_tp,n_cs,n_cs);
af_snr_donor_ul=zeros(n_tp,n_cs,n_cs);
direct_snr_iab_ul=zeros(n_tp,n_cs);
ris_snr_iab_ul=zeros(n_tp,n_cs,n_cs);
af_snr_iab_ul=zeros(n_tp,n_cs,n_cs);

%bh snr matrices
bh_snr_iab=zeros(n_tp,n_cs);
bh_snr_donor_tx=zeros(n_tp,n_cs);
bh_snr_donor_rx=zeros(n_tp,n_cs);

% for i=1:n_tp
%     disp(i)
%     for j=1:n_cs
%         for k=1:n_cs
%             if k~=j
%                 tx_entity1.pos = tx_positions_3d(j,:);
%                 tx_entity2.pos = tx_positions_3d(j,:);
%                 
%                 rx_entity.pos = rx_positions_3d(i,:);
%                 ris_entity.pos=ris_positions_3d(k,:);
% 
%                 af_entity.pos=af_positions_3d(k,:);
%                 direct_snr_donor(i,j)=direct_channel_snr(tx_entity1,rx_entity,ris_entity, scenario.radio_prm);
%                 direct_snr_iab(i,j)=direct_channel_snr(tx_entity2,rx_entity,ris_entity, scenario.radio_prm);
% 
%                 %disp(direct_snr(i,j,k))
%                 ris_snr_donor(i,j,k) = ris_channel_snr(tx_entity1, rx_entity, ris_entity, scenario.radio_prm);
%                 ris_snr_iab(i,j,k) = ris_channel_snr(tx_entity2, rx_entity, ris_entity, scenario.radio_prm);
% 
%                 %disp(ris_snr(i,j,k))
%                 af_snr_donor(i,j,k) = af_channel_snr(tx_entity1, rx_entity, af_entity, scenario.radio_prm);
%                 af_snr_iab(i,j,k) = af_channel_snr(tx_entity2, rx_entity, af_entity, scenario.radio_prm);
%            end
%         end
%     end
% end

for i=1:n_tp
    for j=1:n_cs
        iab_entity.pos=iab_positions_3d(j,:);
        donor_entity.pos=iab_entity.pos;
        ue_entity.pos=ue_positions_3d(i,:);
        for k=1:n_cs
            if k~=j %ris/af and iab/donor must be in different CSs
                ris_entity.pos=ris_positions_3d(k,:);
                af_entity.pos=af_positions_3d(k,:);

                ris_snr_donor_dl(i,j,k) = ris_channel_snr(donor_entity, ue_entity, ris_entity, scenario.radio_prm); %ris snr, downlink
                ris_snr_iab_dl(i,j,k) = ris_channel_snr(iab_entity, ue_entity, ris_entity, scenario.radio_prm);

                ris_snr_donor_ul(i,j,k) = ris_channel_snr(ue_entity, donor_entity, ris_entity, scenario.radio_prm); %ris snr, uplink
                ris_snr_iab_ul(i,j,k) = ris_channel_snr(ue_entity, iab_entity, ris_entity, scenario.radio_prm);

                af_snr_donor_dl(i,j,k) = af_channel_snr(donor_entity, ue_entity, af_entity, scenario.radio_prm); %af snr, downlink
                af_snr_iab_dl(i,j,k) = af_channel_snr(iab_entity, ue_entity, af_entity, scenario.radio_prm);

                af_snr_donor_ul(i,j,k) = ris_channel_snr(ue_entity, donor_entity, af_entity, scenario.radio_prm); %af snr, uplink
                af_snr_iab_ul(i,j,k) = ris_channel_snr(ue_entity, iab_entity, af_entity, scenario.radio_prm);
            end
            direct_snr_donor_dl(i,j)=direct_channel_snr(donor_entity,ue_entity,ris_entity, scenario.radio_prm); %direct snr, downlink
            direct_snr_iab_dl(i,j)=direct_channel_snr(iab_entity,ue_entity,ris_entity, scenario.radio_prm);

            direct_snr_donor_ul(i,j)=direct_channel_snr(ue_entity,donor_entity,ris_entity, scenario.radio_prm); %direct snr, uplink
            direct_snr_iab_ul(i,j)=direct_channel_snr(ue_entity,iab_entity,ris_entity, scenario.radio_prm);
            
            bh_snr_iab=direct_channel_snr(iab_entity,iab_entity,ris_entity, scenario.radio_prm); %backhaul snr
            bh_snr_don_tx=direct_channel_snr(donor_entity,iab_entity,ris_entity, scenario.radio_prm);
            bh_snr_don_rx=direct_channel_snr(iab_entity,donor_entity,ris_entity, scenario.radio_prm);
        end
    end
end
        
direct_rate_donor_dl=zeros(n_tp,n_cs); %matrices for rates
direct_rate_iab_dl=zeros(n_tp,n_cs);
ris_rate_donor_dl=zeros(n_tp,n_cs,n_cs);
ris_rate_donor_dl=zeros(n_tp,n_cs,n_cs);
af_rate_donor_dl=zeros(n_tp,n_cs,n_cs);
af_rate_iab_dl=zeros(n_tp,n_cs,n_cs);

direct_rate_donor_ul=zeros(n_tp,n_cs);
direct_rate_iab_ul=zeros(n_tp,n_cs);
ris_rate_donor_ul=zeros(n_tp,n_cs,n_cs);
ris_rate_donor_ul=zeros(n_tp,n_cs,n_cs);
af_rate_donor_ul=zeros(n_tp,n_cs,n_cs);
af_rate_iab_ul=zeros(n_tp,n_cs,n_cs);

bh_rate_iab=zeros(n_tp,n_cs);
bh_rate_donor_tx=zeros(n_tp,n_cs);
bh_rate_donor_rx=zeros(n_tp,n_cs);

direct_rate_donor_dl(:,:)=radio_prm.BW.*log2(1+10.^(direct_snr_donor_dl/10))./1e6; %downlink rates
direct_rate_iab_dl(:,:)=radio_prm.BW.*log2(1+10.^(direct_snr_iab_dl/10))./1e6;
ris_rate_donor_dl(:,:,:)=radio_prm.BW.*log2(1+10.^(ris_snr_donor_dl/10))./1e6;
ris_rate_iab_dl(:,:,:)=radio_prm.BW.*log2(1+10.^(ris_snr_iab_dl/10))./1e6;
af_rate_donor_dl(:,:,:)=radio_prm.BW.*log2(1+10.^(af_snr_donor_dl/10))./1e6;
af_rate_iab_dl(:,:,:)=radio_prm.BW.*log2(1+10.^(af_snr_iab_dl/10))./1e6;

direct_rate_donor_ul(:,:)=radio_prm.BW.*log2(1+10.^(direct_snr_donor_ul/10))./1e6; %uplink rates
direct_rate_iab_ul(:,:)=radio_prm.BW.*log2(1+10.^(direct_snr_iab_ul/10))./1e6;
ris_rate_donor_ul(:,:,:)=radio_prm.BW.*log2(1+10.^(ris_snr_donor_ul/10))./1e6;
ris_rate_iab_ul(:,:,:)=radio_prm.BW.*log2(1+10.^(ris_snr_iab_ul/10))./1e6;
af_rate_donor_ul(:,:,:)=radio_prm.BW.*log2(1+10.^(af_snr_donor_ul/10))./1e6;
af_rate_iab_ul(:,:,:)=radio_prm.BW.*log2(1+10.^(af_snr_iab_ul/10))./1e6;

bh_rate_iab(:,:)=radio_prm.BW.*log2(1+10.^(bh_snr_iab/10))./1e6; %backhaul rates
bh_rate_donor_tx(:,:)=radio_prm.BW.*log2(1+10.^(bh_snr_donor_tx/10))./1e6;
bh_rate_iab_rx(:,:)=radio_prm.BW.*log2(1+10.^(bh_snr_donor_rx/10))./1e6;

for c=1:n_cs %set diagonals to zero for reflected rates
    ris_rate_donor(:,c,c)=0;
    ris_rate_iab(:,c,c)=0;
    af_rate_donor(:,c,c)=0;
    af_rate_iab(:,c,c)=0;
end

%% airtimes calculation

%downlink airtimes
direct_airtime_dl_donor = R_dir_min./repmat(direct_rate_donor_dl,1,1,n_cs); %donor->iab
ris_airtime_dl_donor= (R_dir_min*rate_ratio)./ris_rate_donor_dl; %donor->ris->tp
sr_airtime_dl_donor = (R_dir_min*rate_ratio)./af_rate_donor_dl; %donor->sr->tp
direct_airtime_dl_iab = R_dir_min./repmat(direct_rate_iab_dl,1,1,n_cs); %iab->iab
ris_airtime_dl_iab= (R_dir_min*rate_ratio)./ris_rate_iab_dl; %iab->ris->tp
sr_airtime_dl_iab = (R_dir_min*rate_ratio)./af_rate_iab_dl; %iab->sr->tp

%uplink airtimes (rate for uplink = 0.1*R_downlink)
direct_airtime_ul_donor = 0.1*R_dir_min./repmat(direct_rate_donor_ul,1,1,n_cs); %donor->iab
ris_airtime_ul_donor= 0.1*(R_dir_min*rate_ratio)./ris_rate_donor_ul; %donor->ris->tp
sr_airtime_ul_donor = 0.1*(R_dir_min*rate_ratio)./af_rate_donor_ul; %donor->sr->tp
direct_airtime_ul_iab = 0.1*R_dir_min./repmat(direct_rate_iab_ul,1,1,n_cs); %iab->iab
ris_airtime_ul_iab= 0.1*(R_dir_min*rate_ratio)./ris_rate_iab_ul; %iab->ris->tp
sr_airtime_ul_iab = 0.1*(R_dir_min*rate_ratio)./af_rate_iab_ul; %iab->sr->tp

%set infinite airtimes to 1 in order to not select them (important outside diagonals)
ris_airtime_dl_donor(ris_airtime_dl_donor == Inf)=1;
ris_airtime_dl_iab(ris_airtime_dl_iab == Inf)=1;
ris_airtime_ul_donor(ris_airtime_ul_donor == Inf)=1;
ris_airtime_ul_iab(ris_airtime_ul_iab == Inf)=1;

%maximum downlink airtimes
max_airtime_dl_ris_donor = max(direct_airtime_dl_donor, ris_airtime_dl_donor);
max_airtime_dl_ris_iab = max(direct_airtime_dl_iab, ris_airtime_dl_iab);
max_airtime_dl_sr_donor = max(direct_airtime_dl_donor, sr_airtime_dl_donor);
max_airtime_dl_sr_iab = max(direct_airtime_dl_iab, sr_airtime_dl_iab);

max_airtime_dl_ris_donor(max_airtime_dl_ris_donor == Inf) = 0;
max_airtime_dl_ris_iab(max_airtime_dl_ris_iab == Inf) = 0;
max_airtime_dl_sr_donor(max_airtime_dl_sr_donor == Inf) = 0;
max_airtime_dl_sr_iab(max_airtime_dl_sr_donor == Inf) = 0;

max_airtime_ul_ris_donor = max(direct_airtime_ul_donor, ris_airtime_ul_donor);
max_airtime_ul_ris_iab = max(direct_airtime_ul_iab, ris_airtime_ul_iab);
max_airtime_ul_sr_donor = max(direct_airtime_ul_donor, sr_airtime_ul_donor);
max_airtime_ul_sr_iab = max(direct_airtime_ul_iab, sr_airtime_ul_iab);

%maximum uplink airtimes
max_airtime_ul_ris_donor(max_airtime_dl_ris_donor == Inf) = 1;
max_airtime_ul_ris_iab(max_airtime_dl_ris_iab == Inf) = 1;
max_airtime_ul_sr_donor(max_airtime_dl_sr_donor == Inf) = 1;
max_airtime_ul_sr_iab(max_airtime_dl_sr_donor == Inf) = 1;

max_airtime_ul_ris_donor(max_airtime_dl_ris_donor == Inf) = 1;
max_airtime_ul_ris_iab(max_airtime_dl_ris_iab == Inf) = 1;
max_airtime_ul_sr_donor(max_airtime_dl_sr_donor == Inf) = 1;
max_airtime_ul_sr_iab(max_airtime_dl_sr_donor == Inf) = 1;

channels_paolo; %provisional backhaul rates

%% variable pruning
%direct links pruning mask
direct_p_mask = repmat(direct_rate_iab,1,1,n_cs) >= R_dir_min; %since iab rates are less than donor rates, we perform pruning based on the former

%refl. links pruning
af_p_mask  = af_rate_iab >= R_dir_min*rate_ratio;
ris_p_mask = ris_rate_iab >= R_dir_min*rate_ratio;

%angles
angles_mask_ris = zeros(n_tp,n_cs,n_cs);

for r=1:n_cs
    for d=1:n_cs
        for t=1:n_tp
            angles_mask_ris(t,d,r) = max([cs_tp_angles(r,t) cs_cs_angles(r,d)]) - min([cs_tp_angles(r,t) cs_cs_angles(r,d)]) <= 2*max_angle_span;
        end
    end
end

ris_p_mask = ris_p_mask & angles_mask_ris & direct_p_mask;
af_p_mask  = af_p_mask & direct_p_mask;

% put diagonals to 0
for t=1:n_tp
    for c=1:n_cs
        ris_p_mask(t,c,c) = 0;
    end
end

if has_buildings
    for r=1:n_cs
        for d=1:n_cs
            for t=1:n_tp
                af_p_mask(t,d,r) = af_p_mask(t,d,r) & ~cs_cs_obstruction(d,r) & ~cs_tp_obstruction(d,t) & ~cs_tp_obstruction(r,t);
                ris_p_mask(t,d,r) = ris_p_mask(t,d,r) & ~cs_cs_obstruction(d,r) & ~cs_tp_obstruction(d,t) & ~cs_tp_obstruction(r,t);
            end
        end
    end
    if scenario.has_relays
        bh_p_mask = ~cs_cs_obstruction;
    end
else %bh p mask is all 1 if no obstacles
    bh_p_mask = ones(n_cs,n_cs);
end

%decativate self links
bh_p_mask = bh_p_mask - diag(diag(bh_p_mask));

%% generate instance structure
%some local variables are set as transpose in the instance structure in
%order to reflect the indexing in the model

%candidate sites and test points
instance.n_cs=n_cs;
instance.n_tp=n_tp;

%budgeting
instance.ris_budget = ris_budget;

instance.ris_price = ris_price;
instance.iab_price = iab_price;
instance.sr_price = af_price;

%access and backhaul masks
instance.bh_p_mask = bh_p_mask;
instance.acc_p_mask = ris_p_mask;
instance.sr_p_mask = af_p_mask;

%downlink and uplink demands
instance.d = ones(n_tp,1).*R_dir_min;
instance.d_ul = ones(n_tp,1).*R_dir_min*0.1;

%distances
instance.cs_tp_dist = cs_tp_distance_matrix';

%angle section
instance.cs_tp_angles = cs_tp_angles;
instance.cs_cs_angles = cs_cs_angles;
instance.smallest_angles = smallest_angles;
instance.angle_span = max_angle_span;

%sr bs panel orientation
sr_minangle=mod(cs_cs_angles+90,360);
instance.sr_minangle=sr_minangle-diag(diag(sr_minangle));

sr_maxangle=mod(cs_cs_angles-90,360);
instance.sr_maxangle=sr_maxangle-diag(diag(sr_maxangle));
%OF weight and degradation factor
instance.OF_weight = OF_weight;
instance.rate_ratio = rate_ratio;

%OF normalization constraints
instance.angle_norm = 180;
instance.length_norm = max(cs_tp_distance_matrix(:));

%max airtimes for halfduplex
instance.max_airtime_dl_ris_donor=max_airtime_dl_ris_donor;
instance.max_airtime_dl_ris_iab=max_airtime_dl_ris_iab;
instance.max_airtime_dl_sr_donor = max_airtime_dl_sr_donor;
instance.max_airtime_dl_sr_iab = max_airtime_dl_sr_iab;

instance.max_airtime_ul_ris_donor=max_airtime_ul_ris_donor;
instance.max_airtime_ul_ris_iab=max_airtime_ul_ris_iab;
instance.max_airtime_ul_sr_donor = max_airtime_ul_sr_donor;
instance.max_airtime_ul_sr_iab = max_airtime_ul_sr_iab;

%airtimes for RIS/SR sharing
instance.direct_airtime_dl_donor = direct_airtime_dl_donor;
instance.ris_airtime_dl_donor= ris_airtime_dl_donor;
instance.sr_airtime_dl_donor = sr_airtime_dl_donor;
instance.direct_airtime_dl_iab = direct_airtime_dl_iab;
instance.ris_airtime_dl_iab= ris_airtime_dl_iab;
instance.sr_airtime_dl_iab = sr_airtime_dl_iab;

instance.direct_airtime_ul_donor = direct_airtime_ul_donor;
instance.ris_airtime_ul_donor= ris_airtime_ul_donor;
instance.sr_airtime_ul_donor = sr_airtime_ul_donor;
instance.direct_airtime_ul_iab = direct_airtime_ul_iab;
instance.ris_airtime_ul_iab= ris_airtime_ul_iab;
instance.sr_airtime_ul_iab = sr_airtime_ul_iab;

% instance.direct_rate_donor = direct_rate_donor;
% instance.direct_rate_iab = direct_rate_iab;
% instance.ris_rate_donor = ris_rate_donor;
% instance.ris_rate_iab = ris_rate_iab;
% instance.sr_rate_donor = af_rate_donor;
% instance.sr_rate_iab = af_rate_iab;

% instance.c_iab = channel.backhaul_rates; %provisional BH rates while still waiting
% instance.c_don_tx = channel.backhaul_rates;
% instance.c_don_rx=channel.backhaul_rates;

instance.c_iab = bh_rate_iab; %provisional BH rates while still waiting
instance.c_don_tx = bh_rate_don_tx;
instance.c_don_rx=bh_rate_don_rx;

instance.output_filename = [num2str(dataname) '.m'];
%% workspace saving
save([instance_folder dataname]);

end