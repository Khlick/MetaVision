classdef (Abstract) parser
  
  methods (Access = public, Static = true)
    
    function list = supported(num)
      if nargin < 1, num = []; end
      % Add new array entry when supported file reader becomes available
      list(1) = struct( ...
        'type', 'symphony', ...
        'label', 'Symphony Data File', ...
        'exts', {{'h5'}}, ...
        'reader', 'readSymphonyMeta' ...
        );
      list(2) = struct( ...
        'type', 'iris session', ...
        'label', 'Iris Session File', ...
        'exts', {{'isf'}}, ...
        'reader', 'readIrisSessionMeta' ...
        );
      if isempty(num), return; end
      list = list(num);
    end
    
    function labels = getLabels()
      labels = {MetaVision.parser.supported().label}';
    end
    
    function extensions = getExtensions()
      extensions = {MetaVision.parser.supported().exts}';
    end
    
    function  filtStr = getFilterText()
      exts = MetaVision.parser.getExtensions();
      extID = cellfun(@(e) strjoin(strcat('*.', e),';'), exts, 'unif', 0);
      extLab = strcat( ...
        MetaVision.parser.getLabels(), ...
        ' (', ...
        cellfun(@(e) strjoin(strcat('*.', e),','), exts, 'unif', 0), ...
        ')' ...
        );
      filtStr = [extID,extLab];
    end
    
    function r = getReaderFromExtensionLabel(label)
      exts = MetaVision.parser.getExtensions();
      labs = strcat( ...
        MetaVision.parser.getLabels(), ...
        ' (', ...
        cellfun(@(e) strjoin(strcat('*.', e),','), exts, 'unif', 0), ...
        ')' ...
        );
      r = MetaVision.parser.supported(find(strcmp(labs,label),1,'first')).reader;
    end
    
  end
  
%% Reader Methods
% Add your reader function file to the directory, then add the call
% signature here and update the supported() method.
  methods (Static)
    
    info = readSymphonyMeta(fileName)
    
    info = readIrisSessionMeta(fileName)
  end
  
end

