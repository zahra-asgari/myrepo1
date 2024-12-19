% function for extracting the diffraction loss using knife-edge effect from
% 3GPP

function Loss = DiffractionLoss(pos_bs, pos_ue, pos_blocker_center, blocker_size, orientation_blocker, fc)

   % pos_bs: [m] position of the BS (i.e., tx)  [x; y; z]
   % pos_ue: [m] position of the BS (i.e., rx)  [x; y; z]
   % pos_blocker_center: [m] center position of the blocker  [x; y; z]
   % blocker_size: [m] blocker size [length; width; height]  note that length > 0
   % orientation_blocker: [deg]  [-90 90] abslolute orienttaion angle of the blocker, counterclock is posotive, the 0 orienttaion parallel the width
   % fc: [Hz] carrier frequency
 
   % Loss: [dB] Attenuation loss caused by the 3D blocker using knife-edge
   % diffraction loss model


   if pos_blocker_center(3) ~= (blocker_size(3) / 2)
       error('blocker height shoud be equal to two times the pos blcoker center in the third position')
   end
   %% extracting the intersection points of the effective distance with the
   % LoS tx-rx link

   % topview
    if orientation_blocker>90 || orientation_blocker<-90
        
        disp('WTF')
    end
    pos_rectangle_topview = rectangleRotation(pos_blocker_center(1:2), blocker_size(2), blocker_size(1),  orientation_blocker);
    pos_intersection_to_blockerEdges_topview = IntersectionPointsToEdges(pos_ue, pos_bs, pos_rectangle_topview, pos_blocker_center, blocker_size, orientation_blocker, 'topview');
    
    sub_plot = 0;

    if sub_plot
        figure(1) %#ok<*UNRCH>
        plot([pos_ue(1) pos_bs(1)], [pos_ue(2) pos_bs(2)], 'd-', 'LineWidth', 1.5, 'MarkerSize', 8); hold on
        plot(pos_blocker_center(1), pos_blocker_center(2), '*-', 'LineWidth', 1.5, 'MarkerSize', 8); hold on
        plot(pos_rectangle_topview(1, :), pos_rectangle_topview(2, :), 'k--', 'LineWidth', 1.5); hold on
        plot([pos_rectangle_topview(1, 1) pos_rectangle_topview(1, 4)], [pos_rectangle_topview(2, 1) pos_rectangle_topview(2, 4)], 'k--', 'LineWidth', 1.5); hold on
        plot(pos_intersection_to_blockerEdges_topview(1, :), pos_intersection_to_blockerEdges_topview(2, :), 'rx-', 'LineWidth', 1.5, 'MarkerSize', 10); hold on
        set(gca, 'FontSize', 12);
        xlabel('X [m]');
        ylabel('Y [m]');
        title('Topview')
    end

    
    
    % sideview
    pos_rectangle_sideview = EdgesSideview(pos_blocker_center, blocker_size, orientation_blocker);  % four points of the blocker from the sideview
    pos_intersection_to_blockerEdges_sideview = IntersectionPointsToEdges(pos_ue, pos_bs, pos_rectangle_sideview, pos_blocker_center, blocker_size, orientation_blocker, 'sideview');


    if sub_plot
        figure(3)
        plot([pos_ue(1) pos_bs(1)], [pos_ue(3) pos_bs(3)], 'd-', 'LineWidth', 1.5, 'MarkerSize', 8); hold on
        plot(pos_blocker_center(1), pos_blocker_center(3), '*-', 'LineWidth', 1.5, 'MarkerSize', 8); hold on
        plot(pos_rectangle_sideview(1, :), pos_rectangle_sideview(2, :), 'k--', 'LineWidth', 1.5); hold on
        plot([pos_rectangle_sideview(1, 1) pos_rectangle_sideview(1, 4)], [pos_rectangle_sideview(2, 1) pos_rectangle_sideview(2, 4)], 'k--', 'LineWidth', 1.5); hold on
        plot(pos_intersection_to_blockerEdges_sideview(1, :), pos_intersection_to_blockerEdges_sideview(2, :), 'rx-', 'LineWidth', 1.5, 'MarkerSize', 10); hold on
        set(gca, 'FontSize', 12);
        xlabel('X [m]');
        ylabel('Z [m]');
        xlim([0 150]);
        ylim([0 10]);
        title('Sideview')
    end
    
   %% calculation for the loss
    % topview
    D1_w1 = pdist2(pos_intersection_to_blockerEdges_topview(:,1)', pos_ue(1:2)');
    D1_w2 = pdist2(pos_intersection_to_blockerEdges_topview(:,2)', pos_ue(1:2)');
    D2_w1 = pdist2(pos_intersection_to_blockerEdges_topview(:,1)', pos_bs(1:2)');
    D2_w2 = pdist2(pos_intersection_to_blockerEdges_topview(:,2)', pos_bs(1:2)');
    r_los_topview = pdist2(pos_ue(1:2)', pos_bs(1:2)');
    % distance between projected center point to projected line between Tx-Rx
    k_w = (pos_bs(2) - pos_ue(2)) / (pos_bs(1) - pos_ue(1)); % slope of the projection line between bs and ue on top view  
    b_w = pos_bs(2) - k_w * pos_bs(1);
    A_w = k_w;
    B_w = -1; 
    C_w =  b_w;
    Dist_w = @(x0, y0) abs(A_w * x0 + B_w * y0 + C_w) / sqrt(A_w^2 + B_w^2);   % distance a point (x0, y0) to a line 
    dist_blockageCenterToLineBSUE_topview = Dist_w(pos_blocker_center(1), pos_blocker_center(2));   % projected distance

    
    D1_h1 = pdist2(pos_intersection_to_blockerEdges_sideview(:,1)', pos_ue([1, 3])');
    %     D1_h2 = pdist2(pos_intersection_to_blockerEdges_sideview(:,2)', pos_ue([1, 3])');
    D1_h2 = 1e6;
    D2_h1 = pdist2(pos_intersection_to_blockerEdges_sideview(:,1)', pos_bs([1, 3])');
    %     D2_h2 = pdist2(pos_intersection_to_blockerEdges_sideview(:,2)', pos_bs([1, 3])');
    D2_h2 = 1e6;
    r_los_sideview = pdist2(pos_ue([1, 3])', pos_bs([1, 3])');
   
   % sideview
   % projected line between Tx and Rx
   k_h = (pos_bs(3) - pos_ue(3)) / (pos_bs(1) - pos_ue(1)); % slope of the projection line between bs and ue on side view
   b_h = pos_ue(3) - k_h * pos_ue(1);
    
   A_h = k_h;
   B_h = -1; 
   C_h =  b_h;
   Dist_h = @(x0, y0) abs(A_h * x0 + B_h * y0 + C_h) / sqrt(A_h^2 + B_h^2);
    
   dist_blockageCenterToLineBSUE_sideview = Dist_h(pos_blocker_center(1), pos_blocker_center(3));

   c = physconst('lightspeed');
   lambda = c / fc; 
   
   F_plus = @(x, r_los) (atan((pi/2) * sqrt((pi/ lambda) * (x  - r_los)))) / pi;
   F_minus = @(x, r_los) (atan(- (pi/2) * sqrt((pi/ lambda) * (x  - r_los)))) / pi;

   d_blocker_center_to_intersection_topview = pdist2(pos_blocker_center(1:2)', pos_intersection_to_blockerEdges_topview(:, 1)');
   d_blocker_center_to_intersection_sideview = pdist2(pos_blocker_center([1, 3])', pos_intersection_to_blockerEdges_sideview(:, 1)');
   if dist_blockageCenterToLineBSUE_topview <= d_blocker_center_to_intersection_topview
       F_w1 = F_plus(D1_w1 + D2_w1, r_los_topview);
       F_w2 = F_plus(D1_w2 + D2_w2, r_los_topview); 
   elseif dist_blockageCenterToLineBSUE_topview > d_blocker_center_to_intersection_topview
       Dw1 = D1_w1 + D2_w1;
       Dw2 = D1_w2 + D2_w2;
       Dw_set = [Dw1, Dw2];
       index = find(Dw_set == max(Dw_set));
       F_w1 = F_plus(Dw_set(index(1)), r_los_topview);
       Dw_set(index(1)) = [];
       F_w2 = F_minus(Dw_set, r_los_topview);
   end
   
   if dist_blockageCenterToLineBSUE_sideview <= d_blocker_center_to_intersection_sideview
       F_h1 = F_plus(D1_h1 + D2_h1, r_los_sideview);
       F_h2 = F_plus(D1_h2 + D2_h2, r_los_sideview);
   elseif dist_blockageCenterToLineBSUE_sideview > d_blocker_center_to_intersection_sideview
       Dh1 = D1_h1 + D2_h1;
       Dh2 = D1_h2 + D2_h2;
       Dh_set = [Dh1, Dh2];    
       index = find(Dh_set == max(Dh_set));
       F_h1 = F_plus(Dh_set(index(1)), r_los_sideview);
       Dh_set(index(1)) = [];
       F_h2 = F_minus(Dh_set, r_los_sideview);
   end

   Loss = -20 * log10((1 - (F_h1 + F_h2) * (F_w1 + F_w2)));


end









% rectangle rotation


function Position = rectangleRotation(center_location, L, H, deg)

    theta = deg * pi / 180;
    center1 = center_location(1);
    center2 = center_location(2);
    R = ([cos(theta), -sin(theta); sin(theta), cos(theta)]);
    X = ([L/2, L/2, -L/2, -L/2]);
    Y = ([-H/2, H/2, H/2, -H/2]);
    for i=1:4
        T(:,i) = R * [X(i); Y(i)]; %#ok<*AGROW>
    end
%     x_lower_left = center1 + T(1,1);
%     x_lower_right = center1 + T(1,2);
%     x_upper_right = center1 + T(1,3);
%     x_upper_left = center1 + T(1,4);
%     y_lower_left = center2 + T(2,1);
%     y_lower_right = center2 + T(2,2);
%     y_upper_right = center2 + T(2,3);
%     y_upper_left = center2 + T(2,4);
%     x = [x_lower_left, x_lower_right, x_upper_right, x_upper_left];
%     y = [y_lower_left, y_lower_right, y_upper_right, y_upper_left];
   if theta >  - pi / 2  && theta <=  0 
      x_lower_right = center1 + T(1,1);
      x_upper_right = center1 + T(1,2);
      x_upper_left = center1 + T(1,3);
      x_lower_left = center1 + T(1,4);
      y_lower_right = center2 + T(2,1);
      y_upper_right = center2 + T(2,2);
      y_upper_left = center2 + T(2,3);
      y_lower_left = center2 + T(2,4);
   elseif theta > 0 && theta <=  pi / 2
      x_lower_right = center1 + T(1,4);
      x_upper_right = center1 + T(1,1);
      x_upper_left = center1 + T(1,2);
      x_lower_left = center1 + T(1,3);
      y_lower_right = center2 + T(2,4);
      y_upper_right = center2 + T(2,1);
      y_upper_left = center2 + T(2,2);
      y_lower_left = center2 + T(2,3);
    elseif theta ==  -pi / 2 
      x_lower_right = center1 + T(1,2);
      x_upper_right = center1 + T(1,3);
      x_upper_left = center1 + T(1,4);
      x_lower_left = center1 + T(1,1);
      y_lower_right = center2 + T(2,2);
      y_upper_right = center2 + T(2,3);
      y_upper_left = center2 + T(2,4);
      y_lower_left = center2 + T(2,1);
   
   end

    x = [x_lower_right,  x_upper_right, x_upper_left, x_lower_left];
    y = [y_lower_right,  y_upper_right, y_upper_left, y_lower_left];
    Position = [x; y];


end


% extract the intersection points bteween the effective line of the blocker
% (perpecticular to the direct path) and four edges of the blocker, from
% torview or sideview
% update 17/11/2021

function pos_intersection_to_blockerEdges = IntersectionPointsToEdges(pos_ue, pos_bs, pos_rectangle, pos_blocker_center, blocker_size, orienttaion_blocker, view)

% intersection point of two lines
X = @(A1, A2, B1, B2, C1, C2) (B1 * C2 - B2 * C1) / (B2 * A1 - B1 * A2);
Y = @(A1, A2, B1, B2, C1, C2) (A1 * C2 - C1 * A2) / (B1 * A2 - A1 * B2);
pos_intersect = NaN(2, 2);
    switch view
        case 'topview'
          alpha = orienttaion_blocker * pi / 180;
          slope_trx = (pos_bs(2) - pos_ue(2)) / (pos_bs(1) - pos_ue(1));
          beta = atan(slope_trx);
          if ~isinf(slope_trx) && slope_trx ~= 0

             % intersection point of two lines given their functions
             % effective perpendicular line to the direct tx-rx line
             A_1 = - ((pos_bs(1) - pos_ue(1)) / (pos_bs(2) - pos_ue(2))); 
             B_1 = -1;
             C_1 = pos_blocker_center(2) + ((pos_bs(1) - pos_ue(1)) / (pos_bs(2) - pos_ue(2))) * pos_blocker_center(1);
             if alpha == 0
                 if beta > 0
                     A_2 = slope_trx;
                     B_2 = -1;
                     C_2 = pos_rectangle(2, 1) - slope_trx * pos_rectangle(1, 1);
                     pos_intersect(1, 1) = X(A_1, A_2, B_1, B_2, C_1, C_2);
                     pos_intersect(2, 1) = Y(A_1, A_2, B_1, B_2, C_1, C_2);
                     
                     A_22 = slope_trx;
                     B_22 = -1;
                     C_22 = pos_rectangle(2, 3) - slope_trx * pos_rectangle(1, 3);
                     pos_intersect(1, 2) = X(A_1, A_22, B_1, B_22, C_1, C_22);
                     pos_intersect(2, 2) = Y(A_1, A_22, B_1, B_22, C_1, C_22); 
                 elseif beta < 0
                     A_2 = slope_trx;
                     B_2 = -1;
                     C_2 = pos_rectangle(2, 2) - slope_trx * pos_rectangle(1, 2);
                     pos_intersect(1, 1) = X(A_1, A_2, B_1, B_2, C_1, C_2);
                     pos_intersect(2, 1) = Y(A_1, A_2, B_1, B_2, C_1, C_2);
                     
                     A_22 = slope_trx;
                     B_22 = -1;
                     C_22 = pos_rectangle(2, 4) - slope_trx * pos_rectangle(1, 4);
                     pos_intersect(1, 2) = X(A_1, A_22, B_1, B_22, C_1, C_22);
                     pos_intersect(2, 2) = Y(A_1, A_22, B_1, B_22, C_1, C_22);  
                 end
             elseif alpha == pi/2
                 if beta > 0
                     A_2 = slope_trx;
                     B_2 = -1;
                     C_2 = pos_rectangle(2, 1) - slope_trx * pos_rectangle(1, 1);
                     pos_intersect(1, 1) = X(A_1, A_2, B_1, B_2, C_1, C_2);
                     pos_intersect(2, 1) = Y(A_1, A_2, B_1, B_2, C_1, C_2);
                     
                     A_22 = slope_trx;
                     B_22 = -1;
                     C_22 = pos_rectangle(2, 3) - slope_trx * pos_rectangle(1, 3);
                     pos_intersect(1, 2) = X(A_1, A_22, B_1, B_22, C_1, C_22);
                     pos_intersect(2, 2) = Y(A_1, A_22, B_1, B_22, C_1, C_22); 
                 elseif beta < 0
                     A_2 = slope_trx;
                     B_2 = -1;
                     C_2 = pos_rectangle(2, 2) - slope_trx * pos_rectangle(1, 2);
                     pos_intersect(1, 1) = X(A_1, A_2, B_1, B_2, C_1, C_2);
                     pos_intersect(2, 1) = Y(A_1, A_2, B_1, B_2, C_1, C_2);
                     
                     A_22 = slope_trx;
                     B_22 = -1;
                     C_22 = pos_rectangle(2, 4) - slope_trx * pos_rectangle(1, 4);
                     pos_intersect(1, 2) = X(A_1, A_22, B_1, B_22, C_1, C_22);
                     pos_intersect(2, 2) = Y(A_1, A_22, B_1, B_22, C_1, C_22);  
                 end
             else
                 if (alpha > 0 && beta > 0  &&  alpha <= beta) || (alpha > 0 && beta <= 0  &&  abs(alpha) > abs(beta)) || (alpha < 0 && beta > 0  &&  abs(alpha) > abs(beta)) ...
                      || (alpha < 0 && beta <= 0  &&  abs(alpha) <= abs(beta))   
                     index_minX = find(pos_rectangle(1, :) == min(pos_rectangle(1, :)));
                     A_2 = slope_trx;
                     B_2 = -1;
                     C_2 = pos_rectangle(2, index_minX(1)) - slope_trx * pos_rectangle(1, index_minX(1));
                     pos_intersect(1, 1) = X(A_1, A_2, B_1, B_2, C_1, C_2);
                     pos_intersect(2, 1) = Y(A_1, A_2, B_1, B_2, C_1, C_2);
        
                     index_maxX = find(pos_rectangle(1, :) == max(pos_rectangle(1, :)));
                     A_22 = slope_trx;
                     B_22 = -1;
                     C_22 = pos_rectangle(2, index_maxX(1)) - slope_trx * pos_rectangle(1, index_maxX(1));
                     pos_intersect(1, 2) = X(A_1, A_22, B_1, B_22, C_1, C_22);
                     pos_intersect(2, 2) = Y(A_1, A_22, B_1, B_22, C_1, C_22);   
                 elseif (alpha > 0 && beta > 0  &&  alpha > beta)  || (alpha > 0 && beta <= 0  && abs(alpha) <= abs(beta)) || (alpha < 0 && beta > 0  && abs(alpha) <= abs(beta)) ...
                         || (alpha < 0 && beta <= 0  &&  abs(alpha) > abs(beta))
                     index_minY = find(pos_rectangle(2, :) == min(pos_rectangle(2, :)));
                     A_2 = slope_trx;
                     B_2 = -1;
                     C_2 = pos_rectangle(2, index_minY(1)) - slope_trx * pos_rectangle(1, index_minY(1));
                     pos_intersect(1, 1) = X(A_1, A_2, B_1, B_2, C_1, C_2);
                     pos_intersect(2, 1) = Y(A_1, A_2, B_1, B_2, C_1, C_2);
        
                     index_maxY = find(pos_rectangle(2, :) == max(pos_rectangle(2, :)));
                     A_22 = slope_trx;
                     B_22 = -1;
                     C_22 = pos_rectangle(2, index_maxY(1)) - slope_trx * pos_rectangle(1, index_maxY(1));
                     pos_intersect(1, 2) = X(A_1, A_22, B_1, B_22, C_1, C_22);
                     pos_intersect(2, 2) = Y(A_1, A_22, B_1, B_22, C_1, C_22);
                 end            
             end
          elseif slope_trx == 0  
              if alpha ~= 0 && alpha ~= pi/2
                 index_minX = find(pos_rectangle(2, :) == min(pos_rectangle(2, :)));
                 pos_intersect(1, 1) = pos_rectangle(1, index_minX(1));
                 pos_intersect(2, 1) = pos_rectangle(2, index_minX(1));
    
                 index_maxX = find(pos_rectangle(2, :) == max(pos_rectangle(2, :)));
                 pos_intersect(1, 2) = pos_rectangle(1, index_maxX(1));
                 pos_intersect(2, 2) = pos_rectangle(2, index_maxX(1));
              elseif alpha == 0
                 pos_intersect(1, 1) = pos_blocker_center(1);
                 pos_intersect(2, 1) = pos_blocker_center(2) - blocker_size(1) /2;
                 pos_intersect(1, 2) = pos_blocker_center(1);
                 pos_intersect(2, 2) = pos_blocker_center(2) + blocker_size(1) /2;
              elseif alpha == pi/2
                 pos_intersect(1, 1) = pos_blocker_center(1);
                 pos_intersect(2, 1) = pos_blocker_center(2) - blocker_size(2) /2;
                 pos_intersect(1, 2) = pos_blocker_center(1);
                 pos_intersect(2, 2) = pos_blocker_center(2) + blocker_size(2) /2;
              end
          elseif isinf(slope_trx)
              if alpha ~= 0 && alpha ~= pi/2
                 index_minX = find(pos_rectangle(2, :) == min(pos_rectangle(2, :)));
                 pos_intersect(1, 1) = pos_rectangle(1, index_minX(1));
                 pos_intersect(2, 1) = pos_rectangle(2, index_minX(1));
    
                 index_maxX = find(pos_rectangle(2, :) == max(pos_rectangle(2, :)));
                 pos_intersect(1, 2) = pos_rectangle(1, index_maxX(1));
                 pos_intersect(2, 2) = pos_rectangle(2, index_maxX(1));
              elseif alpha == 0
                 pos_intersect(1, 1) = pos_blocker_center(1);
                 pos_intersect(2, 1) = pos_blocker_center(2) - blocker_size(2) /2;
                 pos_intersect(1, 2) = pos_blocker_center(1);
                 pos_intersect(2, 2) = pos_blocker_center(2) + blocker_size(2) /2;
              elseif alpha == pi/2
                 pos_intersect(1, 1) = pos_blocker_center(1);
                 pos_intersect(2, 1) = pos_blocker_center(2) - blocker_size(1) /2;
                 pos_intersect(1, 2) = pos_blocker_center(1);
                 pos_intersect(2, 2) = pos_blocker_center(2) + blocker_size(1) /2;
              end
          end
          index = find(~isnan(pos_intersect(1, :))  & ~isnan(pos_intersect(2, :)));
          pos_intersection_to_blockerEdges = pos_intersect(:, index); %#ok<*FNDSB>

        case 'sideview'
          slope_trx = (pos_bs(3) - pos_ue(3)) / (pos_bs(1) - pos_ue(1));
          beta = atan(slope_trx);
          if ~isinf(slope_trx) && slope_trx ~= 0

             % intersection point of two lines given their functions
             % effective perpendicular line to the direct tx-rx line
             A_1 = - ((pos_bs(1) - pos_ue(1)) / (pos_bs(3) - pos_ue(3))); 
             B_1 = -1;
             C_1 = pos_blocker_center(3) + ((pos_bs(1) - pos_ue(1)) / (pos_bs(3) - pos_ue(3))) * pos_blocker_center(1);
             
             if beta > 0 && beta < pi/2
                 A_2 = slope_trx;
                 B_2 = -1;
                 C_2 = pos_rectangle(2, 1) - slope_trx * pos_rectangle(1, 1);
                 pos_intersect(1, 1) = X(A_1, A_2, B_1, B_2, C_1, C_2);
                 pos_intersect(2, 1) = Y(A_1, A_2, B_1, B_2, C_1, C_2);

                 A_22 = slope_trx;
                 B_22 = -1;
                 C_22 = pos_rectangle(2, 3) - slope_trx * pos_rectangle(1, 3);
                 pos_intersect(1, 2) = X(A_1, A_22, B_1, B_22, C_1, C_22);
                 pos_intersect(2, 2) = Y(A_1, A_22, B_1, B_22, C_1, C_22);
             elseif beta > -pi/2 && beta < 0
                 A_2 = slope_trx;
                 B_2 = -1;
                 C_2 = pos_rectangle(2, 2) - slope_trx * pos_rectangle(1, 2);
                 pos_intersect(1, 1) = X(A_1, A_2, B_1, B_2, C_1, C_2);
                 pos_intersect(2, 1) = Y(A_1, A_2, B_1, B_2, C_1, C_2);

                 A_22 = slope_trx;
                 B_22 = -1;
                 C_22 = pos_rectangle(2, 4) - slope_trx * pos_rectangle(1, 4);
                 pos_intersect(1, 2) = X(A_1, A_22, B_1, B_22, C_1, C_22);
                 pos_intersect(2, 2) = Y(A_1, A_22, B_1, B_22, C_1, C_22);
             end
          elseif slope_trx == 0   
             pos_intersect(1, 1) = pos_blocker_center(1);
             pos_intersect(2, 1) = pos_blocker_center(3) - abs(pos_rectangle(2, 2) - pos_rectangle(1, 2)) / 2;
             pos_intersect(1, 2) = pos_blocker_center(1);
             pos_intersect(2, 2) = pos_blocker_center(3) + abs(pos_rectangle(2, 2) - pos_rectangle(1, 2)) / 2;

          elseif isinf(slope_trx)
             pos_intersect(1, 1) = pos_blocker_center(1) + abs(pos_rectangle(1, 1) - pos_rectangle(4, 1)) / 2;
             pos_intersect(2, 1) = pos_blocker_center(3);
             pos_intersect(1, 2) = pos_blocker_center(1) - abs(pos_rectangle(1, 1) - pos_rectangle(4, 1)) / 2;
             pos_intersect(2, 2) = pos_blocker_center(3);
          end
          index = find(~isnan(pos_intersect(1, :))  & ~isnan(pos_intersect(2, :)));
          pos_intersection_to_blockerEdges = pos_intersect(:, index); 
    end
                  
end



% four points of the blocker from the sideview


function pos_rectangle_sideview = EdgesSideview(pos_blocker_center, blocker_size, orienttaion_blocker)
 
   theta_radian = orienttaion_blocker * pi / 180;

   pos_rectangle_sideview = NaN(2, 4); 

   if theta_radian == 0
       width = blocker_size(2);
       height = blocker_size(3);

       pos_rectangle_sideview(1, 1) = pos_blocker_center(1) + width / 2;
       pos_rectangle_sideview(2, 1) = pos_blocker_center(3) - height / 2;

       pos_rectangle_sideview(1, 2) = pos_blocker_center(1) + width / 2;
       pos_rectangle_sideview(2, 2) = pos_blocker_center(3) + height / 2;

       pos_rectangle_sideview(1, 3) = pos_blocker_center(1) - width / 2;
       pos_rectangle_sideview(2, 3) = pos_blocker_center(3) + height / 2;

       pos_rectangle_sideview(1, 4) = pos_blocker_center(1) - width / 2;
       pos_rectangle_sideview(2, 4) = pos_blocker_center(3) - height / 2;
   elseif theta_radian == pi/2
       length = blocker_size(1);
       height = blocker_size(3);
       pos_rectangle_sideview(1, 1) = pos_blocker_center(1) + length / 2;
       pos_rectangle_sideview(2, 1) = pos_blocker_center(3) - height / 2;

       pos_rectangle_sideview(1, 2) = pos_blocker_center(1) + length / 2;
       pos_rectangle_sideview(2, 2) = pos_blocker_center(3) + height / 2;

       pos_rectangle_sideview(1, 3) = pos_blocker_center(1) - length / 2;
       pos_rectangle_sideview(2, 3) = pos_blocker_center(3) + height / 2;

       pos_rectangle_sideview(1, 4) = pos_blocker_center(1) - length / 2;
       pos_rectangle_sideview(2, 4) = pos_blocker_center(3) - height / 2;
   else
       height = blocker_size(3);
       length = abs(blocker_size(1) / sin(theta_radian)) + ((blocker_size(2) - blocker_size(1) * cot(theta_radian)) * cos(theta_radian));
       for i = 1 : 4
           if i == 1 
              pos_rectangle_sideview(1, i) = pos_blocker_center(1) + length/2;
              pos_rectangle_sideview(2, i) = pos_blocker_center(3) - height/2;
           elseif i == 2
              pos_rectangle_sideview(1, i) = pos_blocker_center(1) + length/2;
              pos_rectangle_sideview(2, i) = pos_blocker_center(3) + height/2;
           elseif i == 3 
              pos_rectangle_sideview(1, i) = pos_blocker_center(1) - length/2;
              pos_rectangle_sideview(2, i) = pos_blocker_center(3) + height/2;
           elseif i == 4
              pos_rectangle_sideview(1, i) = pos_blocker_center(1) - length/2;
              pos_rectangle_sideview(2, i) = pos_blocker_center(3) - height/2;
           end
       end
   end
  
end