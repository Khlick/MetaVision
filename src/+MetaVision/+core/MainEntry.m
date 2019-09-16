classdef MainEntry < MetaVision.core.Container
  %MAINENTRY Main entry point for MetaVision
  
  properties (Access = private)
    sessionInfo
    currentList
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
      app.addListener(v,'clearFiles', @app.onClearFiles);
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
      readers = rep({readerMethod},numel(files));
      
      app.parseFiles(files,readers);
    end
    
    function onClearFiles(app,~,~)
      app.currentList = [];
      app.ui.clearView();
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
      import MetaVision.parser.*;
      
      % check against 
      files = setdiff(files,app.currentList);
      
      % collect byte information from files
      [totalDataSize,eachFileSize] = MetaVision.app.Info.getBytes(files);
      accDataRead = 0;

      LS = MetaVision.ui.loadShow();
      LS.updatePercent('Parsing files...');
      pause(1);

      nf = numel(files);

      POOL = gcp('nocreate');
      if isempty(POOL) && nf > 1
        fprintf('Please, be patient while we connect to a parallel pool.\n');
        POOL = parpool('local');
        pause(0.1);
      end

      skipped = cell(nf,2);
      S = cell(1,nf);
      if ~iscell(files), reader = cellstr(files); end
      if ~iscell(reader), reader = cellstr(reader); end
      
      if nf == 1
        
        try
          S{1} = feval( ...
            str2func(reader{1}), ...
            files{1} ...
            );
        catch er
          [~,fname,~] = fileparts(files{1});
          skipped(1,:) = [{fname},{[er.identifier,' => ', er.message]}];
        end
        
      else
        
        % using parallel pool
        % build future calls
        futures(nf) = parallel.FevalFuture;
        for I = 1:nf
          futures(I) = parfeval(POOL, ...
            str2func(reader{I}), ...
            1, ... % N outputs
            files{I} ... % input to reader
            );
        end
        
        % collect from futures
        for I = 1:nf
          [cIdx,S_par] = futures.fetchNext();
          S{cIdx} = S_par;
          if isempty(S_par)
            [~,fname,~] = fileparts(files{cIdx});
            er = futures(cIdx).Error;
            skipped(cIdx,:) = [{fname},{[er.identifier,' => ', er.message]}];
          end
          accDataRead = accDataRead + eachFileSize(cIdx);
          if accDataRead/totalDataSize < 1
            LS.updatePercent(accDataRead/totalDataSize,'Parsing...');
          end
        end

      end
      LS.updatePercent('Done!');
      pause(1.3);
      
      % build the UI
      app.ui.buildUI(S{:});
      
      LS.shutdown();
      LS.reset();
      delete(LS);
      
      app.show();
      
      %%% Check skipped and report:
      skippedSlots = cellfun(@isempty, S, 'UniformOutput', true);
      skipped = skipped(skippedSlots,:);

      if ~isempty(skipped)
        fprintf('\nThe Following files were skipped:\n');
        for ss = 1:size(skipped,1)
          fprintf('  File: "%s"\n    For reason: "%s".\n', skipped{ss,:});
        end
      end
      
      app.currentList = files(~skippedSlots);
    end
    
  end
end

