classdef MainEntry < MetaVision.core.Container
  %MAINENTRY Main entry point for MetaVision
  
  properties (Access = private)
    sessionInfo
    about
  end
  
  methods (Access = protected)
    
    function preRun(app)
      if ispc
        app.sessionInfo = struct( ...
          'sessionStart', datestr(now,'YYYY/DD/mmm (hh:MM:ssPM)'), ...
          'sessionEnd', '', ...
          'User', getenv('UserName'), ...
          'Profile', getenv('UserProfile'), ...
          'Domain', getenv('UserDomain') ...
          );
      else
        app.sessionInfo = struct( ...
          'sessionStart', datestr(now,'YYYY/DD/mmm (hh:MM:ssPM)'), ...
          'sessionEnd', '', ...
          'User', getenv('USER'), ...
          'Profile', getenv('HOME'), ...
          'Domain', getenv('LOGNAME') ...
          );
      end
    end
    
    function bind(app)
      bind@MetaVision.core.Container(app);
      % add listeners
      v = app.ui;
      
      app.addListener(v,'loadFile', @app.onRetrieveFiles);
      app.addListener(v,'loadDirectory', @app.onRetrieveDirectory);
      app.addListener(v,'requestAbout', @app.buildAbout);
      app.addListener(v,'requestSupportedFiles', @app.displaySupported);
    end
    
    function preStop(app)
      app.sessionInfo.sessionEnd = datestr(now,'YYYY/DD/mmm (hh:MM:ssPM)');
    end
    
    function postStop(app)
      sIcell = [fieldnames(app.sessionInfo),struct2cell(app.sessionInfo)];
      sIstr = cell(size(sIcell,1),1);
      for r = 1:size(sIcell,1)
        sIstr{r} = strjoin(sIcell(r,:), ': ');
      end
      sIstr = strjoin(sIstr, '\n  ');
      fprintf('MetaVision session info:\n');
      fprintf('  %s\n', sIstr);
    end
    
  end
%% Callbacks
  methods (Access = protected)
    
    function onRetrieveFiles(app,~,~)
      import MetaVision.parser;
      
      filterText = parser.getFilterText();
      
      [files,fIdx,root] = MetaVision.app.Info.getFile( ...
        'Load Files', ...
        filterText, ...
        app.options.workingDirectory, ...
        'multiselect', 'on' ...
        );
      
      if isempty(files)
        app.ui.show();
        return;
      end
      
      app.options.workingDirectory = root;
      
      readerMethod = MetaVision.parser.getReaderFromExtensionLabel(...
        filterText{fIdx,2} ...
        );
      
      app.parseFiles(files,readerMethod);
    end
    
    function onRetrieveDirectory(app,~,~)
      root = MetaVision.app.Info.getFolder(...
        'Select a data folder', ...
        app.options.workingDirectory ...
        );
      if isempty(root)
        app.ui.show();
        return
      end
     app.options.workingDirectory = root;
     
     app.onRetrieveFiles([],[]);
    end
    
    function buildAbout(app,~,~)
      if isempty(app.about)
        app.about = MetaVision.ui.about();
      end
      if app.about.isClosed
        app.about.rebuild();
      end
      if ~app.about.isHidden, return; end
      app.about.show;
    end
    
    function displaySupported(app,~,~)
      labels = MetaVision.parser.getLabels();
      exts = MetaVision.parser.getExtensions();
      supp = cell(length(labels),1);
      for l = 1:length(labels)
        supp{l} = ['Extensions: "',strjoin(exts{l},', '),'", for "', labels{l},'"'];
      end
      
      commandwindow;
      pause(0.1);
      
      fprintf('MetaVision supports the following file types:\n');
      disp(strjoin(supp,'\n'));
      
      pause(2);
      % bring the app to the front
      app.show();
    end
    
  end
  
%% public
  methods
    
    function obj = MainEntry(varargin)
      obj@MetaVision.core.Container(varargin{:});
    end
    
    function setAbout(app,ab)
      app.about = ab;
    end
    
  end

  
%% private
  methods (Access = private)
    
    function parseFiles(app,files,reader)
      import MetaVision.parser;
      
      LS = MetaVision.ui.loadShow();
      LS.show;
      nFiles = length(files);
      loaded = {};
      unread = {};
      for fn = 1:nFiles
        %load file use try?
        try
          loaded{end+1} = feval( ...
            sprintf('MetaVision.parser.%s',reader), ...
            files{fn} ...
            ); %#ok<AGROW>
        catch
          unread{end+1} = files{fn}; %#ok<AGROW>
        end
        %update percentag
        LS.updatePercent(fn/(nFiles+1));
      end
      app.ui.buildUI(loaded);
      LS.updatePercent(1);
      LS.reset;
      delete(LS);
      app.show();
      % dev
      if ~isempty(unread)
        MetaVision.app.Info.showWarning( ...
          sprintf( ...
            'The following %d files not found:\n  "%s"\n\n', ...
            length(unread), ...
            strjoin(unread, ', ') ...
          ) ...
          );  
      end
    end
    
  end
end

