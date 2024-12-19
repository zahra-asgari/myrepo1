classdef debug_methods < handle
    %DEBUG_MSG This class provides debug message capabilities, use as
    %superclass only
    properties
        last_line_len
    end

    methods
        function debug_msg(obj,msg,verbose)
            if verbose
                obj.last_line_len = fprintf([msg '\n']);
            end
        end
        function delete_then_debug_msg(obj,msg,verbose)
            if verbose
                fprintf(repmat('\b',1,obj.last_line_len));
                obj.last_line_len = fprintf([msg '\n']);
            end
        end
    end
end


