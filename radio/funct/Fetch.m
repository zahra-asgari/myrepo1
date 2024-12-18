function [Source,Dist_Rx2Tx, DoesServe] = Fetch(Destination,Source,Source_Panels,WhatToFetch)


if ~isprop(Source,'Selected')
    Source.addprop('Selected');
end
TargetAzimuth = atan2(Destination.Center(2)- Source.Center(2), Destination.Center(1) - Source.Center(1)); % Angle of departure
HorizShieldingAngle = deg2rad(60);
targetDistance = sqrt(sum((Source.Center - Destination.Center).^2));
NoServeDistance = abs((Source.Center(3) - Destination.Center(3))  ./ tan(abs(Source.MaxDownSteerElevRad) + abs(Source.DownTiltRad)));


if (targetDistance < NoServeDistance)
    warning('At this distance and height, the BS does not serve the destination, so no panel i sselected and channel is zero')
    Source.Selected.ElemPos = [];
    Source.Selected.Orientation = [];
    Dist_Rx2Tx = [];
    Source.Selected.CorrespondingPanel = [];
    DoesServe = 0;
else
    if isequal(WhatToFetch,'OnlyRotation')
        if (abs(angle(exp(1j*(Source_Panels.Orientation.Panel1 - TargetAzimuth)))) <= HorizShieldingAngle)
            Source.Selected.CorrespondingPanel = 1;
            Source.Selected.Orientation = Source_Panels.Orientation.Panel1;
        end
        
        if (abs(angle(exp(1j*(Source_Panels.Orientation.Panel2 - TargetAzimuth)))) <= HorizShieldingAngle)
            Source.Selected.CorrespondingPanel = 2;
            Source.Selected.Orientation = Source_Panels.Orientation.Panel2;
        end
        
        if (abs(angle(exp(1j*(Source_Panels.Orientation.Panel3 - TargetAzimuth)))) <= HorizShieldingAngle)
            Source.Selected.CorrespondingPanel = 3;
            Source.Selected.Orientation = Source_Panels.Orientation.Panel3;
        end
        DoesServe = 1;
        Source.Selected.ElemPos = [];
        Dist_Rx2Tx = [];  
        
    else
        if (abs(angle(exp(1j*(Source_Panels.Orientation.Panel1 - TargetAzimuth)))) < HorizShieldingAngle)
            Source.Selected.CorrespondingPanel = 1;
            
            Source.Selected.ElemPos = Source_Panels.ElemPos.Panel1;
            Source.Selected.Orientation = Source_Panels.Orientation.Panel1;
            Dist_Rx2Tx = Destination.Center.' - Source.Selected.ElemPos;% PL*(Dx+1i*Dy);
            %     Dist_Rx2Tx = Dist_Rx2Tx(abs(Dist_Rx2Tx)>NoServeDistance);
            
        end
        
        if (abs(angle(exp(1j*(Source_Panels.Orientation.Panel2 - TargetAzimuth)))) < HorizShieldingAngle)
            Source.Selected.CorrespondingPanel = 2;
            Source.Selected.ElemPos = Source_Panels.ElemPos.Panel2;
            Source.Selected.Orientation = Source_Panels.Orientation.Panel2;
            Dist_Rx2Tx = Destination.Center.' - Source.Selected.ElemPos;% PL*(Dx+1i*Dy);
            %     Dist_Rx2Tx = Dist_Rx2Tx(abs(Dist_Rx2Tx)>NoServeDistance);
            
        end
        
        if (abs(angle(exp(1j*(Source_Panels.Orientation.Panel3 - TargetAzimuth)))) < HorizShieldingAngle)
            Source.Selected.CorrespondingPanel = 3;
            Source.Selected.ElemPos = Source_Panels.ElemPos.Panel3;
            Source.Selected.Orientation = Source_Panels.Orientation.Panel3;
            Dist_Rx2Tx = Destination.Center.' - Source.Selected.ElemPos;% PL*(Dx+1i*Dy);
            %     Dist_Rx2Tx = Dist_Rx2Tx(abs(Dist_Rx2Tx)>NoServeDistance);
        end
        DoesServe = 1;
    end
end

end