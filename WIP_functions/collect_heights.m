clear;
clc;
load('/home/paolo/projects/RIS-Planning-Instance-Generator/Blockage_Data/Milan_Buildings_3.mat')
n = numel(Buildings);
heights = zeros(n,1);
categories = zeros(10,1);
for b=1:n
heights(b,1) = Buildings(b).properties.UN_VOL_AV;
switch Buildings(b).properties.UN_VOL_POR
    case '0301'
        categories(1,1) = categories(1,1) + 1;
    case '0302'
        categories(2,1) = categories(2,1) + 1;
    case '0303'
        categories(3,1) = categories(3,1) + 1;
    case '0304'
        categories(4,1) = categories(4,1) + 1;
    case '0305'
        categories(5,1) = categories(5,1) + 1;
    case '0306'
        categories(6,1) = categories(6,1) + 1;
    case '0307'
        categories(7,1) = categories(7,1) + 1;
    case '0308'
        categories(8,1) = categories(8,1) + 1;
    case '0309'
        categories(9,1) = categories(9,1) + 1;
    case '0395'
        categories(10,1) = categories(10,1) + 1;
        
end
disp([b n])
end
disp(categories)
disp(n - sum(categories))
heights = sort(heights);
bar(heights);
hold on;
yline(6,'r');