function [done] = checkReducibility(conn_mat,done,node)
%CHECKREDUCIBILITY Summary of this function goes here
%   Detailed explanation goes here
if nargin == 1
    node = 1;
    done = 1;
end
n_cs = size(conn_mat,1);
wip = [];
for i=1:n_cs
    if conn_mat(node,i)
        wip = [wip i];
    end
end
for i=1:numel(wip)
    if ~ismember(wip(i),done)
        done = [done wip(i)];
        done = unique([done checkReducibility(conn_mat,done,wip(i))],'stable');
    end
end

end

