function Blockage = Static_3D_Blockage_Check(diameter,Params,ForWhom)
Tx = Params.Tx;
Rx = Params.Rx;
%AF = Params.AF;
RIS = Params.RIS;
switch ForWhom
    case 'Relay'
        lineseg_1 =  [Tx.Center(1),Tx.Center(2),Tx.Center(3) ; AF.Center(1),AF.Center(2),AF.Center(3)];
        
        lineseg_2 =  [AF.Center(1),AF.Center(2),AF.Center(3); Rx.Center(1),Rx.Center(2),Rx.Center(3)];
        
        Buildings = Params.Blockage.Buildings;
    
        if manage_polygons(Buildings,lineseg_1,Params.Blockage.site_center,diameter) || manage_polygons(Buildings,lineseg_2,Params.Blockage.site_center,diameter) 
            Blockage.Status = 'Static_Blocked';
            Blockage.Event = true;
            Blockage.PB = 1;
            Blockage.Loss = inf;
        else
        
            Blockage.Status = 'NotBlocked';
            Blockage.Event = false;
            Blockage.PB = 0;
            Blockage.Loss = 0;
        end
    case 'RIS'
        lineseg_1 =  [Tx.Center(1),Tx.Center(2),Tx.Center(3) ; RIS.Center(1),RIS.Center(2),RIS.Center(3)];
        
        lineseg_2 =  [RIS.Center(1),RIS.Center(2),RIS.Center(3); Rx.Center(1),Rx.Center(2),Rx.Center(3)];
        
        Buildings = Params.Blockage.Buildings;
   
        if manage_polygons(Buildings,lineseg_1,Params.Blockage.site_center,diameter) || manage_polygons(Buildings,lineseg_2,Params.Blockage.site_center,diameter) 
            Blockage.Status = 'Static_Blocked';
            Blockage.Event = true;
            Blockage.PB = 1;
            Blockage.Loss = inf;
        else
        
            Blockage.Status = 'NotBlocked';
            Blockage.Event = false;
            Blockage.PB = 0;
            Blockage.Loss = 0;
        end
    case 'Direct'
        
        lineseg =  [Tx.Center(1),Tx.Center(2),Tx.Center(3) ; Rx.Center(1),Rx.Center(2),Rx.Center(3)];
        Buildings = Params.Blockage.Buildings;
   
        if manage_polygons(Buildings,lineseg,Params.Blockage.site_center,diameter)
            Blockage.Status = 'Static_Blocked';
            Blockage.Event = true;
            Blockage.PB = 1;
            Blockage.Loss = inf;
        else
        
            Blockage.Status = 'NotBlocked';
            Blockage.Event = false;
            Blockage.PB = 0;
            Blockage.Loss = 0;
        end
end
end