%% campus
% x_left_limit = 517730;
% x_right_limit = 517970;
%
% y_down_limit = 5035950;
% y_up_limit = 5036220;

%% piazza
% x_left_limit = 517600;
% x_right_limit = 517730;
%
% y_down_limit = 5035800;
% y_up_limit = 5036290;

%% canyon su
% x_left_limit = 517730;
% x_right_limit = 518060;
%
% y_down_limit = 5036220;
% y_up_limit = 5036340;

%% whole
x_left_limit = 517600;
x_right_limit = 518060;

y_up_limit = 5036340;
y_down_limit = 5035900;

%% filter

filtered_b = Buildings;
b_count = 1;
keep_mask = true(numel(Buildings),1);

x_offset = inf;
y_offset = inf;

for bb=1:numel(Buildings) % for each building
    % search inside edges and see if any is outside the limits
    bld = Buildings{bb};
    for ed = 1:size(bb,1)
        if bld(ed,1) < x_left_limit || bld(ed,1) > x_right_limit ||...
                bld(ed,2) < y_down_limit || bld(ed,2) > y_up_limit
            keep_mask(bb) = false;
            x_offset = min([x_offset, bld(ed,1)]);
            y_offset = min([y_offset, bld(ed,2)]);
        end
    end
end

filtered_b = Buildings(keep_mask);

%% translate all vertices

% for bb=1:numel(filtered_b)
%     new_vertices_x = filtered_b{bb}(:,1) - x_offset;
%     new_vertices_y = filtered_b{bb}(:,1) - y_offset;
%     filtered_b{bb} = [new_vertices_x new_vertices_y];
% end

%% plot result

polygons = cell(1,length(filtered_b));

figure
for i = 1:length(filtered_b)

    polygons{1,i} = polyshape(filtered_b{1,i}(:,1),filtered_b{1,i}(:,2));
    %     patch( Params.Buildings{1,i}(:,1),  Params.Buildings{1,i}(:,2), [217, 217, 217]/255);
    %     hold on

    plot(polygons{1,i},'HandleVisibility','off')
    hold on
end

%% plot result translated

translated_polygons = cell(1,length(filtered_b));

f1=figure();
for i = 1:length(filtered_b)

    temp_p = polyshape(filtered_b{1,i}(:,1),filtered_b{1,i}(:,2));
    translated_polygons{1,i} = translate(temp_p, [-x_offset -y_offset]);
    %     patch( Params.Buildings{1,i}(:,1),  Params.Buildings{1,i}(:,2), [217, 217, 217]/255);
    %     hold on

    plot(translated_polygons{1,i},'HandleVisibility','off')
    hold on
end
dcm=datacursormode(f1);

dcm.SnapToDataVertex = 'off';

%% plot result translated scaled

translated_scaled_polygons = cell(1,length(filtered_b));

f1=figure();
for i = 1:length(filtered_b)

    temp_p = polyshape(filtered_b{1,i}(:,1),filtered_b{1,i}(:,2));
    [cx, cy] = centroid(temp_p);
    temp_p = scale(temp_p, 0.98,[cx cy]);
    translated_scaled_polygons{1,i} = translate(temp_p, [-x_offset -y_offset]);
    %     patch( Params.Buildings{1,i}(:,1),  Params.Buildings{1,i}(:,2), [217, 217, 217]/255);
    %     hold on

    plot(translated_scaled_polygons{1,i},'HandleVisibility','off')
    hold on
end
dcm=datacursormode(f1);

dcm.SnapToDataVertex = 'off';


%% handpicked candidate sites
corner_positions = [...
    [465.192151069641,462.948242476210]
    [479.209403448331,428.481084967963]
    [479.031313353335,449.933521206491]
    [526.120201178943,485.596287021413]
    [697.566177504486,394.075249177404]
    [478.826540515001,395.384033158422]
    [526.164188533672,395.940666349605]
    [596.631061165128,496.784791681916]
    [530.229814057995,450.356714216992]
    [616.205887086398,396.675133901648]
    [530.408047432546,428.915388608351]
    [549.080042588292,395.783691786230]
    [606.896597716434,164.454632627778]
    [577.947330046096,164.149798749946]
    [568.808266668522,162.201750683598]
    [499.599949028634,161.638207861222]
    [591.011281511281,321.712290819734]
    [549.757772203186,338.936996481381]
    [553.105621505994,318.771214808337]
    [525.403565191606,314.381781782024]
    [541.206917811360,232.025694399141]
    [496.979876334022,231.066725669429]
    [477.132435959531,158.007235431112]
    [477.008077537117,234.654047274031]
    [483.164548635541,263.045823677443]
    [482.862869186210,294.996621863917]
    [480.851049603662,315.399534039199]
    [656.714754340937,170.074265191332]
    [656.068537331361,204.668189939111]
    [659.567623997747,251.883565801196]
    [658.508210386965,275.199908181094]
    [622.377671677561,181.611230325215]
    [622.008947736293,220.390999940224]
    [619.918115369510,240.926958951168]
    [619.915912778117,318.239744176157]
    [624.326352237782,372.068019250408]
    [653.762671284960,428.467637684196]
    [652.869750513753,497.356698451564]
    [627.489589226490,132.339652055874]
    [608.419234775705,132.140709907748]
    [596.506400006299,127.129515365697]
    [552.997837761359,122.286079852842]
    [505.249320140400,123.658900479786]
    [464.647780966538,125.576779762283]
    [413.312944577541,125.442604543641]
    [400.483545370167,126.650653149001]
    [357.245519670658,146.126297556795]
    [325.441005891014,152.213801432401]
    [291.038115545816,156.783246804960]
    [289.893141638488,224.993905324489]
    [416.758541227027,167.358325913548]
    [416.628137005959,227.317291433923]
    [419.056029305095,255.965098729357]
    [418.642096213007,300.091871083714]
    [455.625781977433,314.028179814108]
    [416.050997994083,320.893116539344]
    [414.733684287465,386.003668351099]
    [454.137626095966,395.158509363420]
    [442.612482999626,485.237110660411]
    [287.710515589395,406.743344268762]
    [266.980433846533,338.138020687737]
    [286.611926797195,338.681906563230]
    [313.274974738248,423.568649042398]
    [358.385087541887,424.084429659881]
    [357.293678201444,500.772004201077]
    [457 240]];

zero_deg_ris = [[530.321350097656,439.345275878906]
    [509.499450683594,475.532928466797]
    [627.689697265625,114.007484436035]
    [625.407775878906,171.574264526367]
    [622.194458007813,200.897842407227]
    [619.837036132813,253.341354370117]
    [620.063110351563,301.955718994141]
    [624.175231933594,388.344055175781]
    [562.928771972656,342.822723388672]
    [570.589538574219,372.148437500000]
    [477.017791748047,228.661361694336]
    [483.006408691406,279.583801269531]
    [358.248443603516,433.535491943359]
    [357.603240966797,478.636260986328]
    [357.261901855469,149.121078491211]
    [290.760864257813,166.521102905273]
    [290.331298828125,193.136581420898]
    [290.017669677734,214.701629638672]
    [288.053405761719,360.870330810547]
    [287.802917480469,396.357025146484]];

ninenty_deg_ris = [[503.209716796875,450.133392333984]
    [592.383117675781,396.455993652344]
    [498.060943603516,395.576416015625]
    [433.725677490234,386.546356201172]
    [599.047241210938,321.786682128906]
    [534.938049316406,288.521026611328]
    [593.470458984375,220.181045532227]
    [517.643981933594,242.703826904297]
    [439.056823730469,233.311294555664]
    [461.909759521484,297.128417968750]
    [716.212036132813,393.112487792969]
    [688.763366699219,200.341827392578]
    [439.446319580078,120.513824462891]
    [616.483642578125,132.224792480469]
    [523.687316894531,127.720237731934]
    [340.435180664063,152.454803466797]
    [693.544,308.600]];
% [517.929,242.707]
% [444.029, 233.314]
% [450.682, 294.647]
% [504.834533691406,450.146820068359]
% [598.162475585938,396.503997802734]
% [560.930114746094,395.922119140625]
% [495.916870117188,395.555541992188]
% [434.886199951172,386.579833984375]];

oneigthy_deg_ris = [[659.010314941406,264.149291992188]
    [656.414672851563,186.140380859375]
    [697.637512207031,389.939819335938]
    [653.640380859375,441.804382324219]
    [653.305725097656,476.375183105469]
    [609.376831054688,376.195739746094]
    [450.682434082031,294.646484375000]
    [553.284790039063,309.084289550781]
    [553.668518066406,243.489593505859]
    [526.441528320313,276.684478759766]
    [470.184173583984,460.145599365234]
    [479.108428955078,440.643890380859]
    [418.364837646484,199.039779663086]
    [418.853668212891,277.535888671875]
    [415.403594970703,352.891906738281]];

twoseventy_deg_ris = [[563.554992675781,236.112777709961]
    [599.571594238281,244.904876708984]
    [615.083007812500,371.979614257813]
    [554.886413574219,338.999053955078]
    [531.313598632813,269.739837646484]
    [464.275054931641,259.568237304688]
    [515.770568847656,314.278656005859]
    [468.605743408203,314.147857666016]
    [436.963256835938,321.107055664063]
    [662.851379394531,428.547607421875]
    [574.170532226563,496.635620117188]
    [504.787200927734,428.698059082031]
    [696.756347656250,447.176177978516]
    [716.302429618081,387.874285068363]
    [680.179321289063,251.738647460938]
    [595.389343261719,164.333465576172]
    [541.091308593750,162.009048461914]
    [443.607482910156,167.419036865234]
    [275.600219726563,338.376770019531]
    [367.935058593750,424.089141845703]
    [301.646942138672,424.303649902344]
    [335.801055908203,429.229248046875]
    [430.575 256]];

%% drop tp

tp_x_offset = 292;
tp_y_offset = 127;

tp_x_width = 730 - tp_x_offset;
tp_y_width = 500 - tp_y_offset;

n_tp = 60;
tp_positions = zeros(n_tp,2);
tp_count = 1;

for t = 1:1e6
    t_x = rand()*tp_x_width + tp_x_offset;
    t_y = rand()*tp_y_width + tp_y_offset;
    discard = false;
    % check if in polygon
    for pol=1:numel(translated_polygons)
        if inpolygon(t_x,t_y,translated_polygons{pol}.Vertices(:,1),translated_polygons{pol}.Vertices(:,2))
            % discard this tp
            discard = true;
            break % break the polygon search loop
        end
    end
    if ~discard
        tp_positions(tp_count,:) = [t_x t_y];
        tp_count = tp_count + 1;
        if tp_count > n_tp
            break;
        end
    end
end
%% good samples of tp positions

tp_positions_sample_1 = [
    466.516146062969	308.939058168970
    562.743902159848	153.113727787524
    354.497308818353	371.026533871116
    387.623982574920	171.436209439154
    310.894050222308	188.753201542358
    515.864385777397	450.490971030298
    627.622203323312	177.336694763492
    320.435256797536	377.821966925875
    503.206633036467	311.790881588989
    429.305845147145	247.665861662591
    329.195844946449	204.221893065188
    434.642410572160	160.544771141803
    646.920000566519	276.035497563821
    579.027663430238	338.432624913706
    293.367376589111	369.954102400404
    643.211802649104	336.314216492026
    302.864191569703	422.990582723923
    593.586994845462	352.255614420169
    461.484141231712	151.444681112876
    729.383904064861	373.569373958123
    392.377467277873	161.410956680207
    397.548654015679	463.658484097614
    387.198419051722	305.861986919296
    409.243923825227	285.102459278445
    642.103822977556	474.752685670562
    497.736964646553	241.251163503304
    484.444862603765	241.458795174319
    412.455682584690	178.752775045947
    364.947791286918	311.242377701507
    357.032597459848	186.858741005466
    449.031559848470	160.740798091529
    637.278526738659	293.837699086416
    378.098093678033	280.412527022863
    395.233692344349	228.532628420277
    519.856138823433	300.118851825027
    521.306021265720	252.630916026463
    499.488003207416	405.579129833341
    585.441966525499	423.755815873731
    411.374020166090	232.900343239425
    709.530366395811	396.510420853598
    700.081421089842	337.440880732002
    728.322004546768	417.747260260750
    500 145
    465 135
    530 145
    580 140
    620 140
    515 275
    500 265
    680 240
    670 230
    640 230
    590 470
    620 410
    620 440
    320 415
    330 400
    ];

%% filter

area = 'whole';

switch area
    case 'campus'
        x_left_limit = 420;
        x_right_limit = 616;
        y_down_limit = 178;
        y_up_limit = 386;
        donor_position = [482.862869186210,294.996621863917];
    case 'piazza'
        x_left_limit = 275;
        x_right_limit = 419;

        y_down_limit = 145;
        y_up_limit = 434;
        donor_position = [418.642096213007,300.091871083714];
    case 'bassini'
        x_left_limit = 275;
        x_right_limit = 800;
        y_down_limit = 388.1;
        y_up_limit = 550;
        donor_position = [479.209403448331,428.481084967963];
    case 'golgi'
        x_left_limit = 600;
        x_right_limit = 800;
        y_down_limit = 166;
        y_up_limit = 396;
        donor_position =[659.567623997747,251.883565801196];
    case 'celoria'
        x_left_limit = 417;
        x_right_limit = 800;
        y_down_limit = 50;
        y_up_limit = 168.9;

        donor_position = [552.997837761359,122.286079852842];
    case 'whole'
        x_left_limit = 0;
        x_right_limit = 1e3;
        y_down_limit = 0;
        y_up_limit = 1e3;
end

% x_left_limit = x_left_limit - x_offset;
% x_right_limit = x_right_limit - x_offset;
% y_up_limit = y_up_limit - y_offset;
% y_down_limit = y_down_limit - y_offset;



%% scatter with limits

cp_filtered = corner_positions;
cp_filtered = cp_filtered(cp_filtered(:,1) >= x_left_limit & cp_filtered(:,1)<=x_right_limit & cp_filtered(:,2) >= y_down_limit & cp_filtered(:,2) <= y_up_limit,:);

zero_ris = zero_deg_ris;
zero_ris = zero_ris(zero_ris(:,1) >= x_left_limit & zero_ris(:,1)<=x_right_limit & zero_ris(:,2) >= y_down_limit & zero_ris(:,2) <= y_up_limit,:);

ninenty_ris = ninenty_deg_ris;
ninenty_ris = ninenty_ris(ninenty_ris(:,1) >= x_left_limit & ninenty_ris(:,1)<=x_right_limit & ninenty_ris(:,2) >= y_down_limit & ninenty_ris(:,2) <= y_up_limit,:);

oneigthy_ris = oneigthy_deg_ris;
oneigthy_ris = oneigthy_ris(oneigthy_ris(:,1) >= x_left_limit & oneigthy_ris(:,1)<=x_right_limit & oneigthy_ris(:,2) >= y_down_limit & oneigthy_ris(:,2) <= y_up_limit,:);

twoseventy_ris = twoseventy_deg_ris;
twoseventy_ris = twoseventy_ris(twoseventy_ris(:,1) >= x_left_limit & twoseventy_ris(:,1)<=x_right_limit & twoseventy_ris(:,2) >= y_down_limit & twoseventy_ris(:,2) <= y_up_limit,:);

tp_filt = tp_positions_sample_1;
tp_filt = tp_filt(tp_filt(:,1) >= x_left_limit & tp_filt(:,1)<=x_right_limit & tp_filt(:,2) >= y_down_limit & tp_filt(:,2) <= y_up_limit,:);

%donor_id = find(cp_filtered == donor_position);
%donor_id = donor_id(1);

hold on
scatter(cp_filtered(:,1), cp_filtered(:,2),'o','filled','red','DisplayName','Node CS');
scatter(zero_ris(:,1),zero_ris(:,2),'o','filled','blue','DisplayName','RIS CS');
scatter(ninenty_ris(:,1),ninenty_ris(:,2),'o','filled','blue','HandleVisibility','off');
scatter(oneigthy_ris(:,1),oneigthy_ris(:,2),'o','filled','blue','HandleVisibility','off');
scatter(twoseventy_ris(:,1),twoseventy_ris(:,2),'o','filled','blue','HandleVisibility','off');
scatter(tp_filt(:,1),tp_filt(:,2),'o','filled','green','DisplayName','Test Points');
scatter(donor_position(1), donor_position(2),'o','filled','k','DisplayName','Donor');

bs_positions = cp_filtered;
ris_positions = [zero_ris; ninenty_ris; oneigthy_ris; twoseventy_ris];
ris_orientation_clockwise = [zeros(size(zero_ris,1),1);
    (-pi/2).*ones(size(ninenty_ris,1),1);
    pi.*ones(size(oneigthy_ris,1),1);
    (pi/2).*ones(size(twoseventy_ris,1),1)];
ris_orientation_counterclock = [zeros(size(zero_ris,1),1);
    (pi/2).*ones(size(ninenty_ris,1),1);
    pi.*ones(size(oneigthy_ris,1),1);
    (-pi/2).*ones(size(twoseventy_ris,1),1)];

%% scatter
hold on
scatter(corner_positions(:,1),corner_positions(:,2),'o','filled','red');
scatter(zero_deg_ris(:,1),zero_deg_ris(:,2),'o','filled','blue');
scatter(ninenty_deg_ris(:,1),ninenty_deg_ris(:,2),'o','filled','blue');
scatter(oneigthy_deg_ris(:,1),oneigthy_deg_ris(:,2),'o','filled','blue')
scatter(twoseventy_deg_ris(:,1),twoseventy_deg_ris(:,2),'o','filled','blue');
scatter(tp_positions_sample_1(:,1),tp_positions_sample_1(:,2),'o','filled','green');


%% channels init

addpath('utils_radio');

Params.Config.Check_Static_Blockage = true;
% Params.Config.Check_Static_Blockage = false;
%Params.Config.Check_Dynamic_Blockage = true;
Params.Config.Check_Dynamic_Blockage = false;

% Define Communication medium
Params.comm = Set_CommParams(28e9,200e6,'NoShadowing');


% Define Blockage params
% prm.Blockage = Set_BlockageParams(28e9,3,3,2,2,2e-3,'RunOnDemand');
% Params.Blockage = Set_BlockageParams(28e9,6,3,2,2,2e-3,'Median','Interpolate');
Params.Blockage = Set_BlockageParams(28e9,6,3,2,2,2e-3,'Median','Interpolate');
% AA = prm.Blockage.Handle(100,prm.Blockage);
% disp(prm.Blockage.Handle(50,prm.Blockage))

Address = [pwd,'/Blockage_Data'];
Name = 'scaled_translated_leonardo.mat';
Params.Blockage.Buildings = translated_scaled_polygons;
%[Params.Blockage]= Set_Buildings(Address,Name,Params.Blockage);

% Scenarios
Scenario.Tx2Rx = 'UMi';
Scenario.Tx2AF = 'UMi';
Scenario.AF2Rx = 'UMi';

Params.RIS = Network_Entity('RIS',[0,0,0], Params.comm,'Orientation',-pi,'Dir','true','Policy','Anomalous','Nh',100,'Nv',100);

% Define AF
Params.AF = Network_Entity('AF',[0,0,0], Params.comm,'Orientation','Optimum','Type','Option2');

%% channels compute

% direct bh rates
n_bs = size(bs_positions,1);
n_ris = size(ris_positions,1);
n_tp = size(tp_filt,1);

bh_rates = zeros(n_bs,n_bs);
bh_block_mask = false(n_bs,n_bs);

ris_rates = zeros(n_tp,n_bs,n_ris);
src_block_mask = false(n_tp,n_bs,n_ris);

direct_rates = zeros(n_tp,n_bs);
direct_block_mask = false(n_tp,n_bs);

% bh link
for c=1:n_bs
    for d=1:n_bs
        if c==d
            continue;
        end
        tx_2d_pos = bs_positions(c,:);
        rx_2d_pos = bs_positions(d,:);
        if c==donor_id
            Params.Tx = Network_Entity('BS',[tx_2d_pos,7],Params.comm,'Type','Donor','Orientation',0);
            Params.Rx = Network_Entity('BS',[rx_2d_pos,7],Params.comm,'Type','IAB','Orientation',0);
        elseif d==donor_id
            Params.Tx = Network_Entity('BS',[tx_2d_pos,7],Params.comm,'Type','IAB','Orientation',0);
            Params.Rx = Network_Entity('BS',[rx_2d_pos,7],Params.comm,'Type','Donor','Orientation',0);
        else
            Params.Tx = Network_Entity('BS',[tx_2d_pos,7],Params.comm,'Type','IAB','Orientation',0);
            Params.Rx = Network_Entity('BS',[rx_2d_pos,7],Params.comm,'Type','IAB','Orientation',0);
        end
        [SNR,Blockage] = Compute_Channel_Direct(Params,Scenario);
        bh_rates(c,d) = Params.comm.BW*1e-6*log2(1+10^(0.1.*SNR.DL));
        bh_block_mask(c,d) = Blockage.Direct.PB; % true if blocked
    end
end

% bs-ue link and ris link
for t=1:n_tp
    for d=1:n_bs
        tx_2d_pos = bs_positions(d,:);
        rx_2d_pos = tp_filt(t,:);

        % direct bs ue link
        if d==donor_id
            Params.Tx = Network_Entity('BS',[tx_2d_pos,7],Params.comm,'Type','Donor','Orientation',0);
        else
            Params.Tx = Network_Entity('BS',[tx_2d_pos,7],Params.comm,'Type','IAB','Orientation',0);
        end

        Params.Rx = Network_Entity('UE',[rx_2d_pos 1.5], Params.comm,'Orientation','Optimum','Nh',2,'Nv',2,'Type','Class2');
        [SNR,Blockage] = Compute_Channel_Direct(Params,Scenario);
        direct_rates(t,d) = Params.comm.BW*1e-6*log2(1+10^(0.1.*SNR.DL));
        direct_block_mask(t,d) = Blockage.Direct.PB; % true if blocked
        %         disp(Params.comm.BW*1e-6*log2(1+10^(0.1.*SNR.DL)));
        %         disp(Blockage.Direct.PB);
        %         disp('__');
        % ris links
        if Blockage.Direct.PB % if the drect comm is blocked we skip this src
            ris_rates(t,d,:) = zeros(1,n_ris);
            src_block_mask(t,d,:)= true(1,n_ris);
        else
            for r=1:n_ris
                %                 if r==2 && t==6 && d==5
                %                     disp('d');
                %                 end

                % first compute the angles and check if they're inside FOV
                ris_2d_pos = ris_positions(r,:);
                ris_orient = ris_orientation_clockwise(r);
                Params.RIS = Network_Entity('RIS',[ris_2d_pos, 3], Params.comm,'Orientation',ris_orient,'Dir','true','Policy','FF_Assympt','Nh',100,'Nv',100);
                relative_rx_pos = rx_2d_pos - ris_2d_pos;
                relative_tx_pos = tx_2d_pos - ris_2d_pos;
                fov_halved = deg2rad(120)/2;%Params.RIS.Horizontal_FOV/2;
                tx_angle = atan2(relative_tx_pos(2),relative_tx_pos(1));
                rx_angle = atan2(relative_rx_pos(2),relative_rx_pos(1));
                src_in_fov = (tx_angle >= ris_orientation_counterclock(r)-fov_halved & tx_angle <= ris_orientation_counterclock(r)+fov_halved)...
                    & (rx_angle >= ris_orientation_counterclock(r)-fov_halved & rx_angle <= ris_orientation_counterclock(r)+fov_halved);

                if src_in_fov
                [SNR,Blockage] = Compute_Channel_RIS(Params,Scenario);
                ris_rates(t,d,r) = Params.comm.BW*1e-6*log2(1+10^(0.1.*SNR.RIS));
                src_block_mask(t,d,r) = Blockage.RIS.PB; % true if blocked
                if ~src_block_mask(t,d,r)
                    %plot([ris_positions(r,1) tp_filt(t,1)],[ris_positions(r,2) tp_filt(t,2)],'k', 'HandleVisibility','off');
                end
                else
                    ris_rates(t,d,r) = 0;
                    src_block_mask(t,d,r) = true; % true if blocked
                end
            end
        end
    end
end
%% plot available links
% bh links
first = 1;
for c=1:n_bs
    for d=1:n_bs
        if bh_block_mask(c,d) == 0
            if first
                plot([bs_positions(c,1) bs_positions(d,1)],[bs_positions(c,2) bs_positions(d,2)],'k', 'DisplayName', 'BH Link');
                first = 0;
            else
                plot([bs_positions(c,1) bs_positions(d,1)],[bs_positions(c,2) bs_positions(d,2)],'k', 'HandleVisibility','off');
            end
        end
    end
end
%% ue-bs links
first = 1;
for c=1:n_bs
    for t=1:n_tp
        if direct_block_mask(t,c) == 0
            if first
                plot([bs_positions(c,1) tp_filt(t,1)],[bs_positions(c,2) tp_filt(t,2)],'k', 'DisplayName', 'BH Link');
                first = 0;
            else
                plot([bs_positions(c,1) tp_filt(t,1)],[bs_positions(c,2) tp_filt(t,2)],'k', 'HandleVisibility','off');
            end
        end
    end
end
%% src links
first = 1;
for c=1:n_bs
    for t=1:n_tp
        for r=1:n_ris
            if ris_rates(t,c,r)>0
                if first
                    plot([ris_positions(r,1) tp_filt(t,1)],[ris_positions(r,2) tp_filt(t,2)],'k', 'DisplayName', 'BH Link');
                    first = 0;
                else
                    plot([ris_positions(r,1) tp_filt(t,1)],[ris_positions(r,2) tp_filt(t,2)],'k', 'HandleVisibility','off');
                end
            end%
        end
    end
end

%% save
save(['leonardo_subareas/' area '_data'],'bs_positions','ris_positions','ris_orientation_clockwise','tp_filt',...
    "direct_rates","direct_block_mask","bh_rates","bh_block_mask","src_block_mask","ris_rates","donor_id","donor_position");