function blocked = check_vector_obstruction(map,link)
n_links = size(link,1)/2;
blocked = zeros(1,n_links);
pl=0;
c = zeros(size(blocked));
t = zeros(size(blocked));
for i=1:n_links
    c(1,i) = link(2*i,3) - link(2*i-1,3);
end
[xi,yi,ii] = polyxpoly(link(:,1),link(:,2),map(:,1),map(:,2));
if pl
    plot(polyshape(map(:,1:2)));
    hold on;
    for i=1:n_links
        plot(link(2*i-1:2*i,1)',link(2*i-1:2*i,2)');
    end
    axis equal;
    drawnow;
    hold off;

%     hold on
%     scatter(0.513035920406155*1e6, 5.039067449198294*1e6,'^k');
%     hold off
end
if ~c    
        hits = size(ii,1);
        for is=hits:-1:1
            l_idx=ii(is,1);
            b_idx=ii(is,2);            
            if link(l_idx,3)<= map(b_idx,3) && ~blocked(1,(l_idx+mod(l_idx,2))/2)
                blocked(1,(l_idx+mod(l_idx,2))/2)=1;
            end
        end             
else    
    hits = size(ii,1);
    for is=hits:-1:1
        l_idx=ii(is,1);
        b_idx=ii(is,2);
        tx_idx = l_idx - (1 - mod(l_idx,2));
        rx_idx = l_idx + mod(l_idx,2);

        if ~blocked(1,rx_idx/2)
            c_x = link(rx_idx,1) - link(tx_idx,1);
            c_y = link(rx_idx,2) - link(tx_idx,2);
            c_all = [c_x c_y];
            [~,idx]=max(abs(c_all));
            c(1,rx_idx/2)=c_all(idx);
            if c(1,rx_idx/2) ~= 0
                if idx == 1
                    t(1,rx_idx/2) = (xi(is) - link(tx_idx,1))/c(1,rx_idx/2);
                elseif idx == 2
                    t(1,rx_idx/2) = (yi(is) - link(tx_idx,2))/c(1,rx_idx/2);
                end
                z_is = link(tx_idx,3) + t(1,rx_idx/2)*(link(rx_idx,3) - link(tx_idx,3));
                if z_is <= map(b_idx,3)
                    blocked(1,rx_idx/2)=1;
                    % if (tx_idx==9 || tx_idx==23) && (rx_idx==10 || rx_idx==24)
                    %     disp(['Link (' num2str(tx_idx) ',' num2str(rx_idx) ') BLOCKED! The height of the building is ' num2str(map(b_idx,3)) ' m and the link is at ' num2str(z_is) ' m']);
                    %     hold on;
                    %     scatter(xi(is),yi(is),'*r');
                    %     drawnow;
                    %     hold off;
                    % end
                else
                    % if (tx_idx==9 || tx_idx==23) && (rx_idx==10 || rx_idx==24)
                    %     disp(['Link (' num2str(tx_idx) ',' num2str(rx_idx) ') not Blocked. The height of the building is ' num2str(map(b_idx,3)) ' m and the link is at ' num2str(z_is) ' m']);
                    %     hold on;
                    %     scatter(xi(is),yi(is),'*g');
                    %     drawnow;
                    %     hold off;
                    % 
                    % end
                end
            else
                warning('Both x and y of the tx and the intersection points are the same: it shouldn''t happen!');
            end   
        end
    end 

end

end