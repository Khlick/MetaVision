classdef (Abstract) Container < handle
  
  events
    didStop
  end
  
  properties (SetAccess = private)
    isStopped
  end
  
  properties (SetAccess = protected)
    ui        MetaVision.ui.primary
    options
  end
  
  properties (Access = private)
    listeners
  end
  
  methods
    
    %Constructor
    function obj = Container(view,options)
      if nargin < 2
        cName = regexp(class(obj), '(?<=\.)\w*$', 'match', 'once');
        try
          options = MetaVision.settings.(cName);
        catch
          options = [];
        end
      end
      if nargin < 1
        view = MetaVision.ui.primary();
      end
      obj.ui = view;
      obj.listeners = cell(0);
      obj.options = options;
    end
    
    function delete(obj)
      if ~obj.isStopped
        obj.stop();
      end
    end
    
    function run(obj)
      obj.preRun;
      obj.bind;
      obj.show;
      obj.postRun;
    end
    
    function stop(obj)
      obj.preStop;
      obj.unbind;
      obj.close;
      obj.isStopped = true;
      obj.postStop;
      notify(obj,'didStop');
    end
    
    function show(obj)
      obj.ui.show;
    end
    
  end
  
  methods (Access = protected)
    % overwrite these methods to control running procedures
    function preRun(obj) %#ok
    end
    
    function postRun(obj) %#ok
    end
    
    function preStop(obj) %#ok
    end
    
    function postStop(obj) %#ok
    end
    
    function close(obj)
      if isempty(obj.ui), return; end
      try
        % try a safe shutdown
        obj.ui.shutdown;
      catch
        % or just delete the object
        delete(obj.ui)
      end
    end
    
    function bind(obj)
      L = obj.ui;
      obj.addListener(L,'Close',@obj.onUIClose);
    end
    
    function unbind(obj)
      obj.removeAllListeners();
    end
    
    function l = addListener(obj, varargin)
      l = addlistener(varargin{:});
      obj.listeners{end+1} = l;
    end
    
    function removeListener(obj,listener)
      loc = ismember(...
        cellfun(@(l)l.EventName, obj.listeners,'unif',0),...
        listener.EventName);
      if ~any(loc), disp('Listener non-existent'); end
      delete(listener)
      obj.listeners(loc) = [];
    end
    
    function removeAllListeners(obj)
      while ~isempty(obj.listeners)
        delete(obj.listeners{1});
        obj.listeners(1) = [];
      end
    end
    
    function enableListener(obj, listener)
      loc = ismember(...
        cellfun(@(l)l.EventName, obj.listeners, 'unif',0),...
        listener.EventName);
      if ~any(loc), disp('Listener non-existent'); end
      obj.listeners{loc}.Enabled = true;
    end
    
    function disableListener(obj,listener)
      loc = ismember(...
        cellfun(@(l)l.EventName, obj.listeners,'unif',0),...
        listener.EventName);
      if ~any(loc), disp('Listener non-existent'); end
      obj.listeners{loc}.Enabled = false;
    end
    
    function enableAllListeners(obj)
      for o = 1:length(obj.listeners)
        obj.listeners{o}.Enabled = true;
      end
    end
    
    function disableAllListeners(obj)
      for o = 1:length(obj.listeners)
        obj.listeners{o}.Enabled = false;
      end
    end
    
    % override this function to handle ui close event
    function onUIClose(obj,~,~)
      obj.stop;
    end
    
  end
  
end

