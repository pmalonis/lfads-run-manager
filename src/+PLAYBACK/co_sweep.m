%% This script walks through running LFADS on a single Lorenz dataset
%% Generate synthetic Lorenz datasets

% build the dataset collection
datasetPath = '../../data/raw/';

%% Locate and specify the datasets
dc = RTP.DatasetCollection(datasetPath);
dc.name = 'controller_params_sweep';

% add individual datasets
%RTP.Dataset(dc, 'raju_M1.mat');
%RTP.Dataset(dc, 'raju_PMd.mat');
RTP.Dataset(dc, 'raju.mat');
%RTP.Dataset(dc, 'rockstar.mat');

%% Build RunCollection - first a single run

% Run a single model for each of the datasets
runRoot = '../../data/model_output';
rc = RTP.RunCollection(runRoot, 'controller_co_dim_sweep', dc);

% replace this with the date this script was authored as YYYYMMDD
% This ensures that updates to lfads-run-manager will remain compatible
% with older runs already on disk
rc.version = 20180131;

%% Set some hyperparameters

par = RTP.RunParams;
par.name = 'with_inputs'; % name is completely optional and not hashed, for your convenience
par.spikeBinMs = 10; % rebin the data at 5 ms
%par.c_co_dim = 2; % no controller --> no inputs to generator
par.c_batch_size = 64; % must be < 1/5 of the min trial count for trainToTestRatio == 4
par.c_gen_dim = 200; % number of units in generator RNN
par.c_ic_enc_dim = 64; % number of units in encoder RNN
par.c_learning_rate_stop = 1e-5; % we can stop training early for the demo
par.c_ic_dim = 200;
par.c_do_causal_controller = false;
par.c_controller_input_lag = 1;
par.c_output_dist = 'poisson';
par.c_keep_prob = 0.98;
par.c_con_dim = 128;
par.c_l2_con_scale = 500;
par.c_l2_gen_scale = 500;
par.c_factors_dim = 40;
parSet = par.generateSweep('c_co_dim', [3 4], 'c_kl_co_weight', [2 3]);

% add a single set of parameters to this run collection. Additional
% parameters can be added. LFADS.RunParams is a value class, unlike the other objects
% which are handle classes, so you can modify par freely.
%rc.addParams(par);
rc.addParams(parSet);

%% Create the RunSpecs

% Define a RunSpec, which indicates which datasets get included, as well as
% what name to call this run spec
for ds_index = 1
    runSpecName = dc.datasets(ds_index).getSingleRunName(); % generates a simple run name from this datasets name
    runSpec = RTP.RunSpec(runSpecName, dc, ds_index);
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
