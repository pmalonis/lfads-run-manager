addpath('..')
run('RTP.drive_script.m')

run_name = 'single_rockstar';

runs = rc.findRuns(run_name);

for i = 1:length(runs)
    pm = runs(i).loadPosteriorMeans();
    save([runs(i).path '/posterior_means.mat'], 'pm');
end