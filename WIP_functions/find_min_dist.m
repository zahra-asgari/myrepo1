function p_closer = find_min_dist(bound,coord,sampl_freq_wall,p_closer)
if nargin == 3
    p_closer = Inf*ones(size(coord,1),1);
end
for q=1:numel(bound)
    for r=1:size(bound{q},1)-1
        S = bound{q}(r,:);
        E = bound{q}(r+1,:);
        % edge_l = sqrt((E(1)-S(1))^2+(E(2)-S(2))^2);
        % N1 = (E(1)-S(1))*(E(2)-S(2))*(coord(:,2)-S(2));
        % N2 = (E(2) - S(2))^2*S(1);
        % N3 = (E(1)- S(1))^2*coord(:,1);
        % D = (E(2) - S(2))^2 - (E(1) - S(1))^2;
        % x_proj = (N1 + N2 - N3)/(D);
        % y_proj = coord(:,2) - ((coord(:,1)-x_proj)*(E(1)-S(1)))/(E(2)-E(1));
        % coord_proj = [x_proj y_proj];
        % % pr_dist = pdist2(coord_proj,[S;E]);
        % pr_s_dist = sqrt((coord_proj(:,1) - S(1)).^2+((coord_proj(:,2) - S(2)).^2));
        % pr_e_dist = sqrt((coord_proj(:,1) - E(1)).^2+((coord_proj(:,2) - E(2)).^2));
        % pr_dist = [pr_s_dist,pr_e_dist];
        % good_proj = all(pr_dist<edge_l,2);
        % d = zeros(size(good_proj));
        % if any(good_proj)
        %     % ii = find(good_proj);
        %     num = abs((E(1)-S(1))*(S(2)-coord(good_proj,2))...
        %         -(S(1)-coord(good_proj,1))*(E(2)-S(2)));
        %     den = sqrt((E(1)-S(1))^2 + (E(2)-S(2))^2);
        %     projection = num/den;
        %     d(good_proj) = projection;
        %     d(not(good_proj)) = min(pdist2(coord(not(good_proj),:),[S;E]),[],2);            
        % else
            % d = pdist2(coord, [S;E]);
            % d = min(d,[],2);
        % num = abs((E(1)-S(1))*(S(2)-coord(:,2))...
        %     -(S(1)-coord(:,1))*(E(2)-S(2)));
        % den = sqrt((E(1)-S(1))^2 + (E(2)-S(2))^2);
        % projection = num/den;
        % d = [pdist2(coord, [S;E])];
        wall_length = pdist2(S,E);
        edge_x = linspace(S(1),E(1),((ceil(wall_length)+1)/sampl_freq_wall))';
        edge_y = linspace(S(2),E(2),((ceil(wall_length)+1)/sampl_freq_wall))';
        d = pdist2(coord, [edge_x,edge_y]);
        % end
        d = min(d,[],2);
        p_closer(d < p_closer) = d(d < p_closer);
    end
end
end