function [solution] = solution_to_struct(filepath)
%SOLUTION_TO_STRUCT Summary of this function goes here
%   Detailed explanation goes here
run(filepath);

%solution.time = time;
solution.y_don = y_don;
solution.y_ris = y_ris;
solution.avg_angsep=avg_angsep;
solution.x = x;
solution.delta = delta;
solution.obj=obj;

end

