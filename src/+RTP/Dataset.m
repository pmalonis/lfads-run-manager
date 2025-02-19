classdef Dataset < LFADS.Dataset
    methods
        function ds = Dataset(collection, relPath)
            ds = ds@LFADS.Dataset(collection, relPath);
            % you might also wish to set ds.name here,
            % possibly by adding a third argument to the constructor
            % and assigning it to ds.name
        end

        function data = loadData(ds)
            % load this dataset's data file from .path
            data = load(ds.path);
        end

        function loadInfo(ds, reload)
            % Load this Dataset's metadata if not already loaded

            if nargin < 2 
                reload = false;
            end
            if ds.infoLoaded && ~reload, return; end

            % modify this to extract the metadata loaded from the data file
            data = ds.loadData();
            data.subject = data.monkey.name;
            ds.nChannels = sum(contains(fieldnames(data), 'Chan'));
            ds.nTrials = size(data.cpl_st_trial_rew, 1);
            ds.infoLoaded = true;
        end
    end
end

