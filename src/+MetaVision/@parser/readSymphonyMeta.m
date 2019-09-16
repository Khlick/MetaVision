function Meta = readSymphonyMeta(fileName)
% get h5 info
info = h5info(fileName);
% Check symphony version
attList = [{info.Attributes.Name}',{info.Attributes.Value}'];
symphonyVersion = attList{strcmpi(attList(:,1), 'version'),2};

if symphonyVersion < 2
  %symphony v1
  Meta = getMetaV1();
  Notes = getNotesV1();
  Meta(1).Notes = Notes;
else
  %symphony v2
  Meta = arrayfun(@getMetaV2, info.Groups, 'UniformOutput', true); % returns 1x1 cell
  Meta = cat(1, Meta{:}); % struct array
  Notes = arrayfun(@getNotesV2, info.Groups, 'UniformOutput', false);
  Notes = cat(1,Notes{:}); % 1 x nExp of nNote x 2 cells
  % set notes into meta
  nExperiments = length(info.Groups);
  [Meta(1:nExperiments).Notes] = Notes{:};
end
% return from here

%%% FUNCTIONS -------------------------------------------------------->

%% Version 1
function Meta = getMetaV1()
  Meta = struct();
  % cellProperties = info.Groups.Groups;
  % cellAttributes = cellProperties(3).Attributes; % XXX indexing issue?
  % numerical index values, derived from cellAttributes(1:3).Name
  % 1. SourceID (i.e., 'WT')
  % 2. cellID (but we'll use fileName instead)
  % 3. rigName (which never changes and isn't used - omit until a problem occurs)

  rootName = info.Groups.Name;
  % /properties, /epochs, /epochGroups
  % Gather some manual information from groups
  tmp = cell2struct(...
    {info.Groups(end).Attributes(ismember({info.Groups(end).Attributes.Name}', ...
                                          {'label','keywords'})).Value, ...
     info.Groups(end).Groups(3).Attributes(...
       ismember({info.Groups(end).Groups(3).Attributes.Name}', ...
                'sourceID')).Value...
    }', ...
    {info.Groups(end).Attributes(ismember({info.Groups(end).Attributes.Name}', ...
                                          {'label','keywords'})).Name, ...
     info.Groups(end).Groups(3).Attributes(...
       ismember({info.Groups(end).Groups(3).Attributes.Name}', ...
                'sourceID')).Name...
    }');
  Meta.Label = tmp.label;
  % Keywords from file
  try
    Meta.Keywords = tmp.keywords;
  catch
    Meta.Keywords = '';
  end
  % Source ID
  Meta.SourceID = tmp.sourceID;
  % user-chosen identifier for the cell
  Meta.FullFile = fileName;
  % XXX hard-code now, get from user later
  Meta.CellType = 'unknown'; 
  % Additional properties
  Meta.ExperimentStartTime = sec2str( ...
    double(h5readatt(fileName, ...
      rootName, ...
      'startTimeDotNetDateTimeOffsetUTCTicks' ...
    ))*1e-7 ...
    );
  Meta.cellID = h5readatt(fileName, [rootName,'/properties'], 'cellID');
 
  % XXX hard-code now, get from user later
  Meta.OutputConfiguration = {'amp'; 'red'; 'orange'; 'blue'}; 
  % XXX hard-code now, get from user later
  Meta.OutputScaleFactor = {0; 19.3000; 30; 21}; 
  % XXX hard-code now, get from user later
  Meta.NDFConfiguration = {0; 0; 0; 0}; 
  % this is necessary for analysis program
  Meta.FamilyCondition.Label = {'Label'}; 
  % ??, copied from Kate's example CellInfo struct
  Meta.FamilyCondition.FamilyStepGuide = {'StmAmp'}; 
  % ??, copied from Kate's example CellInfo struct
  Meta.FamilyCondition.FamilyCueGuide = []; 
  % ??, copied from Kate's example CellInfo struct
  Meta.FamilyCondition.SegNum = 0;
  % ??, copied from Kate's example CellInfo struct
  Meta.FamilyCondition.PlotPref = 1;
  % ??, copied from Kate's example CellInfo struct
  Meta.FamilyCondition.ScaleFactorIndex = [];
  % ??, copied from Kate's example CellInfo struct
  Meta.FamilyCondition.DecimatePts = 1;
  % ??, copied from Kate's example CellInfo struct
  Meta.FamilyCondition.UserInfo = [];
  
end %meta
function Notes = getNotesV1()
  %load the xml file
  [root,name,~] = fileparts(fileName);
  Notes = cell(1,2);
  try
    xmlFile = search_recurse([name,'_metadata'], 'root', root, 'ext', {'.xml'});
  catch 
    return;
  end
  Notes = XML2Notes(xmlFile);
end %notes

%% Version 2
function Meta = getMetaV2(grp)
  % grp is the hdf5 location of the current experiment. If you run multiple
  % 'experiment' types (Our version is is called "Electrophysiology") it will be
  % be aa cell array of multiple experiments (see the header of this function).
  [root,label,ext] = fileparts(fileName);
  % fing group's properties
  prpIndex = contains({grp.Groups.Name}', '/properties');
  Meta = cell2struct(...
    [ ...
      { ...
        [label,ext]; ...
        root ...
      }; ...
      { ...
        grp.Groups(prpIndex).Attributes.Value ...
      }' ...
    ], ...
    [ ...
      {'File';'Location'}; ...
      {grp.Groups(prpIndex).Attributes.Name}' ...
    ] ...
    );
  Meta.StartTime = ...
    sec2str( ...
      h5readatt(...
        fileName,...
        grp.Name,...
        'startTimeDotNetDateTimeOffsetTicks' ...
        ), ...
      h5readatt(...
        fileName,...
        grp.Name,...
        'startTimeDotNetDateTimeOffsetOffsetHours' ...
        ) ...
    );
  Meta.EndTime = ...
    sec2str( ...
      h5readatt(...
        fileName,...
        grp.Name,...
        'endTimeDotNetDateTimeOffsetTicks' ...
        ), ...
      h5readatt(...
          fileName,...
          grp.Name,...
          'endTimeDotNetDateTimeOffsetOffsetHours' ...
        ) ...
    );
  Meta.Purpose = h5readatt(fileName,grp.Name,'purpose');
  Meta.SymphonyVersion = h5readatt(fileName,info.Name,'symphonyVersion');
  % devices
  prpIndex = contains({grp.Groups.Name}', '/devices');
  deviceInfo = grp.Groups(prpIndex).Groups;
  nDevices = length(deviceInfo);
  %Meta.Devices = cell(1,nDevices);
  Meta.Devices = struct( ...
    'Name', '', ...
    'Manufacturer', '', ...
    'Resources', struct('name', '', 'value', []) ...
    );
  for deviceNum = 1:nDevices
    curName = deviceInfo(deviceNum).Name;
    tmpStr = struct();
    try
      tmpStr.Name = h5readatt(fileName,curName,'name');
    catch
      tmpStr.Name = sprintf('Device_%d',deviceNum);
    end
    
    try
      tmpStr.Manufacturer = h5readatt(fileName,curName,'manufacturer');
    catch
      tmpStr.Manufacturer = 'Unknown';
    end
    % add Resources here once I figure out how to capture them
    try
      resourceInfo = h5info(fileName,[curName,'/resources']);
      resourceTypes = arrayfun( ...
        @(rc) h5readatt(fileName,rc.Name,'name'), ...
        resourceInfo.Groups, ...
        'UniformOutput', 0 ...
        );
      % drop configuration settings ... ? Not sure if this is needed. Would like
      % to know config defaults.
      resourceInfo = resourceInfo.Groups( ...
        ~ismember(resourceTypes,'configurationSettingDescriptors') ...
        );
      resourceTypes = resourceTypes( ...
        ~ismember(resourceTypes,'configurationSettingDescriptors') ...
        );
      for g = 1:length(resourceInfo)
        rData = getArrayFromByteStream(h5read(fileName,[resourceInfo(g).Name,'/data']));
        tmpStr.Resources(g) = struct( ...
          'name', resourceTypes{g}, ...
          'value', rData ...
          );
      end
    catch
      tmpStr.Resources = struct('name', '', 'value', []);
    end
    if ~isfield(tmpStr,'Resources')
      tmpStr.Resources = struct('name', '', 'value', []);
    end
    Meta.Devices(deviceNum) = tmpStr;
  end
  prpIndex = contains({grp.Groups.Name}', '/sources');
  sourceLinks = grp.Groups(prpIndex).Links;
  sources = arrayfun( ...
    @(lnk)h5info(fileName,lnk.Value{1}), ...
    sourceLinks, ...
    'UniformOutput', 0 ...
    );
  nSources = numel(sources);
  S = cell(nSources,1);
  for sNum = 1:nSources
    curSource = sources{sNum};
    S{sNum} = recurseSources(curSource);
  end
  Meta.Sources = [S{:}];
  Meta.Label = label;
  Meta = {Meta};%make a cell
  
  % helper recursive function
  function S = recurseSources(thisSource,label)
    if nargin < 2, label = ''; end
    thisName = thisSource.Name;
    thisLabel = {label,h5readatt(fileName,thisName,'label')};
    thisLabel(cellfun(@isempty,thisLabel,'UniformOutput',1)) = [];
    thisLabel = strjoin(thisLabel,' > ');
    propsInds = endsWith({thisSource.Groups.Name}','/properties');
    thisAttr = thisSource.Groups(propsInds).Attributes;
    S = struct( ...
      'Name', {thisLabel}, ...
      'Properties', cell2struct({thisAttr.Value}',{thisAttr.Name}') ...
      );
    subIdx = contains({thisSource.Groups.Name},'/sources');
    if ~any(subIdx), return; end
    subLinks = thisSource.Groups(subIdx).Links;
    if isempty(subLinks), return; end
    S = [ ...
      S, ...
      arrayfun( ...
        @(lnk) ...
          recurseSources(h5info(fileName,lnk.Value{1}),thisLabel), ...
        subLinks, ...
        'UniformOutput', true ...
        ) ...
      ];
  end
end
function Notes = getNotesV2(nfo)
  %nfo = info.Groups;
  %experiment notes come from nfo+'/notes'
  experimentNotes = struct('time',{''},'text',{''});
  try %#ok<TRYNC>
    data = h5read(fileName,[nfo.Name,'/notes']);
    [~,experimentNotes.time] = sec2str(data.time.ticks,data.time.offsetHours(1));
    experimentNotes.text = data.text;
  end
  
  %source notes
  sourceIndex = contains({nfo.Groups.Name}', '/sources');
  sourceGroups = nfo.Groups(sourceIndex); 
  sourceNotes(1:numel(sourceGroups.Groups),1) = struct('time',{''},'text',{''});
  if numel(sourceNotes) > 0
    for g = 1:numel(sourceGroups.Groups)
      try
        data = h5read(fileName,[sourceGroups.Groups(g).Name,'/notes']);
      catch
        continue
      end
      [~,sourceNotes(g).time] = sec2str(data.time.ticks,data.time.offsetHours(1));
      sourceNotes(g).text = data.text;
    end
  end

  %epochGroup notes
  groupIndex = ~cellfun(@isempty,...
    strfind({nfo.Groups.Name}', '/epochGroups'),'unif',1); %#ok
  epochGroups = nfo.Groups(groupIndex);
  blockNotes = struct('time',{''},'text',{''});
  if numel(epochGroups.Groups) > 0 
    % first get from group
    epochNotes = getNoteStruct({epochGroups.Groups.Name}');
    % then look for each experiment
    for I = 1:numel(epochGroups.Groups)
      epochBlockIndex = ~cellfun(@isempty,...
        strfind({epochGroups.Groups(I).Groups.Name}', '/epochBlocks'),'unif',1); %#ok
      epochBlocks = epochGroups.Groups(I).Groups(epochBlockIndex);
      % get each experiment for this epoch block
      try %#ok<TRYNC>
        blockNotes = [blockNotes;getNoteStruct({epochBlocks.Groups.Name}')];%#ok<AGROW>
      end
    end
  end

  Notes = cat(2,...
      cat(1,... %add times
        experimentNotes.time, ...
        sourceNotes.time, ...
        epochNotes.time, ...
        blockNotes.time ...
      ),...
      cat(1,... %add note texts
        experimentNotes.text, ...
        sourceNotes.text, ...
        epochNotes.text, ...
        blockNotes.text ...
      )...
    );
  if ~numel(Notes)
    Notes = {[{''},{''}]};
    return
  end
  [~,sid] = sort(Notes(:,1));
  Notes = {Notes(sid,:)};
  
  % HELPER FXN
  function nStruct = getNoteStruct(loc)
    if ~iscell(loc)
      loc = cellstr(loc);
    end
    nStruct(1:numel(loc),1) = struct('time',{''},'text',{''});
    for L = 1:numel(loc)
      try
        notedata = h5read(fileName,[loc{L},'/notes']);
      catch
        continue
      end
      [~,nStruct(L).time] = sec2str(notedata.time.ticks,notedata.time.offsetHours(1));
      nStruct(L).text = notedata.text;
    end
  end
end %notes  

end %end of reader

%% Helpers
function [ tString,varargout ] = sec2str( secs, ofst )
  if nargin < 2, ofst = 0; end
  % offset is the number of hours from UTC
  ofst = 60^2 * ofst;
  tString = cell(numel(secs),1);
  for i = 1:numel(secs)
    thisTick = uint64(double(secs(i))+ofst);
    tString{i} = datestr( ...
      datetime( ...
        thisTick, ...
        'ConvertFrom', '.net' ...
        ), ...
      'mmm-DD-YYYY HH:MM:SS.FFF' ...
      );
    %{
    h = fix(tSec/60^2);
    hfrac = round(24*(h/24-fix(h/24)),0);
    m = fix((tSec-h*60^2)/60);
    s = fix(tSec-h*60^2-m*60);
    ms = fix((tSec - fix(tSec)) * 10^4);
    tString{end+1,1} = sprintf('%02d:%02d:%02d.%04d',hfrac+ofst,m,s,ms);%#ok<AGROW>
    %}
  end
  varargout{1} = tString;
  if numel(tString) == 1
    tString = tString{:};
  end
end

function tsec = str2sec(str)%#ok
  spt = strsplit(str,':');
  nums = str2double(flipud(spt(:))); %s,m,h now
  tsec = 0;
  for nn = 1:length(nums)
    tsec = nums(nn)*60^(nn-1) + tsec;
  end
end

function notesCell = XML2Notes(filename)

  try
    theStruct = parseXML(filename);
  catch
    notesCell = cell(1,2);
    return
  end

  noteStruct = [theStruct.Children(~cellfun(@isempty, ...
    regexp({theStruct.Children.Name}','notes'))).Children];
  noteStruct = noteStruct(~arrayfun(@(x) strcmpi(x.Name, '#text'), noteStruct));
  notesCell = [arrayfun(@(x)x.Attributes.Value, noteStruct, 'uniformout', false);...
    arrayfun(@(x)x.Children.Data, noteStruct, 'uniformout', false)]';

  if isempty(notesCell)
    notesCell = cell(1,2);
    return; 
  end

  % Now let's fix the time column (theres probably a better way than this)
  splitTC = cellfun(@(x)strsplit(x, ' '), notesCell(:,1), 'unif', false);
  splitTime = cellfun(@(x)datevec([x{2:3}],'HH:MM:SSPM'), splitTC, 'unif', false);
  fixedTime = cellfun(@(x)num2str(x(4:6),'%02d:%02d:%02d'), ...
    splitTime, 'unif', false);
  notesCell(:,1) = strcat(cellfun(@(x)x{1}, splitTC, 'unif', false), ' @ ', fixedTime);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% XML PARSER %%%%%%%%%%%%%%%%%%%%%%%%
  function theStruct = parseXML(filename)
    % PARSEXML Convert XML file to a MATLAB structure.
    try
       tree = xmlread(filename);
    catch
       error('Failed to read XML file %s.',filename);
    end

    % Recurse over child nodes. This could run into problems 
    % with very deeply nested trees.
    try
       theStruct = parseChildNodes(tree);
    catch
       error('Unable to parse XML file %s.',filename);
    end
  end

  % ----- Local function PARSECHILDNODES -----
  function children = parseChildNodes(theNode)
    % Recurse over node children.
    children = [];
    if theNode.hasChildNodes
       childNodes = theNode.getChildNodes;
       numChildNodes = childNodes.getLength;
       allocCell = cell(1, numChildNodes);

       children = struct(             ...
          'Name', allocCell, 'Attributes', allocCell,    ...
          'Data', allocCell, 'Children', allocCell);

        for count = 1:numChildNodes
            theChild = childNodes.item(count-1);
            children(count) = makeStructFromNode(theChild);
        end
    end
  end
  % ----- Local function MAKESTRUCTFROMNODE -----
  function nodeStruct = makeStructFromNode(theNode)
    % Create structure of node info.

    nodeStruct = struct(                        ...
       'Name', char(theNode.getNodeName),       ...
       'Attributes', parseAttributes(theNode),  ...
       'Data', '',                              ...
       'Children', parseChildNodes(theNode));

    if any(strcmp(methods(theNode), 'getData'))
       nodeStruct.Data = char(theNode.getData); 
    else
       nodeStruct.Data = '';
    end
  end

  % ----- Local function PARSEATTRIBUTES -----
  function attributes = parseAttributes(theNode)
  % Create attributes structure.

    attributes = [];
    if theNode.hasAttributes
       theAttributes = theNode.getAttributes;
       numAttributes = theAttributes.getLength;
       allocCell = cell(1, numAttributes);
       attributes = struct('Name', allocCell, 'Value', ...
                           allocCell);

       for count = 1:numAttributes
          attrib = theAttributes.item(count-1);
          attributes(count).Name = char(attrib.getName);
          attributes(count).Value = char(attrib.getValue);
       end
    end
  end
end
