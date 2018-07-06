function Processed_LFPs = process_LFPs(LFP,fs)
%
% 
%

b_band = [13 30];
lg_band= [31 80];
hg_band= [81 150];
vhg_band=[151 300];
filter_order = 8;

[num_LFPs, numtrials] = size(LFP);

beta    = cell(num_LFPs,numtrials);
lgamma  = cell(num_LFPs,numtrials);
hgamma  = cell(num_LFPs,numtrials);
vhgamma = cell(num_LFPs,numtrials);

bb   = fir1(filter_order, b_band/(fs/2), 'band');
lgb  = fir1(filter_order, lg_band/(fs/2), 'band');
hgb  = fir1(filter_order, hg_band/(fs/2), 'band');
vhgb = fir1(filter_order, vhg_band/(fs/2), 'band');

for i=1:num_LFPs
    for j = 1:numtrials
        data = detrend(double(LFP{i,j}));
        beta{i,j} = filtfilt(bb,1,data);
        lgamma{i,j} = filtfilt(lgb,1,data);
        hgamma{i,j} = filtfilt(hgb,1,data);
        vhgamma{i,j} = filtfilt(vhgb,1,data);
    end
end

Processed_LFPs = table(beta,lgamma,hgamma,vhgamma);