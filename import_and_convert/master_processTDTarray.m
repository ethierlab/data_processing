% Processing script for array recordings with TDT data 



%% 1- Import TDT to mat file

% matdata = TDT_import(filepath);

%% 2- Rethreshold spikes one channel at a time

% options:

BLOCKPATH = uigetdir('/Users/christianethier/Google Drive (Work)/Projects/Chronic Array and Mototrak/sample data/jados-19-04-30-am','Select TDT data block');

% read file info:
heads = TDTbin2mat(BLOCKPATH, 'HEADERS', 1);




% initial threshold value
THRESH  = -80e-6; % 
NPTS    = 40; %1.6ms snippets
OVERLAP = 0; % one spike max per NPTS
REJECT  = 400e-6; % reject above 400uV (artifact)
STORE   = 'spik'; %load only streamed neural data

CHANNEL = 1;

% 
% [num_ch num_pts_tot] = size(matdata.streams.spik.data,1);
% 
% for ch = 1:num_ch
% end

ch = 1;

% Now read the specified data from our block into a Matlab structure.
data = TDTbin2mat(BLOCKPATH, 'STORE', STORE, 'CHANNEL', CHANNEL);

%% Use TDTdigitalfilter to filter the streaming waveforms
% We are interested in single unit activity in the 300Hz-5000Hz band.
su = TDTdigitalfilter(data, STORE, [300 5000]);

%% Use TDTthresh to extract snippet events
% Mode is set to 'manual' in this example for extracting snippets around a hard threshold.
su = TDTthresh(su, STORE, 'MODE', 'manual', 'THRESH', THRESH, 'NPTS', NPTS, 'OVERLAP', OVERLAP,'REJECT',REJECT);

% look at first 500 spikes
figure; plot(su.snips.Snip.data(1:500,:)'); title('before cleanup');

su = cleanup_spikes(su);

figure; plot(su.snips.Snip.data(1:500,:)'); title('after cleanup');

% reshape data into columns of 10 sec segments. patch last column with nans
num_pts_per_seg = 10*matdata.streams.spik.fs;
num_seg         = ceil(num_pts_tot/num_pts_per_seg);
stream_data     = reshape( [matdata.streams.spik.data(ch,:) nan(1, num_pts_per_seg*num_seg-num_pts_tot)],num_pts_per_seg,num_seg);

