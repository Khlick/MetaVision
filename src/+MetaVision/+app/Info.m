classdef Info < handle
  methods (Static)
    
    function n = name()
      n = 'MetaVision';
    end
    
    function n = extendedName()
      n = 'Meta-data viewer for experimental datafiles.';
    end

    function d = description()
      d = [ ...
          'Designed for MATLAB, MetaVision is an Iris DVA extension ', ...
          'for viewing meta-information of experimental data.' ...
        ];
    end

    function v = version(sub)
      if ~nargin
        sub = 'public';
      end
      status = {1,0,'a'};
      switch sub
        case 'major'
          v = sprintf('%d',status{1});
        case 'minor'
          v = sprintf('%02d',status{2});
        otherwise
          v = sprintf('%d.%02d%s',status{1},status{2},status{3});
      end
    end

    function o = owner()
      o = 'Sampath Lab, UCLA';
    end
    
    function a = author()
      a = 'Khris Griffis';
    end
    
    function y = year()
      y = '2019';
    end
    
    function loc = getResourcePath()
      loc  = fullfile(...
        fileparts(...
          fileparts(...
            fileparts(...
              mfilename('fullpath')...
            )...
          )...
        ),...
        'resources');
    end
    
    function loc = getAppPath()
      loc  = ...
        fileparts(...
          fileparts(...
            fileparts(...
              fileparts(...
                mfilename('fullpath')...
              )...
            )...
          )...
        );
      
    end
    
    function loc = getUserPath()
      if ispc
        loc = [getenv('HOMEDRIVE'),getenv('HOMEPATH')];
      else
        loc = getenv('HOME');
      end
    end
    
    %Get file
    function p = getFile(title, filter, defaultName)
      %%GETFILE box title, filterSpec, startDefault
      if nargin < 2
        filter = '*';
      end
      if nargin < 3
        defaultName = '';
      end
      [filename, pathname] = uigetfile(filter, title, defaultName);
      if ~all(filename)
        p = [];
        return;
      end
      p = fullfile(pathname, filename);
    end
    
    %Get folder
    function p = getFolder(Title, StartLocation)
      if nargin < 2
        StartLocation = MetaVision.app.Info.getUserPath;
      end
      p = uigetdir(StartLocation, Title);
      if ~ischar(p)
        p = '';
        return
      end
    end
    
    %
    function checkDir(pathname)
      [s,mg,~] = mkdir(pathname);
      if ~s
        error('METAVISION:CHECKDIR',mg);
      end
    end
    
    function t = Summary()
      import MetaVision.app.Info;
      
      t = { ...
        Info.name, ...
        Info.year, ...
        Info.extendedName, ...
        Info.description, ...
        Info.version('public'), ...
        Info.owner, ...
        Info.author ...
        };
      
    end
    
  end
end

