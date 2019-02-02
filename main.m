function app = main(varargin)
% add the app to the matlab path
addAppToPath();

% splash screen
about = MetaVision.ui.about();
about.show;
pause(0.5);

tStart = tic;
delay = 5; %6 seconds minimum display of about

% options
primaryView = MetaVision.ui.primary();

%load views and settings into the applicaiton obj (all listeners in Iris)
opts = MetaVision.settings.MainEntry.getDefault();
app = MetaVision.core.MainEntry(primaryView,opts);
app.setAbout(about);

while toc(tStart) < delay
  % wait
end

% kill splash if not manually closed by user.
if ~about.isClosed
  about.shutdown();
end

% launch the application
app.run();

end

%% helper functions
function addAppToPath()
  paths =                            ...
    strsplit(                        ...
      genpath(                       ...
        fileparts(mfilename('fullpath'))   ...
      ),                             ...
      ';'                            ...
    );
  paths = paths(~cellfun(@(x)strcmp(x,''),paths,'unif',1));
  paths = paths(~contains(paths,'\.'));
  
  %add the appropriate paths for the session
  addpath(strjoin(paths,';'));
end