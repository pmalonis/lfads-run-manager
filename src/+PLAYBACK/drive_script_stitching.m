%% This script walks through running LFADS to stitch multiple Lorenz datasets

%% Generate synthetic Lorenz datasets

% build the dataset collection
datasetPath = '../../data/raw/Playback-NN/split_condition/'

%% Locate and specify the datasets
dc = PLAYBACK.DatasetCollection(datasetPath);
dc.name = 'mk_prop_pb_orgin_params';

% add individual datasets
PLAYBACK.Dataset(dc, 'mk080729_M1m/prop_pb.mat');
PLAYBACK.Dataset(dc, 'mk080730_M1m/prop_pb.mat');
PLAYBACK.Dataset(dc, 'mk080731_M1m/prop_pb.mat');
PLAYBACK.Dataset(dc, 'mk080828_M1m/prop_pb.mat');

% load metadata from the datasets to populate the dataset collection
dc.loadInfo;

% print information loaded from each dataset
dc.getDatasetInfoTable()

%% Set some hyperparameters
par = PLAYBACK.RunParams;
par.useAlignmentMatrix = true;
par.spikeBinMs = 10; % rebin the data at 5 ms
par.c_co_dim = 2; % no controller --> no inputs to generator
par.trainToTestRatio = 3;
par.c_batch_size = 4; % must be < 1/5 of the min trial count for trainToTestRatio == 4
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
par.c_factors_dim = 40;
par.c_kl_co_weight = 2;
par.c_factors_dim = 40;
parSet = par.generateSweep('c_factors_dim', [20, 30, 40]);

% Now we'll do something slightly more interesting. We'll do a total of 4
% LFADS runs. 3 will be single-session LFADS runs on each of the datasets
% individually. The last will be a multi-session stitched dataset that
% leverages all 3 of the datasets in a common shared model.

runRoot = '../../data/model_output';
rc = PLAYBACK.RunCollection(runRoot, 'mk_prop_pb_orgin_params', dc);

% replace this with the date this script was authored as YYYYMMDD
% This ensures that updates to lfads-run-manager won't invalidate older
% runs already on disk and provides for backwards compatibility
rc.version = 201801;

% Add a RunSpec using all datasets which LFADS will then "stitch" into a
% shared dynamical model
rc.addRunSpec(PLAYBACK.RunSpec('all', dc, 1:dc.nDatasets));

% add a single set of parameters to this run collection. Additional
% parameters can be added. LFADS.RunParams is a value class, unlike the other objects
% which are handle classes, so you can modify par freely.
%rc.addParams(par);
rc.addParams(parSet);

% adding a return here allows you to call this script to recreate all of
% the objects here for subsequent analysis after the actual LFADS models
% have been trained. The code below will setup the LFADS training runs on
% disk the first time around, and should be run once manually.
%return;

%% Generating accompanying single-dataset models

% If you like you can also add RunSpecs to train individual models for each
% dataset as well to facilitate comparison.
for iR = 1:dc.nDatasets
    runSpec = PLAYBACK.RunSpec(dc.datasets(iR).getSingleRunName(), dc, iR);
    rc.addRunSpec(runSpec);
end

%% Verifying the alignment matrices

% run = rc.findRuns('all', 1);
% run.doMultisessionAlignment();
% nFactorsPlot = 3;
% conditionsToPlot = [1 20 40];

% tool = run.multisessionAlignmentTool;
% tool.plotAlignmentReconstruction(nFactorsPlot, conditionsToPlot);

%% Prepare LFADS input and shell scripts

% generate all of the data files LFADS needs to run everything
rc.prepareForLFADS();

% write a python script that will train all of the LFADS runs using a
% load-balancer against the available CPUs and GPUs
% you should set display to a valid x display
% Other options are available
rc.writeShellScriptRunQueue('display', 0, 'virtualenv', 'lfads');

%% Looking at the alignment matrices used

runStitched = rc.findRuns('all', 1); % 'all' looks up the RunSpec by name, 1 refers to the first (and here, the only) RunParams

alignTool = runStitched.multisessionAlignmentTool;
if isempty(alignTool)
    runStitched.doMultisessionAlignment();
    alignTool = runStitched.multisessionAlignmentTool;
end

alignTool.plotAlignmentReconstruction();

% You want the colored traces to resemble the black "global" trace. The
% black traces are the PC scores using data from all the datasets. The
% colored traces are the best linear reconstruction of the black traces
% from each individual dataset alone. The projection which achieves this
% best reconstruction is used as the initial seed for the readin matrices
% for LFADS, which can be trainable or fixed depending on
% par.do_train_readin.

%% Run LFADS

% You should now run at the command line
% source activate tensorflow   # if you're using a virtual machine
% python ~/lorenz_example/runs/exampleRun_dataset1/run_lfadsqueue.py

% And then wait until training and posterior sampling are finished
%rc.prepareForLFADS();

% write a python script that will train all of the LFADS runs using a
% load-balancer against the available CPUs and GPUs
% you should set display to a valid x display
% Other options are available
%rc.writeShellScriptRunQueue('display', 0, 'virtualenv', 'lfads');
