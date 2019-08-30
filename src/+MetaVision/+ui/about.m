classdef about < MetaVision.ui.UIContainer
  %ABOUT Display information about MetaVision
  properties
    Logo
    Headline
    Headline2
    ByLine
    Contents
  end
  
  properties (Access = private)
    listeners = {}
  end
  
  methods (Access = protected)
    
    % Startup
    function startupFcn(obj,varargin)
      import MetaVision.app.Info;
      
      % read css
      cssFile = scriptRead(...
        {fullfile(MetaVision.app.Info.getResourcePath, ...
          'scripts', 'about.css')}, ...
        false, false, '''');
      
      obj.window.executeJS('var css,logoPanel,logo,contentsPanel,contents;');
      aboutText = Info.Summary;
      aboutText = sprintf( ...
        [ ...
          '<p class="lab"><span class="inc b">%s</span> (%s). %s.</p>', ...
          '<p class="lab dec">%s ',...
          '<span class="b">Version %s, developed for %s, by %s.', ...
          '</span> This software is provided as-is under the MIT License. ', ...
          'See the github ', ...
          '<a href="%s" target="_system">repository</a> ', ...
          'for more information.</p>' ...
        ], ...
        aboutText{:});
      iter = 0;
      pause(0.1);
      while true
        try
          % inject css
          obj.window.executeJS( ...
            [ ...
              'if (typeof css === ''undefined'') {',...
              'css = document.createElement("style");', ...
              'document.head.appendChild(css);', ...
              '}' ...
            ]);
          obj.window.executeJS(['css.innerHTML = `',cssFile{1},'`;']);
          % insert logo
          obj.window.executeJS(...
            sprintf(...
            [ ...
              'if (typeof logo === ''undefined'') {',...
                'logo = document.createElement("div");', ...
                'logo.id = "logo";', ...
              '}', ...
              'logo.innerHTML = `%s`;', ...
            ], ...
            fileread( ...
              fullfile( ...
                MetaVision.app.Info.getResourcePath, 'img', 'Irissm.svg' ...
              ) ...
            )) ...
            );
          [~,id] = mlapptools.getWebElements(obj.Logo);
          obj.window.executeJS( ...
            sprintf([ ...
            'logoPanel = dojo.query("[%s = ''%s'']")[0].lastChild;', ...
            'logoPanel.appendChild(logo);' ...
            ], ...
            id.ID_attr, id.ID_val ...
            ) ...
            );
          % find contents panel and insert aboutText
          obj.window.executeJS(...
            sprintf(...
            [ ...
              'if (typeof contents === ''undefined'') {',...
                'contents = document.createElement("div");', ...
                'contents.classList.add("labDiv");', ...
              '}', ...
              'contents.innerHTML = `%s`;', ...
            ], ...
            aboutText) ...
            );
          [~,id] = mlapptools.getWebElements(obj.Contents);
          obj.window.executeJS( ...
            sprintf([ ...
            'contentsPanel = dojo.query("[%s = ''%s'']")[0].lastChild;', ...
            'contentsPanel.appendChild(contents);' ...
            ], ...
            id.ID_attr, id.ID_val ...
            ) ...
            );
        catch x
          %log this
          iter = iter+1;
          if iter > 20, rethrow(x); end
          pause(0.25);
          continue;
        end
        break;
      end
      % add the close listener
      obj.addListener(obj, 'Close', @(s,e)obj.onCloseRequest);
    end
    
    % Construct view
    function createUI(obj)
      % imports
      import MetaVision.app.Info;
      
      pos = obj.position;
      if isempty(pos)
        initW = 500;
        initH = 480;
        pos = centerFigPos(initW,initH);
      end
      obj.position = pos;
      
      initW = pos(3);
      initH = pos(4); %#ok
      
      
      % Container
      obj.container.Name = sprintf('%s v%s',Info.name,Info.version('major'));
      obj.container.Color = [0 0 0];
      
      % Create Logo
      obj.Logo = uipanel(obj.container);
      obj.Logo.ForegroundColor = [0 0 0];
      obj.Logo.BorderType = 'none';
      obj.Logo.BackgroundColor = [0 0 0];
      obj.Logo.Position = [77 124 345 345];

      % Create Contents
      obj.Contents = uipanel(obj.container);
      obj.Contents.BorderType = 'none';
      obj.Contents.BackgroundColor = [0 0 0];
      obj.Contents.Position = [20 15 460 75];

      % Create Headline
      hL = Info.shortName;
      obj.Headline = uilabel(obj.container);
      obj.Headline.HorizontalAlignment = 'right';
      obj.Headline.VerticalAlignment = 'top';
      obj.Headline.FontName = 'Times New Roman';
      obj.Headline.FontSize = 30;
      obj.Headline.FontWeight = 'bold';
      obj.Headline.FontColor = [1 1 1];
      obj.Headline.Position = [80 131 120 50];
      obj.Headline.Text = hL(1:4);
      
      % Headline2
      obj.Headline2 = uilabel(obj.container);
      obj.Headline2.HorizontalAlignment = 'left';
      obj.Headline2.VerticalAlignment = 'bottom';
      obj.Headline2.FontName = 'Times New Roman';
      obj.Headline2.FontSize = 62;
      obj.Headline2.FontWeight = 'bold';
      obj.Headline2.FontColor = [1 1 1];
      obj.Headline2.Position = [200 111 200 90];
      obj.Headline2.Text = hL(5:end);

      % Create ByLine
      obj.ByLine = uilabel(obj.container);
      obj.ByLine.VerticalAlignment = 'bottom';
      obj.ByLine.FontName = 'Times New Roman';
      obj.ByLine.FontWeight = 'bold';
      obj.ByLine.FontAngle = 'italic';
      obj.ByLine.FontColor = [1 1 1];
      obj.ByLine.Position = [215 103 initW-215-10 22];
      obj.ByLine.Text = Info.extendedName;
      
    end
    
    function onCloseRequest(obj)
      obj.hide;
      obj.removeListeners;
      obj.shutdown;
      obj.reset;
    end
    
    function addListener(obj,varargin)
      l = addlistener(varargin{:});
      obj.listeners{end+1} = l;
    end
    
    function removeListeners(obj)
      while ~isempty(obj.listeners)
        delete(obj.listeners{end});
        obj.listeners(end) = [];
      end
    end
    
  end
  
end