classdef MainEntry < MetaVision.core.Container
  %MAINENTRY Main entry point for MetaVision
  
  properties (Access = private)
    sessionInfo
  end
  
  methods (Access = protected)
    
    function preRun(app)
      app.sessionInfo = struct( ...
        'sessionStart', datestr(now,'YYYY/DD/mmm (hh:MM:ssPM)'), ...
        'sessionEnd', '', ...
        'User', getenv('UserName'), ...
        'Profile', getenv('UserProfile'), ...
        'Domain', getenv('UserDomain') ...
        ); 
    end
    
    function bind(app)
      bind@MetaVision.core.Container(app);
      % add listeners
    end
    
    function preStop(app)
      app.sessionInfo.sessionEnd = datestr(now,'YYYY/DD/mmm (hh:MM:ssPM)');
    end
    
    
  end
%% Callbacks
  methods (Access = protected)
    
    
    
  end
  
end

