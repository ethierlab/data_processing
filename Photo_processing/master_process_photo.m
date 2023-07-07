% master_process_photo

% VARIABLES to edit:
csv_file = '/Volumes/ethierlab/Projects/Photometry/jGCaMP7/40/essai stim train 1s  300hz par 20s 250uA.csv';
time_index      = 1;
GCaMP_sig_index = 2;
ref_sig_index   = 3;
trig_sig_index  = 5;
% signalTitle = 'AIn-1 - Dem (AOut-1)';
% referenceTitle = 'AIn-1 - Dem (AOut-2)';
% stim_trigTitle = 'DI/O-3';


% Configuration
configuration.resamplingFrequency = 20;
configuration.bleachingCorrectionEpochs = [-Inf, 600, 960, Inf];
configuration.zScoreEpochs = [-Inf, 600];
configuration.conditionEpochs = {'Pre', [100, 220], 'During 1', [650, 890], 'Post', [1480, 1600]};
configuration.triggeredWindow = 10;
configuration.f0Function = @movmean;
configuration.f0Window = 10;
configuration.f1Function = @movmean;
configuration.f1Window = 10;
configuration.peaksLowpassFrequency = 0.2;
configuration.thresholdingFunction = @mad;
configuration.thresholdFactor = 0.10;


% read file
inputDataFile = csv_file;
data = convert_csv2mat(csv_file);
time = data.(time_index);
signal = data.(GCaMP_sig_index);
reference = data.(ref_sig_index);

% extract ttl events on trig_sig
ttl = data.(trig_sig_index);
ttl = [false; diff(ttl)==+1];


% [data, names] = loadData(inputDataFile);
% s = ismember(names, signalTitle);
% r = ismember(names, referenceTitle);

% reference = data(:, r);


FPA(time, signal, reference, configuration);