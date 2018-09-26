function mean_data = mean_trial_data(binnedData,varargin)
% usage:  mean_data = mean_trial_data(binnedData,[signals],[trialtypes],['plot'])
%
% This function reads 'binnedData' files obtained with convertMDF2binned.m, in order to compute the average
%  of one or many of the recorded signals accross all trials. Signals can be any or all of : [force, emg, spikes, LFPs]
%
%   input arguments:
%         binnedData              : string of mdf.mat file path and name, or string of variable name in workspace,
%                                   or actual 'binnedData' table obtained from convertMDF2binned.m
%         signals:                : none, one, or many strings indicating which signals to average.
%                                   possible strings are 'force', 'emg', 'spikes','lfp','rawLFP','delta','theta','alpha','beta','lgamma','hgamma','vhgamma'  to average force, emg, firing rates and lfps respectively.
%                                   by default, mean_trial_data will average every type of signals it finds in the binnedData
%         trialtypes              : none, one, or many strings indicating which trial type to average.
%                                   possible strings are 'jackpot','single,'no_reward' and 'all'
%                                   By default, mean_trial_data will average signals separately for each type of trial it finds,
%                                   in addition to calculating an average for all types of trials combined.
%         plot                    : if the string 'plot' is present, plots are generated.
%
%   output arguments:
%         mean_data               : structure with averaged data separated into 'force', 'emg', 'fr' and 'lfp' fields.
%
%%%% Ethierlab 2018/07 -- CE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load data
if ~istable(binnedData)
    %Load the file or structure
    [binnedData] = load_data_table(binnedData);
    if isempty(datatable)
        error('can''t load file');
    end
end

% find signal types and trial types to average
col_names = binnedData.Properties.VariableNames;
if nargin > 1
    in_names  = varargin;
end

ave_force   = false;
ave_emg     = false;
ave_spikes  = false;

ave_lfp     = false(1,8);% (raw, delta, theta, alpha, beta, lgamma, hgamma, vhgamma)

ave_jackpot = false;
ave_single  = false;
ave_norew   = false;
ave_all     = false;
plot_flag   = false;

for s = 1:length(varargin)
    if ~isstr(varargin{s})
        warning('wrong type of argument to ''mean_trial_data''');
        help('mean_trial_data');
        return;
    end
    switch lower(varargin{s})
        case 'force'
            ave_force   = true;
        case 'emg'
            ave_emg     = true;
        case 'spikes'
            ave_spikes  = true;
        case 'lfp'
            ave_lfp     = true(1,8);
        case 'rawlfp'
            ave_lfp(1)  = true;
        case 'delta'
            ave_lfp(2)  = true;
        case 'theta'
            ave_lfp(3)  = true;
        case 'alpha'
            ave_lfp(4)  = true;
        case 'beta'
            ave_lfp(5)  = true;
        case 'lgamma'
            ave_lfp(6)  = true;
        case 'hgamma'
            ave_lfp(7)  = true;            
        case 'vhgamma'
            ave_lfp(8)  = true;
            
        case 'jackpot'
            ave_jackpot = true;
        case 'single'
            ave_single  = true;
        case 'no_reward'
            ave_norew   = true;
        case 'all'
            ave_all     = true;
            
        case 'plot'
            plot_flag   = true;
            
        otherwise
            warning('Unknown parameter ''%s'' provided as argument to ''mean_trial_data''',varargin{s});
    end
            
end

 % default signals if not specified:
if ~any([ave_force,ave_emg,ave_spikes,ave_lfp])
     ave_force  = any(strcmp(col_names,'force'));
     ave_spikes = any(strcmp(col_names,'spikes'));
     ave_emg    = any(strcmp(col_names,'emg'));
     ave_lfp    = repmat(any(strcmpi(col_names,'rawLFP')),1,8);
end
 
%% Start averaging signals accross trials

% 1- spikes
if ave_spikes
end


% 4- LFPs
if any(ave_lfp)
    
end


