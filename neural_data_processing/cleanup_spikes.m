function su = cleanup_spikes(su)
% so far this assumes 40 pts per snip, only 1 channel in data
% parameters are hardcoded and should be made parameterized and provided as input to function
% todo: also look at number of channels?
% overall: make more user friendly and robust
% use time relative to threshold crossing instead of bin number

num_snips = size(su.snips.Snip.data,1);
num_chans = size(su.snips.Snip.data,2);

% remove snips when above 100uV in first 5 bins
rem_idx = find(any(su.snips.Snip.data(:,1:5)'>100e-6));

% remove snips when below -80uV in first 5 bins
rem_idx = [rem_idx find(any(su.snips.Snip.data(:,1:5)'<-80e-6))];

% remove snips when below 0uV in bins 20 to 25
rem_idx = [rem_idx find(any(su.snips.Snip.data(:,20:25)'<0 ))];

% remove snips when absolute amplitude above 150uV for last 10 bins
rem_idx = [rem_idx find(any(abs(su.snips.Snip.data(:,30:40))'>150e-6))];

% actually remove all relevant snips
su.snips.Snip.data(rem_idx,:)     = [];
su.snips.Snip.sortcode(rem_idx,:) = [];
su.snips.Snip.ts(rem_idx,:)       = [];

fprintf('cleanup_spike removed %d of %d snips\n',length(rem_idx),num_snips);

end