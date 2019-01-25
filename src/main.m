function app = main(varargin)
if ispc
  [~,netResult] = system('ping -n 2 8.8.8.8');
  isConnected = ~str2double(netResult(strfind(netResult,'Lost =')+7));
elseif isunix
  [~,netResult] = system('ping -c 2 8.8.8.8');
  isConnected = str2double(netResult(strfind(netResult,'received')-2))>0;
elseif ismac
  [~,netResult] = system('ping -c 2 8.8.8.8');
  isConnected = str2double(netResult(strfind(netResult,'packets received')-2))>0;
else
  isConnected = false;
end

if ~isConnected
  error('Iris DVA 2019 requires an internet connection to operate.');
end

% add the app to the matlab path
addAppToPath();

% Show the busy presenter and app splash while the rest of the app loads
splash = iris.ui.busyShow();
splash.start(sprintf('Iris DVA (c)%s', iris.app.Info.year));

% options
opts = iris.pref.analysis.getDefault();
iris.app.Info.checkDir(opts.OutputDirectory);
iris.app.Info.checkDir(opts.AnalysisDirectory);

% setup data model
dataHandler = iris.data.Handler(varargin{:});

% Build UIs
menuServices = iris.infra.menuServices();
primaryView = iris.ui.primary();

%load views and settings into the applicaiton obj (all listeners in Iris)
app = Iris(dataHandler,primaryView,menuServices);


% App is all ready, kill the splash screen.
splash.stop('Welcome!', 1);
delete(splash);

%launch
app.run();


end

%% helper functions
function addAppToPath()
  paths =                            ...
    strsplit(                        ...
      genpath(                       ...
        iris.app.Info.getAppPath()   ...
      ),                             ...
      ';'                            ...
    );
  paths = paths(~cellfun(@(x)strcmp(x,''),paths,'unif',1));
  spl = strsplit(mfilename('fullpath'),filesep);
  switch spl{length(spl)-1}
    case 'test'
      ignoreFolder = 'main';
    case 'main'
      ignoreFolder = 'test';
  end
  paths = paths(...
    cellfun(...
      @isempty,...
      strfind(paths,[filesep,ignoreFolder]),'unif',1 ...
      )...
    ); %#ok
  %add the appropriate paths for the session
  cellfun(@addpath,paths,'unif',0);
end