function [Processed_LFPs, t] = process_LFPs(rawLFP,fs, varargin)
%
% usage: Processed_LFPs = process_LFPs(LFP,fs, [mapping] )
% 
% inputs:
%       LFP    : num_LFPs x num_trials cell array of LFP data
%       fs     : sampling rate of LFPs
%
%       params :  (optional) none, one or many of these can be provided, any missing parameter will be
%                 set to its default value, indicated in brackets here below.
%                 Use either the ('param_name',param_value) pairs or a params structure with 'param_name' fields
%           'wind'     : [100]  in ms, length of Hamming window
%           'noverlap' : [50]   in %, number of overlap
%           'nlog'     : [true] flag for log normalization of freqs
%
% outputs:
%      Processed_LFPs : a table with LFP power in different frequency bands
%
%


% defaults parameters
params = struct(...
    'wind'         , 100,... % in ms, length of Hamming window
    'noverlap'     , 50, ... % window overlap, in % of 'wind'
    'nlog'         , true... % log normalize
    );

params = parse_input_params(params,varargin);

d_band = [0 4];
t_band = [4 8];
a_band = [8 13];
b_band = [13 30];
lg_band= [31 80];
hg_band= [81 150];
vhg_band=[151 300];

% stft params
wind_pts  = floor(params.wind*fs/1000);
nover_pts = floor(wind_pts*params.noverlap/100);
if params.nlog
    ff = logspace(log10(1),log10(300),256);
else
    ff = 300*(1:256)/256;
end

[num_LFPs, numtrials] = size(rawLFP);

delta   = cell(num_LFPs,numtrials);
theta   = cell(num_LFPs,numtrials);
alpha   = cell(num_LFPs,numtrials);
beta    = cell(num_LFPs,numtrials);
lgamma  = cell(num_LFPs,numtrials);
hgamma  = cell(num_LFPs,numtrials);
vhgamma = cell(num_LFPs,numtrials);

t = cell(numtrials,1);

for i=1:num_LFPs
    for j = 1:numtrials
        data = detrend(double(rawLFP{i,j}));
        [s,f,t] = spectrogram(data,wind_pts,nover_pts,ff,fs);
        
        delta{i,j}   = mean( s( f>=d_band(1)   &  f<=d_band(2),:));
        theta{i,j}   = mean( s( f>=t_band(1)   &  f<=t_band(2),:));
        alpha{i,j}   = mean( s( f>=a_band(1)   &  f<=a_band(2),:));
        beta{i,j}    = mean( s( f>=b_band(1)   &  f<=b_band(2),:));
        lgamma{i,j}  = mean( s( f>=lg_band(1)  &  f<=lg_band(2),:));
        hgamma{i,j}  = mean( s( f>=hg_band(1)  &  f<=hg_band(2),:));
        vhgamma{i,j} = mean( s( f>=vhg_band(1) &  f<=vhg_band(2),:));
    end
end

% [Pow, Freq ,Tsp ,Psp]                  = spectrogram( signal, fs/2, 1000, Freq_sp, fs, 'yaxis');

Processed_LFPs = table(rawLFP,delta,theta,alpha,beta,lgamma,hgamma,vhgamma);