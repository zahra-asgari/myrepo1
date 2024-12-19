classdef Network_Entity < dynamicprops
    
    properties
        Device
        Type
        d
        Nv
        Nh
        NF
        Orientation  %% property in radian units
        Efficiency
        Center
        Panel
        DownTiltRad
        MaxDownSteerElevRad
        Horizontal_FOV
    end
    
    methods
        function obj = Network_Entity(Device,Position,Communication,varargin)
            
            ExpectedDevices = {'BS','UE','AF','DF','RIS','IRS'};
            ValidDevices =  @(x) any(validatestring(x,ExpectedDevices));
            ValidPositions = @(x) isnumeric(x) && isreal(x) && (~isscalar(x))  && (size(x,1) .* size(x,2) ==3) && (length(x)==3);
            
            defaultOrientation = 'Optimum';
            ExpectedOrienations = {'Optimum','Random','Tx','Rx','Relay'};
            PARSER = inputParser;
            addRequired(PARSER,'Device',ValidDevices);
            
            addRequired(PARSER,'Position',ValidPositions);
            
            addRequired(PARSER,'Communication',@isstruct);
            
            obj.Device = Device;
            switch Device
                
                case 'BS'
                    addprop(obj,'EIRP');
                    addprop(obj,'Ptx');
                    addprop(obj,'ArrSize');
%                     addprop(obj,'DownTiltRad');
%                     addprop(obj,'MaxDownSteerElevRad');
                    
                    Default_BS_Type = 'IAB';
                    Expected_BS_Types = {'IAB','Donor'};
                    Valid_BS_Types =  @(x) (any(validatestring(x,Expected_BS_Types)));
                    addOptional(PARSER,'Type',Default_BS_Type,Valid_BS_Types);
                    
                    %                     addOptional(PARSER,'Orientation',defaultOrientation,ValidateTheOrientation);
                    addOptional(PARSER,'Orientation',defaultOrientation,@ValidOrientations);
                    parse(PARSER,Device,Position,Communication,varargin{:});
                    
                    if ~isnumeric(PARSER.Results.Orientation)
                        Final_Orientation = validatestring(PARSER.Results.Orientation, ExpectedOrienations);
                    else
                        Final_Orientation = PARSER.Results.Orientation';
                    end
                    
                    obj = Define_BS(validatestring(PARSER.Results.Type, Expected_BS_Types), Final_Orientation, Communication, obj);
                    
                case  'UE'
                    addprop(obj,'EIRP');
                    addprop(obj,'Ptx');
                    addprop(obj,'ArrSize');
                    addprop(obj,'Band');
                     %addprop(obj,'DownTiltRad');
                     %addprop(obj,'MaxDownSteerElevRad');
                    
                    Default_UE_Type = 'Class2';
                    Expected_UE_Types = {'Class1','Class2','Class3','Class4'};
                    Valid_UE_Types =  @(x) (any(validatestring(x,Expected_UE_Types)));
                    addOptional(PARSER,'Type',Default_UE_Type, Valid_UE_Types);
                    
                    Default_UE_bands = 'n257';
                    Expected_UE_bands = {'n257','n2258','n260','n261'};
                    Valid_UE_Bands =  @(x) (any(validatestring(x,Expected_UE_bands)));
                    addOptional(PARSER,'Band',Default_UE_bands,Valid_UE_Bands);
                    
                    Valid_Antenna_Size = @(x) isnumeric(x) && (x>0) && isinteger(int8(x));
                    Default_UE_Nh = 2;
                    Default_UE_Nv = 2;
                    addOptional(PARSER,'Nh',Default_UE_Nh,Valid_Antenna_Size);
                    addOptional(PARSER,'Nv',Default_UE_Nv,Valid_Antenna_Size);
                    
                    addOptional(PARSER,'Orientation',defaultOrientation,@ValidOrientations);
                    parse(PARSER,Device,Position,Communication,varargin{:});
                    
                    if ~isnumeric(PARSER.Results.Orientation)
                        Final_Orientation = validatestring(PARSER.Results.Orientation, ExpectedOrienations);
                    else
                        Final_Orientation = PARSER.Results.Orientation';
                    end
                    
                    obj = Define_UE(PARSER.Results.Nh,  PARSER.Results.Nv,  PARSER.Results.Type,...
                        PARSER.Results.Band,  Final_Orientation ,Communication, obj);
                    
                    
                case  'AF'
                    addprop(obj,'Role');
                    addprop(obj,'EIRP_min');
                    addprop(obj,'EIRP_max');
                    addprop(obj,'AppGain');
                    addprop(obj,'Horizontal_Alignment_Limit');
                    
                    %                     addprop(obj,'Ptx');
                    addprop(obj,'ArrSize');
                    %addprop(obj,'DownTiltRad');
                     %addprop(obj,'MaxDownSteerElevRad');
                    
                    Default_UE_Type = 'Option1';
                    Expected_UE_Types = {'Option1','Option2'};
                    Valid_UE_Types =  @(x) (any(validatestring(x,Expected_UE_Types)));
                    addOptional(PARSER,'Type',Default_UE_Type,Valid_UE_Types);
                    
                    addOptional(PARSER,'Orientation',defaultOrientation,@ValidOrientations);
                    parse(PARSER,Device,Position,Communication,varargin{:});
                    
                    if ~isnumeric(PARSER.Results.Orientation)
                        Final_Orientation = validatestring(PARSER.Results.Orientation, ExpectedOrienations);
                    else
                        Final_Orientation = PARSER.Results.Orientation';
                    end
                    
                    obj = Define_AF(PARSER.Results.Type,  PARSER.Results.Orientation, Communication, obj);
                    
                case  'RIS'
                    addprop(obj,'Config');
                    addprop(obj,'Nris');
                    addprop(obj,'Role');
                    
                    
                    Default_RIS_Policy_Config = 'Anomalous';
                    Expected_RIS_Policy_Configs = {'Anomalous','Focus','FF_Assympt','Specular'};
                    Valid_RIS_Configs =  @(x) (any(validatestring(x,Expected_RIS_Policy_Configs)));
                    addOptional(PARSER,'Policy',Default_RIS_Policy_Config, Valid_RIS_Configs);
                    
                    
                    Default_RIS_Directivity_Config = 'true';
                    Expected_RIS_Directivity_Configs = {'true','false'};
                    Valid_RIS_Configs =  @(x) (any(validatestring(x,Expected_RIS_Directivity_Configs)));
                    addOptional(PARSER,'Dir',Default_RIS_Directivity_Config, Valid_RIS_Configs);
                    
                    Valid_RIS_Dimension = @(x) isnumeric(x) && (x>0) && isinteger(int8(x));
                    Default_Nh = 100;
                    Default_Nv = 100;
                    addOptional(PARSER,'Nh',Default_Nh,Valid_RIS_Dimension);
                    addOptional(PARSER,'Nv',Default_Nv,Valid_RIS_Dimension);
                    
                    addOptional(PARSER,'Orientation',defaultOrientation,@ValidOrientations);
                    parse(PARSER,Device,Position,Communication,varargin{:});
                    if ~isnumeric(PARSER.Results.Orientation)
                        Final_Orientation = validatestring(PARSER.Results.Orientation, ExpectedOrienations);
                    else
                        Final_Orientation = PARSER.Results.Orientation';
                    end
                    
                    RIS_Configs.Policy = PARSER.Results.Policy;
                    RIS_Configs.Dir = PARSER.Results.Dir;
                    obj =  Define_RIS(PARSER.Results.Nh, PARSER.Results.Nv, ...
                        PARSER.Results.Orientation, RIS_Configs,Communication,obj);
            end
            Location = PARSER.Results.Position;
            obj.Center = (PARSER.Results.Position(:)).';
            
        end
        
        
        function BS = Define_BS(Type,BS_Orientation_Rad,Communication ,BS)
            %             BS.d = prm.lambda/2;                     % inter-element spacing
            BS.d = Communication.lambda/2;                     % inter-element spacing
            BS.Efficiency = 0.8;
            switch Type
                case  'Donor'
                    BS.Type = 'Donor';
                    BS.NF = 8.5;                     % [dB] noise figure
                    BS.EIRP = 58;
                    BS.Ptx = 35;
                    %                     Object.Tilt = -7;
                    BS.Horizontal_FOV = deg2rad(60);
                    BS.MaxDownSteerElevRad = deg2rad(-15);
                    BS.DownTiltRad = deg2rad(-7);
                    BS.Nh = 16;
                    BS.Nv = 12;
                case  'IAB'
                    BS.Type = 'IAB';
                    BS.NF = 9;                     % [dB] noise figure
                    BS.EIRP = 51;
                    BS.Ptx = 31;
                    BS.MaxDownSteerElevRad = deg2rad(-30);
                    BS.DownTiltRad = deg2rad(-7);
                    BS.Nh = 12;
                    BS.Nv = 8;
                    
            end
            BS.ArrSize = BS.Nh * BS.Nv;
            if isnumeric(BS_Orientation_Rad)
                BS.Orientation = (BS_Orientation_Rad);
            else
                BS.Orientation = BS_Orientation_Rad;
            end
        end
        
        
        function UE = Define_UE(Nh,Nv,Type,band,UEOrientation_Rad,Communication,UE)
            if isnumeric(UEOrientation_Rad)
                UE.Orientation = (UEOrientation_Rad);
            else
                UE.Orientation = UEOrientation_Rad;
            end
            UE.Horizontal_FOV = deg2rad(180);
            UE.MaxDownSteerElevRad = deg2rad(90);
            UE.DownTiltRad = deg2rad(0);
            UE.Type = Type;
            UE.Band = band;
            UE.Ptx = 23;
            UE.Nh = Nh;
            UE.Nv = Nv;
            UE.NF = 10;
            UE.Efficiency = 1;
            UE.ArrSize = UE.Nh * UE.Nv;
            UE.EIRP = UE.Ptx + 10*log10(UE.ArrSize) + 10*log10(UE.Efficiency);
            UE.d = Communication.lambda/2;    % inter-element spacing
            switch Type
                case  'Class1'
                    switch band
                        case  'n257'
                            MinPeak_EIRP = 40; %#ok<*NASGU>
                            Max_TRP = 35;
                            Max_EIRP = 55;
                        case  'n258'
                            MinPeak_EIRP = 40;
                            Max_TRP = 35;
                            Max_EIRP = 55;
                        case  'n260'
                            MinPeak_EIRP = 38;
                            Max_TRP = 35;
                            Max_EIRP = 55;
                        case  'n261'
                            MinPeak_EIRP = 40;
                            Max_TRP = 35;
                            Max_EIRP = 55;
                    end
                    
                case  'Class2'
                    switch band
                        case  'n257'
                            MinPeak_EIRP = 29;
                            Max_TRP = 23;
                            Max_EIRP = 43;
                        case  'n258'
                            MinPeak_EIRP = 29;
                            Max_TRP = 23;
                            Max_EIRP = 43;
                        case  'n260'
                            MinPeak_EIRP = [];
                            Max_TRP = [];
                            Max_EIRP = [];
                        case  'n261'
                            MinPeak_EIRP = 29;
                            Max_TRP = 23;
                            Max_EIRP = 43;
                    end
                    
                    
                case  'Class3'
                    switch band
                        case  'n257'
                            MinPeak_EIRP = 22.4;
                            Max_TRP = 23;
                            Max_EIRP = 43;
                        case  'n258'
                            MinPeak_EIRP = 22.4;
                            Max_TRP = 23;
                            Max_EIRP = 43;
                        case  'n260'
                            MinPeak_EIRP = 20.6;
                            Max_TRP = 23;
                            Max_EIRP = 43;
                        case  'n261'
                            MinPeak_EIRP = 22.4;
                            Max_TRP = 23;
                            Max_EIRP = 43;
                    end
                    
                case  'Class4'
                    switch band
                        case  'n257'
                            MinPeak_EIRP = 34;
                            Max_TRP = 23;
                            Max_EIRP = 43;
                        case  'n258'
                            MinPeak_EIRP = 34;
                            Max_TRP = 23;
                            Max_EIRP = 43;
                        case  'n260'
                            MinPeak_EIRP = 31;
                            Max_TRP = 23;
                            Max_EIRP = 43;
                        case  'n261'
                            MinPeak_EIRP = 34;
                            Max_TRP = 23;
                            Max_EIRP = 43;
                    end
            end
            
            if UE.Ptx > Max_TRP
                error('Transmit power cannot exceed the TRP at this band for this class of UE amplifier')
            elseif UE.EIRP < MinPeak_EIRP
                error('EIRP is less than minimum possible EIRP at this band for this class of UE amplifier, if the transmit power cannot be increases, probabely a larger array is required')
            elseif  UE.EIRP > Max_EIRP
                error('EIRP is more than allowed maximum EIRP at this band for this class of UE amplifier')
            end
        end
        
        
        function AF = Define_AF(Type,AF_Orientation_Rad,Communication,AF)
            AF.Role = 'Relay';
            AF.Horizontal_Alignment_Limit = pi/2;
            AF.Type = Type;
            AF.d = Communication.lambda/2;
            AF.NF = 8;
            AF.MaxDownSteerElevRad = deg2rad(-30);
            AF.DownTiltRad = deg2rad(-5);
            AF.Horizontal_FOV = deg2rad(60);
            switch Type
                case  'Option1'
                    AF.Nh = 12;
                    AF.Nv = 6;
                    AF.Efficiency = 0.4;
                    AF.EIRP_min = 40;
                    AF.EIRP_max = 55;
                    AF.AppGain = 20;
                case  'Option2'
                    AF.Nh = 20;
                    AF.Nv = 12;
                    AF.Efficiency = 0.5;
                    AF.EIRP_min = 40;
                    AF.EIRP_max = 58;
                    AF.AppGain = 26;
            end
            if isnumeric(AF_Orientation_Rad)
                AF.Orientation = (AF_Orientation_Rad);
            else
                AF.Orientation = AF_Orientation_Rad;
            end
            AF.ArrSize = AF.Nh * AF.Nv;
        end
        
        function RIS = Define_RIS(Nh,Nv, RIS_Orientation_rad,RIS_Config,Communication, RIS)
            RIS.Role = 'Relay';
            RIS.Horizontal_FOV = deg2rad(120); % !!!!!!
            RIS.MaxDownSteerElevRad = deg2rad(90);
            RIS.DownTiltRad = deg2rad(0);
            RIS.NF = 0;
            RIS.Type = 'flat';
            RIS.Efficiency = 1;
            RIS.Nh = Nh;
            RIS.Nv = Nv;
            RIS.Nris = RIS.Nh * RIS.Nv ;
            RIS.d = Communication.lambda/4;
            RIS.Config.Policy = RIS_Config.Policy;
            RIS.Config.ElementDirectivity = RIS_Config.Dir;
            if isnumeric(RIS_Orientation_rad)
                RIS.Orientation = RIS_Orientation_rad;
            else
                RIS.Orientation = RIS_Orientation_rad;
            end
        end
        

    end
end