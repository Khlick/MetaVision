classdef logger < handle
  %LOGGER Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = private)
    className
  end
  
  methods
    
    function obj = logger(cName)
      obj.className = cName;
    end
    
    
    
  end
  
  methods (Access = private)
    function log(obj, type, message, ME)
      msg = sprintf('(%s) >%s', type, message);
      if ~isempty(ME)
        msg = sprintf('%s\n%s', msg, ME.getReport());
      end
      
    end
  end
  
  
end

