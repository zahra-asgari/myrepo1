function Blockage = Static_Blockage_Check(Params,ForWhom)
Tx = Params.Tx;
Rx = Params.Rx;
AF = Params.AF;
RIS = Params.RIS;
epsilon = rand * 1e-6;
switch ForWhom
    case 'Relay'
        lineseg2D_1 =  [Tx.Center(1) ,Tx.Center(2); AF.Center(1) ,AF.Center(2)+epsilon];

        lineseg2D_2 =  [AF.Center(1) ,AF.Center(2); Rx.Center(1) ,Rx.Center(2)+epsilon];

        Buildings = Params.Blockage.Buildings;
        N_BLD = length(Buildings);
        for POL = 1:N_BLD
            This_BLD = Buildings{1,POL};
            [LineSegInside_1,LineSegOutside_1] = intersect(This_BLD,lineseg2D_1);
            [LineSegInside_2,LineSegOutside_2] = intersect(This_BLD,lineseg2D_2);
            if (isempty(LineSegOutside_1)) || (~isempty(LineSegInside_1)) || (isempty(LineSegOutside_2)) || (~isempty(LineSegInside_2))
                Blockage.Status = 'Static_Blocked';
                Blockage.Event = true;
                Blockage.PB = 1;
                Blockage.Loss = inf;
                return
            end
        end
        Blockage.Status = 'NotBlocked';
        Blockage.Event = false;
        Blockage.PB = 0;
        Blockage.Loss = 0;

    case 'RIS'
        lineseg2D_1 =  [Tx.Center(1) ,Tx.Center(2); RIS.Center(1) ,RIS.Center(2)+epsilon];

        lineseg2D_2 =  [RIS.Center(1) ,RIS.Center(2); Rx.Center(1) ,Rx.Center(2)+epsilon];

        Buildings = Params.Blockage.Buildings;
        N_BLD = length(Buildings);
        for POL = 1:N_BLD
            This_BLD = Buildings{1,POL};
            [LineSegInside_1,LineSegOutside_1] = intersect(This_BLD,lineseg2D_1);
            [LineSegInside_2,LineSegOutside_2] = intersect(This_BLD,lineseg2D_2);
            if (isempty(LineSegOutside_1)) || (~isempty(LineSegInside_1)) || (isempty(LineSegOutside_2)) || (~isempty(LineSegInside_2))
                Blockage.Status = 'Static_Blocked';
                Blockage.Event = true;
                Blockage.PB = 1;
                Blockage.Loss = inf;
                return
            end
        end
        Blockage.Status = 'NotBlocked';
        Blockage.Event = false;
        Blockage.PB = 0;
        Blockage.Loss = 0;

    case 'Direct'

        lineseg2D_1 =  [Tx.Center(1) ,Tx.Center(2); Rx.Center(1) ,Rx.Center(2)+epsilon];
        Buildings = Params.Blockage.Buildings;
        N_BLD = length(Buildings);
        for POL = 1:N_BLD
            This_BLD = Buildings{1,POL};
            % %             plot(This_BLD)
            % %             hold on
            [LineSegInside_1,LineSegOutside_1] = intersect(This_BLD,lineseg2D_1);
            if (isempty(LineSegOutside_1)) || (~isempty(LineSegInside_1))
                Blockage.Status = 'Static_Blocked';
                Blockage.Event = true;
                Blockage.PB = 1;
                Blockage.Loss = inf;
                %                 H = 0;
                return
            end
        end
        Blockage.Status = 'NotBlocked';
        Blockage.Event = false;
        Blockage.PB = 0;
        Blockage.Loss = 0;
end
end