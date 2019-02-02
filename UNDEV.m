paths = strsplit(genpath(fileparts(mfilename('fullpath'))),';');
paths = paths(~cellfun(@(x)strcmp(x,''),paths,'unif',1));
ignoreInds = regexp(paths,'(?<=\\)[_\.]+\w*');
paths = paths(cellfun(@isempty,ignoreInds,'UniformOutput',1));
cellfun(@rmpath,paths,'unif',0);
clearvars paths ignoreInds
