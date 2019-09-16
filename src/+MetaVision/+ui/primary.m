classdef primary < MetaVision.ui.UIContainer
  %primary Displays metadata information attached to each open file.
  events
    loadFile
    loadDirectory
    clearFiles
    requestAbout
    requestSupportedFiles
  end
  
  properties (Constant = true)
    TREE_MAX_WIDTH = 400 %Maximum uitree panel width in pixels.
    TREE_MIN_WIDTH = 100  %Minimum uitree panel width in pixels.
    EMPTY_DATUM = struct('props',{{[],[]}},'notes',{{[],[]}}) % template for nodedata
    PROP_NAME_WIDTH = 145
    NOTE_STAMP_WIDTH = 145
  end
  
  % Properties that correspond to app components
  properties (Access = public)
    FileTree            matlab.ui.container.Tree
    FileMenu            matlab.ui.container.Menu
    OpenFileMenu        matlab.ui.container.Menu
    OpenDirectoryMenu   matlab.ui.container.Menu
    ClearFilesMenu      matlab.ui.container.Menu
    QuitMenu            matlab.ui.container.Menu
    HelpMenu            matlab.ui.container.Menu
    SupportedFilesMenu  matlab.ui.container.Menu
    AboutMenu           matlab.ui.container.Menu
    PropNodes    
    TablesPanel         matlab.ui.container.Panel
    TablesGrid          matlab.ui.container.GridLayout
    PropTable           matlab.ui.control.Table
    NoteTable           matlab.ui.control.Table
  end
  
  
  
  properties (Dependent)
    isclear
    hasnodes
  end
  %% Public methods
  methods
    
    function buildUI(obj,varargin)
      if nargin < 2, return; end
      if obj.isClosed, obj.rebuild(); end
      
      obj.show();
      filesData = [varargin{:}]; % array of structs
      nChild = numel(obj.FileTree.Children);
      obj.recurseInfo(filesData, 'File', obj.FileTree, nChild);
    end
    
    function tf = get.isclear(obj)
      tf = isempty(obj.PropTable.Data) && isempty(obj.NoteTable.Data);
    end
    
    function tf = get.hasnodes(obj)
      tf = ~isempty(obj.PropNodes);
    end
    
    % Destruct View
    function clearView(obj)
      if obj.hasnodes
        cellfun(@delete,obj.PropNodes,'UniformOutput',false);
      end
      if ~obj.isclear
        obj.PropTable.Data = {[],[]};
        obj.NoteTable.Data = {[],[]};
      end
    end
    
  end
  %% Startup and Callback Methods
  methods (Access = protected)
    
    % Startup
    function startupFcn(obj,varargin)
      if nargin < 2, return; end
      obj.buildUI(varargin{:});
    end
    
    % Recursion
    function recurseInfo(obj, S, name, parentNode,ofst)
      if nargin < 5, ofst = 0; end
      for f = 1:length(S)
        if iscell(S)
          this = S{f};
        else
          this = S(f);
        end
        if isfield(this,'Notes')
          noteCell = this.Notes;
          this = rmfield(this,'Notes');
        else
          noteCell = cell(1,2);
        end
        props = fieldnames(this);
        vals = struct2cell(this);
        %find nests
        notNested = cellfun(@(v) ~isstruct(v),vals,'unif',1);
        if ~isfield(this,'File')
          hasName = contains(lower(props),'name');
          if any(hasName)
            nodeName = sprintf('%s (%s)',vals{hasName},name);
          else
            nodeName = sprintf('%s %d', name, f+ofst);
          end
        else
          nodeName = this.File;
        end
        thisNode = uitreenode(parentNode, ...
          'Text', nodeName );
        if any(notNested)
          thisNode.NodeData = struct();
          thisNode.NodeData.props = [props(notNested),vals(notNested)];
        else
          thisNode.NodeData = struct();
          thisNode.NodeData.props = [{},{}];
        end
        % append the notes
        thisNode.NodeData.notes = noteCell;
        % store this node
        obj.PropNodes{end+1} = thisNode;
        
        %gen nodes
        if ~any(~notNested), continue; end
        isNested = find(~notNested);
        for n = 1:length(isNested)
          nestedVals = vals{isNested(n)};
          % if the nested values is an empty struct, don't create a node.
          areAllEmpty = all( ...
            arrayfun( ...
              @(sss)all( ...
                cellfun( ...
                  @isempty, ...
                  struct2cell(sss), ...
                  'UniformOutput', 1 ...
                  ) ...
                ), ...
              nestedVals, ...
              'UniformOutput', true ...
              ) ...
            );
          if areAllEmpty, continue; end
          obj.recurseInfo(nestedVals,props{isNested(n)},thisNode);
        end
      end
    end
    
    % Set Table Data
    function setData(obj,d)
      % set the properties from this node
      props = d.props;
      props(:,2) = arrayfun(@unknownCell2Str,props(:,2),'unif',0);
      obj.PropTable.Data = props;
      lens = cellfun(@length,props(:,2),'UniformOutput',true);
      tWidth = obj.PropTable.Position(3)-127;
      obj.PropTable.ColumnWidth = {obj.PROP_NAME_WIDTH, max([tWidth,max(lens)*6.55])};
      
      % set the notes
      notes = d.notes;
      obj.NoteTable.Data = notes;
      lens = cellfun(@length,notes(:,2),'UniformOutput',true);
      tWidth = obj.NoteTable.Position(3)-127;
      obj.NoteTable.ColumnWidth = {obj.NOTE_STAMP_WIDTH, max([tWidth,max(lens)*6.55])};
      
    end
    
    
    % Construct view
    function createUI(obj)
      import MetaVision.app.*;
      
      w = 1010;
      h = 366;
      pos = centerFigPos(w,h);
      
      obj.container.Position = pos;
      
      treeW = min([floor(w*0.3),obj.TREE_MAX_WIDTH]);
      
      % Create container
      obj.container.Name = sprintf('%s V%s',Info.name,Info.version('major'));
      
      % Create FileMenu
      obj.FileMenu = uimenu(obj.container);
      obj.FileMenu.Text = 'File';

      % Create OpenFileMenu
      obj.OpenFileMenu = uimenu(obj.FileMenu);
      obj.OpenFileMenu.Accelerator = 'O';
      obj.OpenFileMenu.Text = 'Open File...';
      obj.OpenFileMenu.MenuSelectedFcn = @(s,e)notify(obj,'loadFile');

      % Create OpenDirectoryMenu
      obj.OpenDirectoryMenu = uimenu(obj.FileMenu);
      obj.OpenDirectoryMenu.Accelerator = 'D';
      obj.OpenDirectoryMenu.Text = 'Open Directory...';
      obj.OpenDirectoryMenu.MenuSelectedFcn = @(s,e)notify(obj,'loadDirectory');
      
      % Create ClearFilesMenu
      obj.ClearFilesMenu = uimenu(obj.FileMenu);
      obj.ClearFilesMenu.Accelerator = 'K';
      obj.ClearFilesMenu.Text = 'Close Files';
      obj.ClearFilesMenu.MenuSelectedFcn = @(s,e)notify(obj,'clearFiles');
      
      % Create Quit Menu
      obj.QuitMenu = uimenu(obj.FileMenu);
      obj.QuitMenu.Accelerator = 'Q';
      obj.QuitMenu.Text = 'Quit';
      obj.QuitMenu.MenuSelectedFcn = @(s,e)notify(obj,'Close');
      obj.QuitMenu.Separator = 'on';
      
      % Create HelpMenu
      obj.HelpMenu = uimenu(obj.container);
      obj.HelpMenu.Text = 'Help';

      % Create SupportedFilesMenu
      obj.SupportedFilesMenu = uimenu(obj.HelpMenu);
      obj.SupportedFilesMenu.Text = 'Supported Files...';
      obj.SupportedFilesMenu.MenuSelectedFcn = @(s,e)notify(obj,'requestSupportedFiles');
      
      % Create AboutMenu
      obj.AboutMenu = uimenu(obj.HelpMenu);
      obj.AboutMenu.Text = 'About';
      obj.AboutMenu.MenuSelectedFcn = @(s,e)notify(obj,'requestAbout');
      
      % Create FileTree
      obj.FileTree = uitree(obj.container);
      obj.FileTree.FontName = 'Times New Roman';
      obj.FileTree.FontSize = 16;
      obj.FileTree.Multiselect = 'off';
      obj.FileTree.SelectionChangedFcn = @obj.getSelectedInfo;
      obj.FileTree.Position = [10, 10, treeW, h-10-10];
      
      % Create the tables Panel
      obj.TablesPanel = uipanel(obj.container);
      obj.TablesPanel.Position = [treeW+8+10, 10, w-treeW-7-10-10, h-10-10];
      obj.TablesPanel.BackgroundColor = [1,1,1];
      obj.TablesPanel.BorderType = 'none';
      
      % Create the GridLayout
      obj.TablesGrid = uigridlayout(obj.TablesPanel,[1,2]);
      obj.TablesGrid.Padding = [0,0,0,0];
      obj.TablesGrid.ColumnSpacing = 8;
      obj.TablesGrid.ColumnWidth = {'1x','1.5x'};

      % Create PropTable
      obj.PropTable = uitable(obj.TablesGrid);
      obj.PropTable.Layout.Row = 1;
      obj.PropTable.Layout.Column = 1;
      obj.PropTable.ColumnName = {'Property'; 'Value'};
      obj.PropTable.ColumnWidth = {obj.PROP_NAME_WIDTH, 'auto'};
      obj.PropTable.RowName = {};
      obj.PropTable.HandleVisibility = 'off';
      obj.PropTable.ColumnEditable = false;
      obj.PropTable.FontName = 'Times New Roman';
      
      
      % Create NoteTable
      obj.NoteTable = uitable(obj.TablesGrid);
      obj.NoteTable.Layout.Row = 1;
      obj.NoteTable.Layout.Column = 2;
      obj.NoteTable.ColumnName = {'Timestamp'; 'Note'};
      obj.NoteTable.ColumnWidth = {obj.NOTE_STAMP_WIDTH, 'auto'};
      obj.NoteTable.RowName = {};
      obj.NoteTable.HandleVisibility = 'off';
      obj.NoteTable.ColumnEditable = false;
      obj.NoteTable.FontName = 'Times New Roman';
      
      
      % set the container resize fcn
      obj.container.SizeChangedFcn = @obj.containerSizeChanged;
      obj.container.Resize = 'on';
      
      % finally, set the previous known position (sizechanged callback will fire)
      oldPos = obj.position; % gets from stored pref
      obj.position = oldPos; % sets pref and container
    end
    
  end
  
  %% Callback
  methods (Access = private)
    
    % Size changed function: container
    function containerSizeChanged(obj,~,~)
      pos = obj.container.Position;
      w = pos(3);
      h = pos(4);
      treeW = min([floor(w*0.3),obj.TREE_MAX_WIDTH]);
      if treeW < obj.TREE_MIN_WIDTH
        treeW = obj.TREE_MIN_WIDTH;
      end
      obj.FileTree.Position = [10 10 treeW h-10-10];
      obj.TablesPanel.Position = [treeW+8+10, 10, w-treeW-7-10-10, h-10-10];
      
      
      thisProp = obj.PropTable.Data;
      if ~isempty(thisProp)
        lens = cellfun(@length,thisProp(:,2),'UniformOutput',true);
        tWidth = obj.PropTable.Position(3)-127;
        obj.PropTable.ColumnWidth = {obj.PROP_NAME_WIDTH, max([tWidth,max(lens)*6.55])};
      end
      thisNote = obj.NoteTable.Data;
      if ~isempty(thisNote)
        lens = cellfun(@length,thisNote(:,2),'UniformOutput',true);
        tWidth = obj.NoteTable.Position(3)-127;
        obj.NoteTable.ColumnWidth = {obj.NOTE_STAMP_WIDTH, max([tWidth,max(lens)*6.55])};
      end
      
    end
    
    % Selection Node changed.
    function getSelectedInfo(obj,~,evt)
      if ~isempty(evt.SelectedNodes)
        obj.setData(evt.SelectedNodes.NodeData);
      else
        obj.setData(obj.EMPTY_DATUM);
      end
    end
    
    
  end
  %% Preferences
  methods (Access = protected)

   function setContainerPrefs(obj)
      setContainerPrefs@MetaVision.ui.UIContainer(obj);
    end
    
    function getContainerPrefs(obj)
      getContainerPrefs@MetaVision.ui.UIContainer(obj);
    end
    
  end
end