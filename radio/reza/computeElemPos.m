
function [Panel] = computeElemPos(Terminal,Orientation_rad,WhatToCalculate)

switch Terminal.Device
    case 'BS'
        if isequal(WhatToCalculate,'OnlyRotation')
            StandardTxOrient_Panel_1 = 0;
            StandardTxOrient_Panel_2 = 2*pi/3;
            StandardTxOrient_Panel_3 = -2*pi/3;
            
            Panel.Orientation.Panel1 = (angle(exp(1j*(StandardTxOrient_Panel_1 + Orientation_rad))));
            Panel.Orientation.Panel2 = (angle(exp(1j*(StandardTxOrient_Panel_2 + Orientation_rad))));
            Panel.Orientation.Panel3 = (angle(exp(1j*(StandardTxOrient_Panel_3 + Orientation_rad))));
            Panel.ElemPos = [];
        else
            StandardTxOrient_Panel_1 = 0;
            StandardTxOrient_Panel_2 = 2*pi/3;
            StandardTxOrient_Panel_3 = -2*pi/3;
            
            
            Panel.Orientation.Panel1 = (angle(exp(1j*(StandardTxOrient_Panel_1 + Orientation_rad))));
            Panel.Orientation.Panel2 = (angle(exp(1j*(StandardTxOrient_Panel_2 + Orientation_rad))));
            Panel.Orientation.Panel3 = (angle(exp(1j*(StandardTxOrient_Panel_3 + Orientation_rad))));
            N_h = Terminal.Nh;
            N_v = Terminal.Nv;
            d = Terminal.d;   % inter-element sapcing
            a = (N_h-1) * d;
            shift = a * sqrt(3) / 6;
            %     shift = 0;
            
            x_ura = (0 : d : (N_h -1)*d) - ((N_h-1)/2)*d;
            y_ura = repmat(0, 1, N_h * N_v) + shift; %#ok<REPMAT>
            
            z_ura = (0 : d : (N_v -1)*d) - ((N_v -1)/2)*d;
            X_ura = repmat(x_ura, N_v,1).';
            Z_ura = repmat(z_ura, N_h,1);
            elPostemp(1,:) = X_ura(:);
            elPostemp(2,:) = y_ura(:);
            elPostemp(3,:) = Z_ura(:);
            %     disp('stop')
            tilt  = 0;
            %     Rot = (pi/2);
            Rot_AlongX = [1 0 0 ;0 cos(tilt) -sin(tilt); 0 sin(tilt) cos(tilt)];
            elPos_Tilted = Rot_AlongX * elPostemp;
            
            Rot_Pan1_AlongZ = [cos(Panel.Orientation.Panel1 - (pi/2)) -sin(Panel.Orientation.Panel1- (pi/2)) 0 ; sin(Panel.Orientation.Panel1- (pi/2)) cos(Panel.Orientation.Panel1- (pi/2)) 0 ;0 0 1];
            Panel.ElemPos.Panel1 = Rot_Pan1_AlongZ * elPos_Tilted + Terminal.Center.';
            
            Rot_Pan2_AlongZ = [cos(Panel.Orientation.Panel2- (pi/2)) -sin(Panel.Orientation.Panel2- (pi/2)) 0 ; sin(Panel.Orientation.Panel2- (pi/2)) cos(Panel.Orientation.Panel2- (pi/2)) 0 ;0 0 1];
            Panel.ElemPos.Panel2 = Rot_Pan2_AlongZ * elPos_Tilted + Terminal.Center.';
            
            Rot_Pan3_AlongZ = [cos(Panel.Orientation.Panel3- (pi/2)) -sin(Panel.Orientation.Panel3- (pi/2)) 0 ; sin(Panel.Orientation.Panel3- (pi/2)) cos(Panel.Orientation.Panel3- (pi/2)) 0 ;0 0 1];
            Panel.ElemPos.Panel3 = Rot_Pan3_AlongZ * elPos_Tilted + Terminal.Center.';
        end
        

    case 'UE'
        d = Terminal.d;
        N_h = Terminal.Nh;
        N_v = Terminal.Nv;
        x_ura = (0 : d : (N_h -1)*d) - ((N_h-1)/2)*d;
        y_ura = repmat(0, 1, N_h * N_v); %#ok<REPMAT>
        
        z_ura = (0 : d : (N_v -1)*d) - ((N_v -1)/2)*d;
        X_ura = repmat(x_ura, N_v,1).';
        Z_ura = repmat(z_ura, N_h,1);
        
        elPostemp(1,:) = X_ura(:);
        elPostemp(2,:) = y_ura(:);
        elPostemp(3,:) = Z_ura(:);
        
        tilt  = 0;
        Rot_AlongX = [1 0 0 ;0 cos(tilt) -sin(tilt); 0 sin(tilt) cos(tilt)];
        elPos_Tilted = Rot_AlongX * elPostemp;
        StandardRxOrient = 0;
        UE_Rot= angle(exp(1j*(StandardRxOrient + Orientation_rad)));
        
        Rot_Pan1_AlongZ = [cos(UE_Rot - (pi/2)) -sin(UE_Rot- (pi/2)) 0 ; sin(UE_Rot- (pi/2)) cos(UE_Rot- (pi/2)) 0 ;0 0 1];
        Panel.ElemPos = Rot_Pan1_AlongZ * elPos_Tilted + Terminal.Center.';
        Panel.Orientation = UE_Rot;
        
    case 'RIS'
        RIS_Elem_locations = zeros(Terminal.Nris,1,1,3);
        Center = Terminal.Center;
        switch Terminal.Plane
            case 'xy'
                M = Terminal.Nh;
                N = Terminal.Nv;
                X_locations = Center(1) + (-(M - 1)/2 : 1 : (M - 1)/2) .* Terminal.d;
                Y_locations = Center(2) + (-(N - 1)/2 : 1 : (N - 1)/2) .* Terminal.d;
                XY_Complex = X_locations + 1j.*Y_locations.';
                XY_Complex = XY_Complex(:);
                RIS_Elem_locations(:,1,1,1) = real(XY_Complex);
                RIS_Elem_locations(:,1,1,2) = imag(XY_Complex);
                RIS_Elem_locations(:,1,1,3) = Center(1,3);
            case 'yz'
                M = Terminal.Nh;
                N = Terminal.Nv;
                Y_locations = Center(2) + (-(M - 1)/2 : 1 : (M - 1)/2) .* Terminal.d;
                Z_locations = Center(3) + (-(N - 1)/2 : 1 : (N - 1)/2) .* Terminal.d;
                YZ_Complex = Y_locations + 1j.*Z_locations.';
                YZ_Complex = YZ_Complex(:);
                RIS_Elem_locations(:,1,1,1) = Center(1,1);
                RIS_Elem_locations(:,2) = real(YZ_Complex);
                RIS_Elem_locations(:,3) = imag(YZ_Complex);
            case'zx'
                M = Terminal.Nh;
                N = Terminal.Nv;
                Z_locations = Center(3) + (-(M - 1)/2 : 1 : (M - 1)/2) .* Terminal.d;
                X_locations = Center(1) + (-(N - 1)/2 : 1 : (N - 1)/2) .* Terminal.d;
                ZX_Complex = Z_locations + 1j.*X_locations.';
                ZX_Complex = ZX_Complex(:);
                RIS_Elem_locations(:,3) = real(ZX_Complex);
                RIS_Elem_locations(:,1,1,2) = Center(1,2);
                RIS_Elem_locations(:,1) = imag(ZX_Complex);
                
        end
        Panel.ElemPos = RIS_Elem_locations;
        Panel.Orientation = Orientation_rad;
end

end