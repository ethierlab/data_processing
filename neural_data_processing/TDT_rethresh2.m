
BLOCKPATH = uigetdir('/Users/christianethier/Google Drive (Work)/Projects/Chronic Array and Mototrak/sample data/jados-19-04-30-am','Select TDT data block');

STORE   = 'spik'; %load only streamed neural data
THRESH  = -75e-6;
NPTS    = 40; %1.6ms snippets
OVERLAP = 0; % one spike max per NPTS
REJECT  = 400e6; % reject above 400uV (artifact)





%%
% Now read the specified data from our block into a Matlab structure.
data = TDTbin2mat(BLOCKPATH);

%% Use TDTdigitalfilter to filter the streaming waveforms
% We are interested in single unit activity in the 300Hz-5000Hz band.
su = TDTdigitalfilter(data, STORE, [300 5000]);

%% Use TDTthresh to extract snippet events
% Mode is set to 'manual' in this example for extracting snippets around a
% hard threshold.
su = TDTthresh(su, STORE, 'MODE', 'manual', 'THRESH', THRESH, 'NPTS', NPTS, 'OVERLAP', OVERLAP);

