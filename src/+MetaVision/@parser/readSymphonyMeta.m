function Meta = readSymphonyMeta(fileName)
  % get h5 info
  info = h5info(fileName);
  % Check symphony version
  attList = [{info.Attributes.Name}',{info.Attributes.Value}'];
  symphonyVersion = attList{strcmpi(attList(:,1), 'version'),2};

  if symphonyVersion < 2
    %symphony v1
    Meta = getMetaV1();
  else
    %symphony v2
    Meta = arrayfun(@getMetaV2, info.Groups, 'UniformOutput', 0);
    Meta = cat(1, Meta{:});
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

%% Version 2
function Meta = getMetaV2(grp)
  % grp is the hdf5 location of the current experiment. If you run multiple
  % 'experiment' types (Our version is is called "Electrophysiology"
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
    sec2str(...
      double(...
        h5readatt(...
          fileName,...
          grp.Name,...
          'startTimeDotNetDateTimeOffsetTicks' ...
        ) ...
      ) * 1e-7 ...
    );
  Meta.EndTime = ...
    sec2str(...
      double(...
        h5readatt(...
          fileName,...
          grp.Name,...
          'endTimeDotNetDateTimeOffsetTicks' ...
        ) ...
      ) * 1e-7 ...
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
      % drop configuration settings as they require symphony installed on the
      % analysis computer.. eff-that.
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
  nSources = length(sources);
  %Meta.Sources = cell(1,nSources);
  for sNum = 1:nSources
    curSource = sources{sNum};
    curName = sources{sNum}.Name;
    label = {h5readatt(fileName,curName,'label')};
    sourceAttr = curSource.Groups( ...
      contains({curSource.Groups.Name}','/source/properties') ...
      ).Attributes;
    Meta.Sources(sNum) = struct( ...
      'Name', label, ...
      'Properties', cell2struct({sourceAttr.Value}',{sourceAttr.Name}') ...
      );
    
    %{
    cell2struct( ...
      [label;{sourceAttr.Value}'], ...
      [{'Name'};{sourceAttr.Name}'] ...
      );
    %}
  end
  Meta.Label = label;
end

end %end of reader

%% Helpers
function [ tString,varargout ] = sec2str( secs, ofst )
  if nargin < 2, ofst = 0; end
  tString = {};
  for tSec = secs(:)'
    h = fix(tSec/60^2);
    hfrac = round(24*(h/24-fix(h/24)),0);
    m = fix((tSec-h*60^2)/60);
    s = fix(tSec-h*60^2-m*60);
    ms = fix((tSec - fix(tSec)) * 10^4);
    tString{end+1,1} = sprintf('%02d:%02d:%02d.%04d',hfrac+ofst,m,s,ms);%#ok<AGROW>
  end
  varargout{1} = tString;
  if length(tString) == 1
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
