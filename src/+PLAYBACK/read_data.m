function data = read_data(mat_data, dt)

    names = fieldnames(mat_data);
    channels = {names{contains(names,'Chan')}};

    T=mat_data.cpl_st_trial_rew(:,2)-mat_data.cpl_st_trial_rew(:,1);
    T = sort(T);
    total = zeros(length(T),1);
    for i=1:length(T)
        total(i) = (length(T)-(i-1))*T(i);
    end

    [~, idx] = max(total);
    trialCutoff = T(idx);
    T = T(idx:end);
    nTrials = length(T);
    nNeurons = length(channels);
    nTime = floor(trialCutoff/dt);
    spikes = zeros(nTrials, nNeurons, nTime);

    binRatio = kin_dt/dt;
    nKinTime = ceil(nTime/binRatio);
    for neuronInd=1:nNeurons
        neuronData = mat_data.(channels{neuronInd});
        trialInd = 1;
        for i = 1:size(mat_data.cpl_st_trial_rew, 1)
            if mat_data.cpl_st_trial_rew(i,2)-mat_data.cpl_st_trial_rew(i,1) < trialCutoff
                continue
            end
            start = mat_data.cpl_st_trial_rew(i, 1);
            stop = start + trialCutoff;
            trialData = neuronData(neuronData > start & neuronData < stop);
            edges = start:dt:stop;
            spikes(trialInd, neuronInd, :) = histcounts(trialData, edges);

%             kinStartInd = find(mat_data.x(:,1) >= start, 1);
%             kinInds = repelem(kinStartInd:kinStartInd+nKinTime-1,binRatio);
%             %in case of odd nTime
%             if length(kinInds) == nTime + 1
%                 kinInds = kinInds(1:end-1);
%             end
%                   
            trialInd = trialInd + 1;
        end
    end
    data.counts = spikes;
    data.timeVecMs = (0:dt:trialCutoff-dt) * 1000;
    data.conditionId = ones(nTrials,1);
    data.externalInputs = 0;
end
