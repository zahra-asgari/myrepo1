function [n_tp,n_cs,cs_cs_distance_matrix, cs_tp_distance_matrix,...
    cs_positions, tp_positions, pruning_struct, errorDonor] = generateFreeCSTPPositions(scenario,PLOT_SITE,Blockage,figure_style, cache_found, cache_path)
%GENERATE_CS_TP_POSITIONS This function generates the tp and cs positions
%(and distances) according to the chosen policy and scenario

if nargin == 3
    cache_found = false;
    save_to_cache = false;
    figure_style = [];
elseif nargin == 4
    cache_found = false;
    save_to_cache = false;
elseif nargin <3
    error('Not enough input arguments');
else
    save_to_cache = true;
end
errorDonor = 0;
pl=0;
% unpack scenario
v2struct(scenario.site);
clear size;
rng(scenario.rng_seed);
center = Blockage.site_center;

cs_cs_distance_matrix = [];
cs_tp_distance_matrix = [];
pruning_struct = [];

switch generation_policy
    case 'uniform'
        n_cs = uniform_n_cs;
        n_tp = uniform_n_tp;
    case 'poisson'
        n_cs = poissrnd(cs_density*site_area);
        n_tp = poissrnd(tp_density*site_area);
    case 'adhoc'
        
    otherwise
        error('Unrecognized generation policy in instance generation')
end

if ~cache_found
    
    %gestire con cicli for e while come nella selezione della cella, da far girare per i CS e TP
    
    switch site_shape
        case 'hexagonal'
            % first check if width equals height, otherwise, since ethe
            % hexagon is expected to have equal sides, some parts of it
            % might fall outside of the planning area
            assert(site_width == site_height, 'width must equal height, otherwise, since the hexagon is expected to have equal sides, some parts of it might fall outside of the planning area');
            % we build an hexagon contained in the rectangular area
            % in particualar, we list the vertices counterclock-wise
            % starting from the lower left vertex
            site_polygon = nsidedpoly(6,'Center',center,'SideLength',site_width/2);
            % %Let's split the whole hexagonal cell in 7 equivalent areas
            % %with different shape.
            % n_sectors = 7;
            % core_area = area(site_polygon)/n_sectors;
            % core_side = sqrt((2*core_area)/(3*sqrt(3)));
            % core_polygon = nsidedpoly(6,'Center',center,'SideLength',core_side);
            % core_polygon = rotate(core_polygon,-30,center);
            % %draw the 6 triangles in every cell to istrubute sites evenly;
            % % for i=1:6
            % %     l = [i i+1];
            % %     if i == 6
            % %         l = [i 1];
            % %     end
            % %     tr(i) = polyshape([site_polygon.Vertices(l,:);center]);
            % %     plot(tr(i));
            % %     hold on;
            % % end
            % 
            % for i=0:5
            %     l = mod(i:i+2,6);
            %     vertices = [mean(site_polygon.Vertices(l(1:2)+1,:));site_polygon.Vertices(l(2)+1,:); mean(site_polygon.Vertices(l(2:3)+1,:)); core_polygon.Vertices(l(2:-1:1)+1,:); center];
            %     spl(i+1) = polyshape(vertices);
            %     % plot(spl(i+1));
            %     % axis equal
            %     % hold on;
            % end
            % spl(end+1) = core_polygon;
            % plot(spl(end));
            [~,cs_positions] = freeCoords(max_pregen_cs,center,site_polygon.Vertices,site_width,Blockage);
            [siteBuildings,tp_positions] = freeCoords(max_pregen_tp,center,site_polygon.Vertices,site_width,Blockage);
            % load("cache/containment_for_tests/70cdb5199bfc131b164dada8792e2990.mat","cs_positions","tp_positions");
            % cs_positions = cs_positions(2:26,:);
            % up until now, we have kept in memory all the buildings if the
            % sector in which the cell is, and others if they're close to
            % the border of one or more of them.

            % we have all the CSs and TPs not overlapping with buildings
            % inside the site, now we filter out all the ones that were
            % randomly placed in unreachable places
            n = numel(siteBuildings);
            pv = [];
            for b=1:n
                xy = reformat_building(siteBuildings(b).geometry.coordinates,'loop');
                z = siteBuildings(b).properties.UN_VOL_AV;
                pv=[pv;xy repmat([z b],[size(xy,1),1]); NaN NaN NaN NaN];
            end
            if not(isempty(pv))
                map = polyshape(pv(:,1:2));
                % free_area=zeros(n_sectors,1);
                % for i=1:n_sectors
                %     free_area(i) = area(subtract(spl(i),map))/area(spl(i));
                % end
            else
                map = polyshape.empty;
                % free_area = ones(n_sectors,1);
            end
            [~,fsi] = free_space_index(map,site_polygon,Blockage,site_width);
            if fsi > 50
                disp(['Free space index is ' num2str(fsi) ', out of range']);
                errorDonor=1;
                return;
                
            else
                disp(['Free space index is ' num2str(fsi) ', OK']);
            end
            %cs_per_sector = spread_points(free_area,n_cs,(1:n_sectors),n_sectors);
            % tp_per_sector = spread_points(free_area,n_tp,(1:n_sectors),n_sectors);
            
            pruning_struct.bh = zeros(size(cs_positions,1));
            pruning_struct.ref1 = zeros(size(cs_positions,1));
            link_num = 2*(size(cs_positions,1)-1);
            link_cs = zeros(link_num,3);
            %bh and ref1 weight for CSs
            for c=1:size(cs_positions,1)
                counter = 0; %use counter to skip self-link in whatever position of the vector it is
                for d=1:size(cs_positions,1)
                    if c~=d
                        counter = counter +1;
                        link_cs(2*counter-1:2*counter,1:2) = [cs_positions(c,1) cs_positions(c,2);...
                            cs_positions(d,1) cs_positions(d,2)];
                    end
                end
                link_cs(:,3)=repmat(scenario.radio.iab_height,[link_num,1]);
                vect = ~check_vector_obstruction(pv,link_cs);
                vect1 = vect(1:c-1);
                vect2 = vect(c:end);
                vect = [vect1,0,vect2];
                pruning_struct.bh(c,:) = vect;
                link_cs(:,3)=repmat([scenario.radio.iab_height;scenario.radio.ris_height],[link_num/2,1]);
                vect = ~check_vector_obstruction(pv,link_cs);
                vect1 = vect(1:c-1);
                vect2 = vect(c:end);
                vect = [vect1,0,vect2];
                pruning_struct.ref1(c,:) = vect;
                % disp(c);
            end
            %filter out CSs which cannot be reached by any of the other CSs            
            reachable_s = find(sum(pruning_struct.bh));
            cs_positions = cs_positions(reachable_s,:);
            pruning_struct.ref1 = pruning_struct.ref1(reachable_s,reachable_s);
            pruning_struct.bh = pruning_struct.bh(reachable_s,reachable_s);

            if fixed_donor_position
                cs_positions = [cs_positions; (center(1) - site_width/2) center(2)];
                link_num = 2*(size(cs_positions,1)-1);
                link_cs = zeros(link_num,3);
                counter = 0; %use counter to skip self-link in whatever position of the vector it is
                for d=1:size(cs_positions,1)
                    if d~=size(cs_positions,1)
                        counter = counter +1;
                        link_cs(2*counter-1:2*counter,1:2) = [cs_positions(end,1) cs_positions(end,2);...
                            cs_positions(d,1) cs_positions(d,2)];
                    end
                end
                link_cs(:,3)=repmat([scenario.radio.donor_height;scenario.radio.ris_height],[link_num/2,1]);
                % vect = ~check_vector_obstruction(pv,link_cs)*(max_pregen_cs/10);
                vect = ~check_vector_obstruction(pv,link_cs);

                pruning_struct.ref1(end+1,:) = vect;
                pruning_struct.ref1(:,end+1) = [vect'; 0];
                link_cs(:,3)=repmat([scenario.radio.donor_height;scenario.radio.iab_height],[link_num/2,1]);
                %vect = ~check_vector_obstruction(pv,link_cs)*(max_pregen_cs/10);
                vect = ~check_vector_obstruction(pv,link_cs);
                pruning_struct.bh(end+1,:) = vect;
                pruning_struct.bh(:,end+1) = [vect'; 0];
                
                spt_cm = not(pruning_struct.bh == 0);
                dg = graph(spt_cm);            
                bins = conncomp(dg);
                reachable = find(bins==bins(end));
                cs_positions = cs_positions(reachable,:);
                pruning_struct.ref1 = pruning_struct.ref1(reachable,reachable);
                pruning_struct.bh = pruning_struct.bh(reachable,reachable);
                
                %TODO find if some CSs must be selected to form a
                %connected component big enough in order to avoid doing it
                %later and reduce solution space

                if size(cs_positions,1) <= n_cs

                    disp('Too few CSs survived the connected component test')
                    errorDonor = 1;
                    return;

                else
                    n_cs = n_cs + 1;
                    %now let's count also the Donor since all the remaining
                    %CSs are in the same connected component as him
                end

                 %dir and ref2 weights for CSs and TPs
                pruning_struct.dir = zeros(size(cs_positions,1),size(tp_positions,1));
                pruning_struct.ref2 = zeros(size(cs_positions,1),size(tp_positions,1));
                link_num = 2*size(tp_positions,1);
                link_tp = zeros(link_num,3);
                for c=1:size(cs_positions,1)
                    for t=1:size(tp_positions,1)
                        link_tp(2*t-1:2*t,1:2) = [cs_positions(c,1) cs_positions(c,2);...
                            tp_positions(t,1) tp_positions(t,2)];
                    end
                    if c < size(cs_positions,1)
                        link_tp(:,3)=repmat([scenario.radio.iab_height;scenario.radio.ue_height],[link_num/2,1]);
                        pruning_struct.dir(c,:) = ~check_vector_obstruction(pv,link_tp);
                        link_tp(:,3)=repmat([scenario.radio.ris_height;scenario.radio.ue_height],[link_num/2,1]);
                        pruning_struct.ref2(c,:) = ~check_vector_obstruction(pv,link_tp);
                        % disp(c);
                    else

                        link_tp(:,3)=repmat([scenario.radio.donor_height;scenario.radio.ue_height],[link_num/2,1]);
                        % pruning_struct.dir(c,:) = ~check_vector_obstruction(pv,link_tp)*(max_pregen_cs/10);
                        pruning_struct.dir(c,:) = ~check_vector_obstruction(pv,link_tp);
                        pruning_struct.ref2(c,:) = zeros(1,size(tp_positions,1));
                    end
                end          
            else
                %dir and ref2 weights for CSs and TPs
                pruning_struct.dir = zeros(size(cs_positions,1),size(tp_positions,1));
                pruning_struct.ref2 = zeros(size(cs_positions,1),size(tp_positions,1));
                link_num = 2*size(tp_positions,1);
                link_tp = zeros(link_num,3);
                for c=1:size(cs_positions,1)
                    for t=1:size(tp_positions,1)
                        link_tp(2*t-1:2*t,1:2) = [cs_positions(c,1) cs_positions(c,2);...
                            tp_positions(t,1) tp_positions(t,2)];
                    end

                    link_tp(:,3)=repmat([scenario.radio.iab_height;scenario.radio.ue_height],[link_num/2,1]);
                    pruning_struct.dir(c,:) = ~check_vector_obstruction(pv,link_tp);
                    link_tp(:,3)=repmat([scenario.radio.ris_height;scenario.radio.ue_height],[link_num/2,1]);
                    pruning_struct.ref2(c,:) = ~check_vector_obstruction(pv,link_tp);
                    % disp(c);
                end

            end

            %filter out TPs which cannot be reached by any CS
            reachable_s = find(sum(pruning_struct.ref2));
            tp_positions = tp_positions(reachable_s,:);
            pruning_struct.ref2 = pruning_struct.ref2(:,reachable_s);
            pruning_struct.dir = pruning_struct.dir(:,reachable_s);

            if fixed_donor_position                
                if sum(pruning_struct.bh(end,:)) == 0 || sum(pruning_struct.bh(:,end)) == 0
                    disp('The Donor cannot connect to any IAB Node and must serve every TP by itself')
                    errorDonor=1;
                    return;
                end

             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %assign points to their sector
                selected_tp = [];
                selected_cs = [];
                % for i=1:n_sectors
                %     idx = find(inpolygon(cs_positions(1:end-1,1),cs_positions(1:end-1,2),spl(i).Vertices(:,1),spl(i).Vertices(:,2)));
                %     sector_cs(idx) = i;
                %     idx = find(inpolygon(tp_positions(:,1),tp_positions(:,2),spl(i).Vertices(:,1),spl(i).Vertices(:,2)));
                %     sector_tp(idx) = i;
                % 
                % end
                % sector_cs(end+1)=0; %the donor is in sector 1, but we don't care about it, it's taken for granted

                %remove subsets of CSs that cannot be reached by the
                %Donor, then remove the TPs that could access the Donor
                %through said CSs. If some of the TP minimum quota in the
                %sectors is not respected anymore, prune the whole instance
                %(it removes cells that are split by high buildings, and
                %also reduces complexity)
                %compute the shortest path tree connectivity matrix

                % remaining_tp = zeros(n_sectors,1);
                % for i=1:n_sectors
                %     remaining_tp(i) = sum(sector_tp==i);
                % end
                % 
                % if size(tp_positions,1) < n_tp || any(remaining_tp < tp_per_sector)
                % 
                %     disp('Too few TPs survived the connected component test')
                %     errorDonor = 1;
                %     return;
                % 
                % end
		%disp(['This is instance ' num2str(scenario.rng_seed) ', there are ' num2str(size(cs_positions,1)-1) ' available CSs and I need ' num2str(n_cs-1) ' clusters'])
                clust_cs= kmeans(cs_positions(1:end-1,:),n_cs-1,'Distance','cityblock','MaxIter',1000);
                % gscatter(cs_positions(1:end-1,1),cs_positions(1:end-1,2),clust_cs)
                % hold on;
                clust_cs = [clust_cs; 0]; %I don't want donor to be clustered

                clust_tp = kmeans(tp_positions,n_tp,'Distance','cityblock','MaxIter',1000);
                % gscatter(tp_positions(:,1),tp_positions(:,2),clust_tp);
                % hold on;

                ok = 0;
                while ~ok
                    for i=1:n_tp
                        selected_tp = sort([selected_tp randsample(find(clust_tp==i),1)]);                        
                    end


                    % for i=1:n_sectors
                    %     %[val,idx]=maxk(sum(pruning_struct.ref2.*(sector_tp==i)),tp_per_sector(i));
                    %     %assert(all(val),"some TPs were selected, but they cannot be served! Increase number of pregenerated TPs"),
                    %     difference = numel(find(sector_tp == i)) - tp_per_sector(i);
                    %     if difference >= 0
                    %         idx = randsample(find(sector_tp == i),tp_per_sector(i));
                    %         selected_tp = sort([selected_tp idx]);
                    %     else
                    %         if numel(find(sector_tp == i)) > 0 
                    %             idx = randsample(find(sector_tp == i),numel(find(sector_tp == i)));
                    %             selected_tp = sort([selected_tp idx]);
                    %         end
                    %         idx = randsample(setdiff(find(sector_tp),selected_tp),-difference);
                    %         selected_tp = sort([selected_tp idx]);
                    %     end
                    % end
                    pruning_cs_by_tp = pruning_struct.dir(:,selected_tp);
                    pruning_cs_by_cs = pruning_struct.bh;
                    cs_set_by_tp = cell(1,n_tp);
                    all_tps_covered = 0;
                    random_tps_ok = 1;
                    for tp=1:n_tp
                        cs_set_by_tp{tp} = find(pruning_cs_by_tp(1:end-1,tp));
                    end
                    used_clusters = [];
                    available_cs = 1:size(cs_positions,1)-1;
                    while ~all_tps_covered                
                        coverage = cellfun(@numel,cs_set_by_tp);
                        coverage(coverage==0)=Inf;
                        if all(isinf(coverage))
                            all_tps_covered = 1;
                        else
                            [~,tp_idx] = min(coverage);
                            clusters = clust_cs(cs_set_by_tp{tp_idx});
                            covered_tps = sum(pruning_cs_by_tp(cs_set_by_tp{tp_idx},setdiff(1:n_tp,find(coverage==Inf))),2);
                            
                            [val,cs_idx] = max(covered_tps);
                            if val == 0
                                disp('Error! There are no other available CSs for this TP. Randomize the TPs again.');
                                random_tps_ok = 0;
                            else
                                current_cs = cs_set_by_tp{tp_idx}(cs_idx);
                                selected_cs = [selected_cs current_cs];
                                available_cs = setdiff(available_cs,current_cs);
                                used_clusters = sort([used_clusters clust_cs(current_cs)]);
                            end                        
                            
                            if ~random_tps_ok
                                break;
                            end
                            for tp=1:n_tp
                                if ismember(current_cs,cs_set_by_tp{tp})
                                    cs_set_by_tp{tp} = [];
                                end
                                for cs=1:numel(cs_set_by_tp{tp})
                                    if ismember(cs_set_by_tp{tp}(cs),find(clust_cs == clust_cs(current_cs)))
                                        cs_set_by_tp{tp}(cs) = 0;
                                    end
                                end
                                cs_set_by_tp{tp} = cs_set_by_tp{tp}(cs_set_by_tp{tp}~=0);
                            end
                        end
                    end
                    donor = numel(cs_positions(:,1));
                    selected_cs = sort([selected_cs donor]);
                    
%                     for i=1:n_sectors
%                         cs_pruned_set = ~ismember(1:size(cs_positions,1),selected_cs)';
%                         covered_css = sum(pruning_cs_by_cs(:,selected_cs).*(sector_cs==i)'.*cs_pruned_set,2);
%                         [val,idx] = maxk(covered_css,cs_per_sector(i));
%                         %[val,idx]=maxk(sum(pruning_cs_by_tp.*(sector_cs==i)',2),cs_per_sector(i));
%                         %assert(all(val),"some CSs were selected, but they cannot be served! Increase number of pregenerated CSs"),
%                         selected_cs = sort([selected_cs idx']);
%                     end
                      unconnectable_real = [];
                      unconnectable_cluster = [];
                      while numel(selected_cs)<n_cs && not(isempty(available_cs))
                          % disp(available_cs);
                          % disp(selected_cs);
                          % disp(used_clusters);
                          spt_cm = pruning_cs_by_cs(selected_cs,selected_cs);
                          dg = graph(spt_cm);
                          bins = conncomp(dg);
                          bin_size = sum(bins==(1:max(bins))',2);
                          min_bin = min(bin_size);
                          bin_ind = find(bin_size==min_bin);
                          lonely = selected_cs((any(bins==bin_ind,1)));
                          if numel(lonely)<numel(selected_cs)
                              [val,idx] = min(sum(pruning_cs_by_cs(lonely,:),2));
                              direct_connect = any(pruning_cs_by_cs(setdiff(selected_cs,lonely),:)) & any(pruning_cs_by_cs(lonely,:),1);
                              if sum(direct_connect)==0
                                  good_picks = find(any(pruning_cs_by_cs(lonely,:)));
                                  if any(not(ismember(clust_cs(direct_connect),used_clusters)))
                                    good_picks = good_picks(not(ismember(clust_cs(direct_connect),used_clusters)));
                                  end
                                  [val,idx] = max(sum(pruning_cs_by_cs(good_picks),2));
                                  selected_cs = sort([selected_cs good_picks(idx)]);
                                  available_cs = setdiff(available_cs,good_picks(idx));
                                  used_clusters = unique(sort([used_clusters clust_cs(good_picks(idx))]));
                              else
                                good_picks = find(direct_connect);
                                if any(not(ismember(clust_cs(direct_connect),used_clusters)))
                                    good_picks = good_picks(not(ismember(clust_cs(direct_connect),used_clusters)));
                                end
                                [val,idx] = max(sum(pruning_cs_by_cs(good_picks,selected_cs),2));  
                                selected_cs = sort([selected_cs good_picks(idx)]);
                                available_cs = setdiff(available_cs,good_picks(idx));
                                used_clusters = unique(sort([used_clusters clust_cs(good_picks(idx))]));                                
                              end
                              
                          else                          
                              a=setdiff(selected_cs,unconnectable_cluster);
                              cluster_fail = 0;
                              if isempty(a)
                                  cluster_fail = 1;
                                  a=setdiff(selected_cs,unconnectable_real);
                                  [val,idx] = min(sum(pruning_cs_by_cs(a,a)));
                                  current_cs = (a(idx));
                                  cs_pruned_set = ~ismember(1:size(cs_positions,1),selected_cs)';
                                  covered_css = pruning_cs_by_cs(:,current_cs).*cs_pruned_set;
                              else
                                  [val,idx] = min(sum(pruning_cs_by_cs(a,a)));
                                  current_cs = (a(idx));
                                  cs_pruned_set = ~ismember(1:size(cs_positions,1),selected_cs)';
                                  covered_css = pruning_cs_by_cs(:,current_cs).*cs_pruned_set.*not(any(clust_cs==used_clusters,2));
                              end
                              if sum(covered_css) == 0
                                  unconnectable_cluster = [unconnectable_cluster current_cs];
                                  if cluster_fail
                                      unconnectable_real = [unconnectable_real current_cs];
                                  end
                              else
                                  [val,idx] = max(sum(pruning_cs_by_cs(:,selected_cs).*covered_css,2));
                                  if idx==0 || val==0
                                      [val,idx] = max(sum(pruning_cs_by_cs(:,selected_cs).*covered_css,2));
                                  end
                                  selected_cs = sort([selected_cs idx]);
                                  available_cs = setdiff(available_cs,idx);
                                  used_clusters = unique(sort([used_clusters clust_cs(idx)]));
                              end
                          end
                      end

                    if  all(any(pruning_struct.dir(selected_cs,selected_tp)))
                        ok=1;
                    else
                        disp('There are TPs which are not connected to the rest of the network!!');
                        errorDonor = 1;
                        return;
                    end
                end
                cs_positions = cs_positions(selected_cs,:);
                tp_positions = tp_positions(selected_tp,:);
                pruning_struct.ref1=pruning_struct.ref1(selected_cs,selected_cs);
                pruning_struct.bh = pruning_struct.bh(selected_cs,selected_cs);
                pruning_struct.ref2=pruning_struct.ref2(selected_cs,selected_tp);
                pruning_struct.dir=pruning_struct.dir(selected_cs,selected_tp);
                
                
                % finally we check if the pre-gen positions could provide enough
                % samples after the rejection method
                assert((size(cs_positions,1) >= n_cs & size(tp_positions,1) >= n_tp),...
                    'Not enough samples have survived the rejection method. Increase scenario.max_pregen{cs,tp}');
            end
        case 'rectangular'
            % this script only works for hexagonal site
        otherwise
            error('Unrecognized site shape');
    end
    
    if ~ris_on_buildings
        cs_positions = cs_positions(1:n_cs,:);
    end
    
    if fakeris
        %add an additional ris, which will be the fake one, it's position (0,0)
        n_cs = n_cs + 1;
        %cs_positions = [cs_positions; [0 0]];
        cs_positions = [[(center(1) - site_width/2) (center(2) - site_width/2)]; cs_positions];
        pruning_struct.ref1 = [ones(1,n_cs);[ones(n_cs-1,1) pruning_struct.ref1]];
        pruning_struct.ref2 = [ones(1,n_tp);pruning_struct.ref2];
        pruning_struct.bh = [zeros(1,n_cs);[zeros(n_cs-1,1) pruning_struct.bh]];
        pruning_struct.dir = [zeros(1,n_tp);pruning_struct.dir];
        %I've moved the fake RIS to the first position in the matrix
        %otherwise it would be lost among the extra CSs.
    end
    pruning_struct.ref1 = pruning_struct.ref1~=0;
    pruning_struct.ref2 = pruning_struct.ref2~=0;
    pruning_struct.bh = pruning_struct.bh~=0;
    pruning_struct.dir = pruning_struct.dir~=0;
    %check if all CSs can reach each other CS
    % clique = numel(checkReducibility(pruning_struct.bh(2:end,2:end))); %avoid fake ris
    % if clique < n_cs - 1
    %     disp('The backhaul is disjointed. Impossible to serve all TPs.')
    %     errorDonor = 1;
    %     return;
    % end
    spt_cm = not(pruning_struct.bh == 0);
    dg = graph(spt_cm);
    bins = conncomp(dg);
    reachable = sum(bins==bins(end));
    if reachable < n_cs - 1
        disp('The backhaul is disjointed. Impossible to serve all TPs.')
        errorDonor = 1;
        return;
    end
    if pl
        number=rng;
        plot(site_polygon,'HandleVisibility','off');
        axis equal;
        hold on;
        if not(isempty(map))
            plot(map,'HandleVisibility','off');
        end
        text(center(1),center(2),num2str(number.Seed),'FontSize',30);
        scatter(cs_positions(2:end-1,1),cs_positions(2:end-1,2),50,'^r','filled','DisplayName','Candidate Sites');
        scatter(cs_positions(end,1),cs_positions(end,2),100,'^k','filled','DisplayName','IAB Donor');
        scatter(tp_positions(:,1),tp_positions(:,2),50,'*g','DisplayName','Test Points');
        for i=2:n_cs
            for j=2:n_cs
                if i~=j && pruning_struct.bh(i,j)
                    h=plot([cs_positions(i,1) cs_positions(j,1)],[cs_positions(i,2) cs_positions(j,2)],'r','HandleVisibility','off');
                    if i==n_cs
                        h.LineWidth=1;
                    end
                end
            end
            for j=1:n_tp
                if pruning_struct.dir(i,j)
                    h=plot([cs_positions(i,1) tp_positions(j,1)],[cs_positions(i,2) tp_positions(j,2)],'g','HandleVisibility','off');
                    if i==n_cs
                        h.LineWidth=1;
                    end
                end
            end
        end
        drawnow
        hold off;
        %save('/home/paolo/projects/RIS-Planning-Instance-Generator/Blockage_Data/site_data.mat','pruning_struct','cs_positions','tp_positions','center')
    end
    % errorDonor = 1; % I added this to make the check fail everytime to
    % see what kind of topologies the algorithm produces
    cs_cs_distance_matrix = squareform(pdist(cs_positions));
    cs_tp_distance_matrix = pdist2(cs_positions, tp_positions);
    
    if save_to_cache
        save(cache_path, 'cs_positions','tp_positions',...
            'cs_cs_distance_matrix', 'cs_tp_distance_matrix','-append');
    end
    
else
    load(cache_path, 'cs_positions','tp_positions',...
        'cs_cs_distance_matrix', 'cs_tp_distance_matrix');
end

end

