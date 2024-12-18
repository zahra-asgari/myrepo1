function [big_M] = big_M_bottleneck(bh,acc,direction)

n_cs = size(acc.ris,2) - 1;
n_tp = size(acc.ris,1);
tx = n_cs;
rx = n_cs +1;
%tx and rx are always Donor and UE respectively; for UL I reversed the
%backhaul matrix and it's the same. We can also apply the spt like this.
big_M = Inf(n_tp,3);
pl= 1;
bh = bh(2:end,2:end);
for i=1:n_tp
    path=1;
    a = 1./squeeze(acc.ris(i,2:end,1:end-1));
    a = min(a,[],2);
    b = 1./squeeze(acc.ncr(i,2:end,1:end-1));
    b = min(b,[],2);
    c = min([a b],[],2);
    switch direction
        case 'DL'
            full = [1./bh c;Inf(1,size(bh,1)+1)];
        case 'UL'
            full = [1./(bh') c;Inf(1,size(bh,1)+1)];
    end
    
    full(full==Inf)=0;
    adj = full~=0;
    [x,y] = find(adj);
    g = digraph(x,y,diag(full(x,y)));
    if pl
        plot(g)
        drawnow
    end
    [~,~,edgepath] = shortestpath(g,tx,rx);
    edges = table2array(g.Edges(edgepath,:));
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
    %NON FUNZIONA! SE IL LINK DIRETTO ESISTE NON EE' PROBABILMENTE BUONO,
    %MA LO CONTINUERA' A TENERE!
    while path
        current_edge = edges(index,1:2);
        g_t = rmedge(g,current_edge(1),current_edge(2));
        [~,~,edgepath] = shortestpath(g_t,tx,rx);
        edges_t = table2array(g_t.Edges(edgepath,:));
        edges_t = setdiff(edges_t,unremovable,'rows');
        if isempty(edges_t)
            unremovable = [unremovable; edges(index,:)];
        else
            threshold = max(edges_t(:,3));
            disp(1/threshold)
            g = g_t;
            edges = edges_t;
            % full(current_edge(1),current_edge(2))=0;
            bad_edges = [];
            for e=1:size(g.Edges,1)
                % disp(e)
                current = table2array(g.Edges(e,:));
                if full(current(1),current(2)) > threshold && not(ismember(current,unremovable,'rows'))
                    bad_edges = [bad_edges e];
                end
            end
            g = rmedge(g,bad_edges);
            if pl
                plot(g);
                drawnow
            end


        end
        edges = setdiff(edges,unremovable,'rows');
        [~,index] = max(edges(:,3));
        if isempty(edges)
            path = 0;
        end
    end

    big_M(i,1) = min(1./unremovable(:,3));
    big_M(i,2:3) = [unremovable(1:2)]; 
end
end