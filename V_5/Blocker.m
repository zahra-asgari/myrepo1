classdef Blocker
    properties
        HEIGHT
        WIDTH
        LENGTH
        Orientation
        Blocker3DCenterPos
        Polygon2D
        RxPos
        TxPos
        DoesBlock
        Loss_dB
    end
    
    methods
        function obj = Blocker(Stat)
            obj.HEIGHT =  random(Stat.HeighDist);
            obj.WIDTH =   random(Stat.WidthDist);
            obj.LENGTH =  random(Stat.LenDist);
        end
        
        function [obj,AllBlockers] = SetBlocker(obj,OtherBlockers,MaxRadius)
            W = obj.WIDTH;
            L = obj.LENGTH;
            x_Blocker = [-W/2, -W/2, W/2, W/2];
            y_Blocker = [-L/2,  L/2, L/2, -L/2];
            XY_Blocker = [x_Blocker;y_Blocker];
            if isempty(OtherBlockers)
                Rotation = rand * 180 - 90;
                obj.Orientation = Rotation;
                RotationMatrix = [cosd(Rotation ),-sind(Rotation );sind(Rotation ),cosd(Rotation )];
                XY_Blockage_Rot= RotationMatrix * XY_Blocker;
                RandPosBlockerCenter = (MaxRadius*sqrt(rand)) .* exp(1j*2*pi*(rand));
                ThisBlockerPos = [real(RandPosBlockerCenter),imag(RandPosBlockerCenter)];
                x_Blocker_rot = XY_Blockage_Rot(1,:)+ ThisBlockerPos(1);
                y_Blocker_rot = XY_Blockage_Rot(2,:)+ ThisBlockerPos(2);
                obj.Polygon2D = polyshape(x_Blocker_rot,y_Blocker_rot);
                
            else
                CollisionID = 1;
                while ~isempty(CollisionID)
                    CollisionID = [];
                    Rotation = rand * 180 - 90;
                    obj.Orientation = Rotation;
                    RotationMatrix = [cosd(Rotation ),-sind(Rotation );sind(Rotation ),cosd(Rotation )];
                    XY_Blockage_Rot= RotationMatrix * XY_Blocker;
                    RandPosBlockerCenter = (MaxRadius*sqrt(rand)) .* exp(1j*2*pi*(rand));
                    ThisBlockerPos = [real(RandPosBlockerCenter),imag(RandPosBlockerCenter)];
                    x_Blocker_rot = XY_Blockage_Rot(1,:)+ ThisBlockerPos(1);
                    y_Blocker_rot = XY_Blockage_Rot(2,:)+ ThisBlockerPos(2);
                    CurentBlocker = polyshape(x_Blocker_rot,y_Blocker_rot);
                    obj.Polygon2D = CurentBlocker;
                    
                    for j = 1:length(OtherBlockers)
                        OldBlocker = OtherBlockers(1,j).Polygon2D;
                        [~ , TempID ,~]= intersect(CurentBlocker,OldBlocker);
                        CollisionID = [CollisionID;TempID]; %#ok<*AGROW>
                    end
                end
            end
            
            obj.Blocker3DCenterPos = [ThisBlockerPos(1),ThisBlockerPos(2),obj.HEIGHT/2];
            
            AllBlockers = cat(2,OtherBlockers,obj);
            %             length(AllBlockers)
            %             plot(obj.Polygon2D)
            %             hold on
        end
        
        
        function [BlockageEvent,obj] = CheckIndicdence(obj,TxPos,RxPos)
            obj.RxPos = RxPos;
            obj.TxPos = TxPos;
            lineseg2D =  [TxPos(1) ,TxPos(2); RxPos(1) ,RxPos(2)];
            [LineSegInside,LineSegOutside] = intersect(obj.Polygon2D,lineseg2D);
            if isempty(LineSegOutside)
                BlockageEvent = 1;
            else
                if ~isempty(LineSegInside)
                    h_BS = TxPos(3);
                    h_UE = RxPos(3);
                    BlockerHeight = obj.HEIGHT;
                    Eff_Blocker_Width = norm([LineSegInside(2,1) - LineSegInside(1,1),LineSegInside(2,2) - LineSegInside(1,2)]);
                    BS_blocker_Dist = norm([LineSegOutside(2,1) - LineSegOutside(1,1),LineSegOutside(2,2) - LineSegOutside(1,2)]);
                    d_1  = BS_blocker_Dist;
                    W_eff = Eff_Blocker_Width;
                    d_2 = (d_1*BlockerHeight + W_eff*BlockerHeight) ./ (h_BS - BlockerHeight);
                    Delta_d = d_2 * h_UE ./ BlockerHeight;
                    UE_dist = norm([RxPos(2) - TxPos(2),RxPos(1) - TxPos(1)]);
                    BlockageEvent = (UE_dist < d_1 + W_eff + d_2 - Delta_d);
                else
                    BlockageEvent = 0;
                end
            end
            obj.DoesBlock = BlockageEvent;
        end
        
        
        function [Loss_dB,obj] = BlockageLoss(obj,fc)
            if obj.DoesBlock == 1
                Loss_dB = DiffractionLoss((obj.TxPos).', (obj.RxPos).', (obj.Blocker3DCenterPos).',...
                    [obj.LENGTH,obj.WIDTH,obj.HEIGHT], obj.Orientation, fc);
                obj.Loss_dB = Loss_dB;
            else
                Loss_dB  = 0;
                obj.Loss_dB = Loss_dB;
%                 disp('This object does not block')
            end
        end
        
        
    end
end