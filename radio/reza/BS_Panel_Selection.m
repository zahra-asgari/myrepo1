function [Destination,Source, DoesServe] = BS_Panel_Selection(Destination,Source,WhatToFetch)
FOV_Horiz = deg2rad(60);
H_s = Source.Center(3);
H_d = Destination.Center(3);
targetDistance = sqrt(sum((Source.Center - Destination.Center).^2));



TargetAzimuth_Source = atan2(Destination.Center(2)- Source.Center(2), Destination.Center(1) - Source.Center(1)); % Angle of departure
FOV_Vert_Down = Source.MaxDownSteerElevRad + Source.DownTiltRad;
FOV_Vert_Up = abs(Source.MaxDownSteerElevRad) + Source.DownTiltRad;
Service_Vert_Source = (abs(H_d - H_s) <= (targetDistance * abs(tan(FOV_Vert_Up)))) && (abs(H_d - H_s) <= (targetDistance * abs(tan(FOV_Vert_Down))));




if isequal(Source.Device,'BS')
    SourcePanels = Source.Panel;
    if ~isprop(Source,'Selected')
        Source.addprop('Selected');
    end
    
    
    if  ~Service_Vert_Source
        warning('At this distance and height, the BS does not serve the destination, so no panel is selected and channel is zero')
        Source.Selected.ElemPos = [];
        Source.Selected.Orientation = [];
%         Dist_Rx2Tx = [];
        Source.Selected.CorrespondingPanel = [];
%         DoesServe = 0;
    elseif Service_Vert_Source
        if isequal(WhatToFetch,'OnlyRotation')
            if (abs(angle(exp(1j*(SourcePanels.Orientation.Panel1 - TargetAzimuth_Source)))) <= FOV_Horiz)
                Source.Selected.CorrespondingPanel = 1;
                Source.Selected.Orientation = SourcePanels.Orientation.Panel1;
            end
            
            if (abs(angle(exp(1j*(SourcePanels.Orientation.Panel2 - TargetAzimuth_Source)))) <= FOV_Horiz)
                Source.Selected.CorrespondingPanel = 2;
                Source.Selected.Orientation = SourcePanels.Orientation.Panel2;
            end
            
            if (abs(angle(exp(1j*(SourcePanels.Orientation.Panel3 - TargetAzimuth_Source)))) <= FOV_Horiz)
                Source.Selected.CorrespondingPanel = 3;
                Source.Selected.Orientation = SourcePanels.Orientation.Panel3;
            end
%             DoesServe = 1;
            Source.Selected.ElemPos = [];
%             Dist_Rx2Tx = [];
            
        else
            if (abs(angle(exp(1j*(SourcePanels.Orientation.Panel1 - TargetAzimuth_Source)))) < FOV_Horiz)
                Source.Selected.CorrespondingPanel = 1;
                Source.Selected.ElemPos = SourcePanels.ElemPos.Panel1;
                Source.Selected.Orientation = SourcePanels.Orientation.Panel1;                
            end
            
            if (abs(angle(exp(1j*(SourcePanels.Orientation.Panel2 - TargetAzimuth_Source)))) < FOV_Horiz)
                Source.Selected.CorrespondingPanel = 2;
                Source.Selected.ElemPos = SourcePanels.ElemPos.Panel2;
                Source.Selected.Orientation = SourcePanels.Orientation.Panel2;
            end
            
            if (abs(angle(exp(1j*(SourcePanels.Orientation.Panel3 - TargetAzimuth_Source)))) < FOV_Horiz)
                Source.Selected.CorrespondingPanel = 3;
                Source.Selected.ElemPos = SourcePanels.ElemPos.Panel3;
                Source.Selected.Orientation = SourcePanels.Orientation.Panel3;

            end
%             DoesServe = 1;
        end
    end
elseif isequal(Source.Device,'AF')
    
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TargetAzimuth_Destination = atan2(Source.Center(2) - Destination.Center(2), Source.Center(1) - Destination.Center(1)); % Angle of departure
FOV_Vert_Down = Destination.MaxDownSteerElevRad + Destination.DownTiltRad;
FOV_Vert_Up = abs(Destination.MaxDownSteerElevRad) + Destination.DownTiltRad;
Service_Vert_Destination = (abs(H_s - H_d) <= (targetDistance * abs(tan(FOV_Vert_Up)))) && (abs(H_s - H_d) <= (targetDistance * abs(tan(FOV_Vert_Down))));


if isequal(Destination.Device,'BS')
    DestPanels = Destination.Panel;
    if ~isprop(Destination,'Selected')
        Destination.addprop('Selected');
    end
    if  ~Service_Vert_Destination
        warning('At this distance and height, the BS does not serve the destination, so no panel is selected and channel is zero')
        Destination.Selected.ElemPos = [];
        Destination.Selected.Orientation = [];
%         Dist_Rx2Tx = [];
        Destination.Selected.CorrespondingPanel = [];
%         DoesServe = 0;
    elseif Service_Vert_Destination
        if isequal(WhatToFetch,'OnlyRotation')
            if (abs(angle(exp(1j*(DestPanels.Orientation.Panel1 - TargetAzimuth_Destination)))) <= FOV_Horiz)
                Destination.Selected.CorrespondingPanel = 1;
                Destination.Selected.Orientation = DestPanels.Orientation.Panel1;
            end
            
            if (abs(angle(exp(1j*(DestPanels.Orientation.Panel2 - TargetAzimuth_Destination)))) <= FOV_Horiz)
                Destination.Selected.CorrespondingPanel = 2;
                Destination.Selected.Orientation = DestPanels.Orientation.Panel2;
            end
            
            if (abs(angle(exp(1j*(DestPanels.Orientation.Panel3 - TargetAzimuth_Destination)))) <= FOV_Horiz)
                Destination.Selected.CorrespondingPanel = 3;
                Destination.Selected.Orientation = DestPanels.Orientation.Panel3;
            end
%             DoesServe = 1;
            Destination.Selected.ElemPos = [];
%             Dist_Rx2Tx = [];
            
        else
            if (abs(angle(exp(1j*(DestPanels.Orientation.Panel1 - TargetAzimuth_Destination)))) < FOV_Horiz)
                Destination.Selected.CorrespondingPanel = 1; 
                Destination.Selected.ElemPos = DestPanels.ElemPos.Panel1;
                Destination.Selected.Orientation = DestPanels.Orientation.Panel1;
            end
            
            if (abs(angle(exp(1j*(DestPanels.Orientation.Panel2 - TargetAzimuth_Destination)))) < FOV_Horiz)
                Destination.Selected.CorrespondingPanel = 2;
                Destination.Selected.ElemPos = DestPanels.ElemPos.Panel2;
                Destination.Selected.Orientation = DestPanels.Orientation.Panel2;
            end
            
            if (abs(angle(exp(1j*(DestPanels.Orientation.Panel3 - TargetAzimuth_Destination)))) < FOV_Horiz)
                Destination.Selected.CorrespondingPanel = 3;
                Destination.Selected.ElemPos = DestPanels.ElemPos.Panel3;
                Destination.Selected.Orientation = DestPanels.Orientation.Panel3;
            end
%             DoesServe = 1;
        end
    end
end


DoesServe = Service_Vert_Destination && Service_Vert_Source;

end
