classdef Info < handle
  methods (Static)
    
    function n = name()
      n = 'MetaVision';
    end
    
    function n = shortName()
      n = [ ...
        native2unicode( ...
        char( ...
          [956,949,964,945] ...
        ) ...
        ), ...
        'Vision' ...
        ];
    end
    
    function n = extendedName()
      n = 'Meta-data viewer for experimental datafiles.';
    end

    function d = description()
      d = [ ...
          'Designed for MATLAB, MetaVision is an Iris DVA extension ', ...
          'for viewing meta-information of experimental data' ...
        ];
    end
    
    function s = site()
      s = 'https://github.com/Khlick/MetaVision';
    end

    function v = version(sub)
      if ~nargin
        sub = 'public';
      end
      status = {1,10,'a'};
      switch sub
        case 'major'
          v = sprintf('%d',status{1});
        case 'minor'
          v = sprintf('%02d',status{2});
        case 'public'
          v = sprintf('%d.%02d',status{1:2});
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
    function [p,varargout] = getFile(title,filter,defaultName,varargin)
      %%GETFILE box title, filterSpec, startDefault
      if nargin < 2
        filter = '*';
      end
      if nargin < 3
        defaultName = '';
      end
      [filename, pathname,fdx] = uigetfile(filter,title,defaultName,varargin{:});
      try
        filename = cellstr(filename);
      catch
        p = [];
        [varargout{1:(nargout-1)}] = deal([]);
        return;
      end
      p = strcat(pathname, filename);
      [varargout{1:(nargout-1)}] = deal(fdx,pathname);
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
        Info.author, ...
        Info.site ...
        };
      
    end
    
    function showWarning(msg)
      st = dbstack('-completenames',1);
      id = upper(strrep(st(1).name,'.', ':'));
      warnCall = sprintf( ...
        'warning(''%s:%s'',''%s'');', ...
        upper(MetaVision.app.Info.name), ...
        id, ...
        msg ...
        );
      eval(warnCall);
    end
    
    function [totalBytes,varargout] = getBytes(file)
      if ischar(file)
        file = {file};
      end
      eachBytes = zeros(length(file),1);
      for f = 1:length(file)
        try %#ok<TRYNC>
          d = dir(file{f});
          eachBytes(f) = double(d.bytes);
        end
      end
      
      totalBytes = sum(eachBytes);
      
      if nargout > 1
        varargout{1} = eachBytes;
      end
    end
    
  end
end

