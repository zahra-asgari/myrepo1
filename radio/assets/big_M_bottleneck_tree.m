function [big_M] = big_M_bottleneck_tree(bh,acc,direction)

n_cs = size(acc.ris,2) - 1;
n_tp = size(acc.ris,1);
tx = n_cs;
rx = n_cs +n_tp;
%tx and rx are always Donor and UE respectively; for UL I reversed the
%backhaul matrix and it's the same. We can also apply the spt like this.
big_M = Inf;
pl= 0;
path=1;
bh = bh(2:end,2:end);
all_c = [];
for i=1:n_tp
    a = 1./squeeze(acc.ris(i,2:end,1:end-1));
    a = min(a,[],2);
    b = 1./squeeze(acc.ncr(i,2:end,1:end-1));
    b = min(b,[],2);
    c = min([a b],[],2);
    all_c = [all_c c];
end
switch direction
    case 'DL'
        full = [1./bh all_c;Inf(1,size(bh,1)+n_tp)];
    case 'UL'
        full = [1./(bh') all_c;Inf(1,size(bh,1)+n_tp)];
end

full(full==Inf)=0;

adj = full~=0;
[x,y] = find(adj);
g = digraph(x,y,diag(full(x,y)));
tree = shortestpathtree(g,tx,tx+1:rx);
if pl
    plot(g)
    drawnow
end

edges = table2array(tree.Edges);
[threshold,index] = max(edges(:,3));
disp(1/threshold)
bad_edges = [];
for e=1:size(g.Edges,1)
    current = table2array(g.Edges(e,:));
    if full(current(1),current(2)) > threshold
        bad_edges = [bad_edges e];
    end
end
g = rmedge(g,bad_edges);
unremovable = double.empty(0,size(edges,2));

while path
    current_edge = edges(index,1:2);
    g_t = rmedge(g,current_edge(1),current_edge(2));
    tree_t = shortestpathtree(g_t,tx,tx+1:rx);
    
    edges_t = table2array(tree_t.Edges);
    if sum((sum(edges_t(:,1) == edges_t(:,2)'))==0) < n_tp
        unremovable = [unremovable; edges(index,:)];
    else
        [threshold,index_t] = max(edges_t(:,3));
        disp(1/threshold)
        bad_edges = [];
        for e=1:size(g_t.Edges,1)
            current = table2array(g_t.Edges(e,:));
            if full(current(1),current(2)) > threshold && not(ismember(current,unremovable,'rows'))
                bad_edges = [bad_edges e];
            end
        end
        g_t = rmedge(g_t,bad_edges);
    
    
        edges_t = table2array(tree_t.Edges);
        %edges_t = setdiff(edges_t,unremovable,'rows');
    
        if not(all(ismember(setdiff((n_cs+1:n_cs+n_tp),unremovable(:,2)),unique(edges_t(:,2)))))
            unremovable = [unremovable; edges(index,:)];
        elseif size(unremovable,1) >= n_tp && not(all(ismember((n_cs+1:n_cs+n_tp),unique(edges_t(:,2)))))
            unremovable = [unremovable; edges(index,:)];
        else
            g = g_t;
            edges = edges_t;
            tree = shortestpathtree(g,tx,tx+1:rx);
            if pl
                plot(g);
                drawnow
            end
    
    
        end
    end
    edges = setdiff(edges,unremovable,'rows');
    [threshold,index] = max(edges(:,3));
    disp(1/threshold);
    if isempty(edges)
        path = 0;
    end

end

big_M(1) = min(1./unremovable(:,3));
big_M(2:3) = [unremovable(1:2)];
end