clc;


A.B.C = 1;
F.E = 1;
H = 1;
tic
X.AfromB = 100;
% X.(['A','from','B'])
text = ['A','from','B'];
ThisAmount.Val = 0;
for i = 1:1e5
    %     D = A.B.C;
    %     D = 1;
    %     D = H;
    %     D = F.E;
    %        D = X.AfromB;
    %        D = X.(['A','from','B']);
%     D = X.(text);

    ThisAmount = Calc(ThisAmount);
end
toc
disp(ThisAmount )






function prmout = Calc(prmin)
% Value = prmin.Val;
temp = 0;
for i =1:1e3
%     temp = temp + Value;
    temp = temp + prmin.Val;
end
prmout.Val = temp;
end

