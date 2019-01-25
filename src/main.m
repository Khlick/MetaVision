function app = main(varargin)
% add the app to the matlab path
addAppToPath();

% options
opts = MetaVision.settings.MainEntry.getDefault();
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