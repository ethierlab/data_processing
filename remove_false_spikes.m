function [clean_data,rem_spikes] = remove_false_spikes(data,fs,varargin)
%  [clean_data] = remove_false_spikes_function(data,fs, [optional parameters])
%
%  This function looks and removes spikes that are occuring within a certain time 'window' epoch,
%     and on a minimal 'numchan' number of channels. This is a way of detecting artifacts in neural
%     recordings leading to near-simultaneous threshold crossings on many channels.
%
%     inputs:
%           data, fs        :  raw data table and sampling rate as obtained with
%                                   ***.m routing to convert TDT files to mat files
%     
%           optional ('Param_names', param_value) pairs (default values in brackets) :
%               
%               'window'    : [0.5] time, in ms, for spikes to be considered simultaneous      
%               'numchan'   : [4] minimum number of channels (or clusters) on which spikes have to occur
%                                 simultaneously in order to be considered noise and removed.
%
%     outputs:
%           clean_data      : raw data table without artifacts
%           rem_spikes      : bin number (frames) where spikes were removed
%
%     example function call:
%           clean_data = remove_false_spikes(data,fs,'window',0.5,'numchan',4)
%
%%%% ethierlab - ME,CE, 2017-12 %%%

% default parameters:
params = struct('window'       ,0.5, ...
                'numchan'      ,4);
            
params = parse_input_params(params,varargin);


%% General table info and variable initiation: 
% fs can be a sampling rate or a table:
if istable(fs)
    fs = fs.spikes;
end

numbins_rem  = ceil(params.window*10^-3*fs); % number of bins corresponding to critical time window
numchan_rem  = params.numchan;

row_names    = data.Properties.RowNames;
trial_labels = data.Properties.VariableNames;
spike_i      = find(strncmpi('clust',row_names,5));
num_chans    = length(spike_i);
num_trials   = length(trial_labels);

rem_spikes   = cell(num_trials,1); 

clean_data   = data;

%% run artifact detection on a trial per trial basis:

for trial = 1:num_trials
    % extract all spike bins into single vector:
    all_spikes = vertcat(data{spike_i,trial}{:});
    
    if isempty(all_spikes)
        %no spikes this trial, skip to next
        continue;
    end
    
     % define time vector spanning all relevant time bins
    edges = min(all_spikes):max(all_spikes)+1;
    
    % count number of spikes per time bin:
    N     = histcounts(all_spikes,edges);
    
    % sum number of spikes over specified time window 
    N     = movsum(N,numbins_rem);
    
    % find time indices 'numbins' around where spike sum is >= number of chans
    edges = edges(1:end-1); %last edge was added just for histcounts to work nicely
    invalid_bins = edges(logical(movsum(N>=numchan_rem,numbins_rem)));
    
    rem_spikes{trial} = all_spikes(ismember(all_spikes,invalid_bins));
    
    if ~isempty(invalid_bins)
        % remove invalid spikes from data, channel by channel:
        for chan = 1:num_chans
            spikes = data{spike_i(chan),trial}{:};
            clean_data{spike_i(chan),trial}{:} = setdiff(spikes,invalid_bins);
        end
    end
end

