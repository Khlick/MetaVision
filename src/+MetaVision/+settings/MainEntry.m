classdef MainEntry < MetaVision.core.StoredPrefs
  
  properties
    workingDirectory
  end
  
  methods
   
    function d = get.workingDirectory(obj)
      d = obj.get('workingDirectory', ...
        getenv('UserProfile') ...
        );
    end
    
    function set.workingDirectory(obj,d)
      MetaVision.app.Info.checkDir(d);
      obj.put('workingDirectory', d);
    end
    
  end
  
  methods (Static)
    function d = getDefault()
      persistent default;
      if isempty(default) || ~isvalid(default)
        default = MetaVision.settings.MainEntry();
      end
      d = default;
    end
  end
  
end