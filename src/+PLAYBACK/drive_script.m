%% This script walks through running LFADS on a single Lorenz dataset
%% Generate synthetic Lorenz datasets

% build the dataset collection
datasetPath = '../../data/raw/';

%% Locate and specify the datasets
dc = PLAYBACK.DatasetCollection(datasetPath);
dc.name = 'mack'

% add individual datasets
%PLAYBACK.Dataset(dc, '300_trial_rockstar.mat');
%PLAYBACK.Dataset(dc, '400_trial_rockstar.mat');
%PLAYBACK.Dataset(dc, '500_trial_rockstar.mat');
%PLAYBACK.Dataset(dc, '600_trial_rockstar.mat');
PLAYBACK.Dataset(dc, 'mk08011M1m.mat');
%PLAYBACK.Dataset(dc, 'raju_M1.mat');
%PLAYBACK.Dataset(dc, 'raju_PMd.mat');

%% Build RunCollection - first a single run

% Run a single model for each of the datasets
runRoot = '../../data/model_output';
rc = PLAYBACK.RunCollection(runRoot, 'new_param_test', dc);

% replace this with the date this script was authored as YYYYMMDD
% This ensures that updates to lfads-run-manager will remain compatible
% with older runs already on disk
rc.version = 20180131;

%% Set some hyperparameters
par = PLAYBACK.RunParams;
par.spikeBinMs = 10; % rebin the data at 5 ms
par.c_co_dim = 2; % no controller --> no inputs to generator
par.trainToTestRatio = 4;
par.c_batch_size = 32; % must be < 1/5 of the min trial count for trainToTestRatio == 4
par.c_gen_dim = 200; % number of units in generator RNN
par.c_ic_enc_dim = 64; % number of units in encoder RNN
par.c_learning_rate_stop = 1e-4; % we can stop training early for the demo
par.c_ic_dim = 200;
par.c_do_causal_controller = false;
par.c_controller_input_lag = 1;
par.c_output_dist = 'poisson';
par.c_keep_prob = 0.98;
par.c_con_dim = 128;
par.c_l2_con_scale = 500;
par.c_l2_gen_scale = 500;
%par.c_do_train_prior_ar_nvar = false;
par.c_cell_clip_value = 5;
par.c_factors_dim = 40;
par.c_ar_prior_dist = 'laplace';
%par.c_kl_co_weight = 2;
%par.c_prior_ar_nvar = 1;
parSet = par.generateSweep('c_kl_co_weight', [1.6 1.7 1.8 1.9]);

% add a single set of parameters to this run collection. Additional
% parameters can be added. LFADS.RunParams is a value class, unlike the other objects
% which are handle classes, so you can modify par freely.
%rc.addParams(par);
rc.addParams(parSet);
%% Create the RunSpecs

% Define a RunSpec, which indicates which datasets get included, as well as
% what name to call this run spec
for ds_index = 1:1
    runSpecName = dc.datasets(ds_index).getSingleRunName(); % generates a simple run name from this datasets name
    runSpec = PLAYBACK.RunSpec(runSpecName, dc, ds_index);
    % add this RunSpec to the RunCollection
    rc.addRunSpec(runSpec);
end

% adding a return here allows you to call this script to recreate all of
% the objects here for subsequent analysis after the actual LFADS models
% have been trained. The code below will setup the LFADS training runs on
% disk the first time around, and should be run once manually.
%return;

%% Prepare LFADS input and shell scripts

% generate all of the data files LFADS needs to run everything
rc.prepareForLFADS();

% write a python script that will train all of the LFADS runs using a
% load-balancer against the available CPUs and GPUs
% you should set display to a valid x display
% Other options are available
rc.writeShellScriptRunQueue('display', 0, 'virtualenv', 'lfads');
