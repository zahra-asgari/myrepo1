function Final_Orientation = Get_Orientation(Start,End,Angles)
% Start and End must be either of 'Tx','Rx','AF', 'RIS', 'Relay'

Terminal = Start;
switch Terminal.Orientation
    case  'Optimum'
        Final_Orientation = Angles.(Start.Role).(End.Role);
    case 'Random'
        Final_Orientation = 2 * pi * rand;
    case 'Rx'
        if ~isequal(Start,'Rx')
            Final_Orientation = Angles.(Start.Role).(Rx.Role);
        else
            error('Tx and Rx are the same terminal')
        end
    case 'Tx'
        if ~isequal(Start,'Tx')
            Final_Orientation = Angles.(Start.Role).(Tx.Role);
        else
            error('Tx and Rx are the same terminal')
        end
    case 'AF'
        if ~isequal(Start,'AF')
            Final_Orientation = Angles.(Start).Relay;
        else
            error('Tx and Rx are the same terminal')
        end
    case 'RIS'
        if ~isequal(Start,'RIS')
            Final_Orientation = Angles.(Start).Relay;
        else
            error('Tx and Rx are the same terminal')
        end
        
    otherwise
        if isnumeric(Terminal.Orientation)
            Final_Orientation = Terminal.Orientation;
        else
            error('Undefined Tx orientation')
        end
end
end

