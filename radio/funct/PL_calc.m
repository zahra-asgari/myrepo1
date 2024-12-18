function PL_dB = PL_calc(SourcePos,DestPos,flag,fc)
c = 3e8;
He = 1;
H_prime_UE  = DestPos(3) - He;
H_prime_BS = SourcePos(3) - He;
d_prime_BP = 4 * H_prime_BS * H_prime_UE * fc /c;

% Distances = DestPos - SourcePos;
Dist3D = pdist2(SourcePos, DestPos);
% Dist3D = sqrt(sum(Distances.^2));
% Dist2D = sqrt(sum(Distances(1:2).^2));
Dist2D = pdist2(SourcePos(1:2), DestPos(1:2));
% PL_dB = 32.4 + 20*log10(Dist3D) + 20 * log10(fc/1e9);
if isequal(flag ,'UMa')
    if (Dist2D) <= d_prime_BP || (Dist2D) >=10
        PL_dB = 28 + 22*log10(Dist3D) + 20 * log10(fc/1e9);
    elseif (Dist2D) <= 5000 || (Dist2D) > d_prime_BP
        PL_dB = 28 + 40*log10(Dist3D) + 20 * log10(fc/1e9) - 9*log10((d_prime_BP).^2 + (SourcePos(3) - DestPos(3)).^2);
    end
elseif isequal(flag ,'UMi')
    if ((Dist2D) <= d_prime_BP) %&& ((Dist2D) >=10)
        PL_dB = 32.4 + 21*log10(Dist3D) + 20 * log10(fc/1e9);
    elseif (Dist2D) <= 5000 && (Dist2D) > d_prime_BP
        PL_dB = 32.4 + 40*log10(Dist3D) + 20 * log10(fc/1e9) - 9.5*log10((d_prime_BP).^2 + (SourcePos(3) - DestPos(3)).^2);
    end 
end

end