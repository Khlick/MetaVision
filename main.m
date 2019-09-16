function app = main(varargin)
% add the app to the matlab path
addAppToPath();

pause(0.05);
import MetaVision.ui.*;
import MetaVision.*;

% splash screen
splash = about();
splash.show;
pause(0.5);

cleanup = onCleanup(@() splash.shutdown() );

p = gcp('nocreate');

if isempty(p)
  fprintf('Please, be patient while we connect to a local parallel pool.\n');
  p = parpool('local');
  % setting the idle timeout to something pretty long
  p.IdleTimeout = 30;
  delay = 2; %reduce the wait time for the splash to show
else
  delay = 5; %6 seconds minimum display of about
end

tStart = tic;

% options
primaryView = primary();

%load views and settings into the applicaiton obj (all listeners in Iris)
opts = settings.MainEntry.getDefault();
app = core.MainEntry(primaryView,opts);
app.setAbout(splash);

while toc(tStart) < delay
  % wait
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