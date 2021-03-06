function binnedData = convertMDF2binned(datatable,varargin)
%
% usage:  binnedData = convertMDF2binned(datastruct,[params])
%
% converts a "Michael Data Format" file to the binned format, according to parameters
% specified in the optional [params] argument.
%
%         datatable               : string of mdf.mat file path and name, or string of variable name in workspace, or actual data table
%
%         params fields:          : (optional) none, one or many of these can be provided, any missing parameter will be
%                                   set to its default value, indicated in brackets here below.
%                                   Use either the ('param_name',param_value) pairs or a params structure with 'param_name' fields
%
%             binsize             : [0.01]   desired bin size in seconds
%             pre_capture         : [0.5]    duration of pre-trial recording
%             HP, LP              : [50 10]  high pass and low pass cut off frequencies for EMG filtering
%             diff_lfp            : [true]   differentiate LFPs using electrodes pairs in different 'columns'
%             diff_mapping        : []       electrode mapping for differential LFP, empty for default (see diff_LFP.m)
%             norm_lfp            : [true]  specify whether raw LFPs are to be normalized in amplitude, using the 99th percentile (to avoid squashing the signal in case there is a big artifact)
%             ArtRemEnable        : [false]  Whether or not to attempt detecting and deleting artifacts
%             NumChan             : [10]     Number of channels from which the artifact removal needs to detect simultaneous spikes to consider it an artifact
%             TimeWind            : [0.0005] time window, in seconds, over which the artifact remover will consider event to be "simultaneous"
%
%
%%%% Ethierlab 2017/09/14 -- CE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if ~istable(datatable)
    %Load the file or structure
    [datatable, fs] = load_data_table(datatable);
    if isempty(datatable)
        error('can''t load file');
    end
else
    %use the data table already in workspace, load fs too
    fs = evalin('base','fs');
end

% default Parameters (all units are in seconds):
params = struct(...
    'binsize'       , 0.01,...
    'pre_capture'   , 0.5,...
    'HP'            , 50,...
    'LP'            , 10,...
    'diff_lfp'      , true,...
    'diff_mapping'  , [],...
    'norm_lfp'      , true,...
    'ArtRemEnable'  , false,...
    'NumChan'       , 10,...
    'TimeWind'      , 0.0005);
%update missing params with default values

params = parse_input_params(params,varargin);

%% Get general data table information
row_names    = datatable.Properties.RowNames;
num_rows     = length(row_names);
trial_labels = datatable.Properties.VariableNames;
num_trials   = length(trial_labels);

% get row indexes of every data type
trial_type_i = find(strcmpi('trial_type', row_names));
EMG_i    = find(strncmpi('EMG',row_names,3));
force_i  = find(strcmpi('force',row_names));
units_i  = find(strncmpi('ch',row_names,2));
LFP_i    = find(strncmpi('LFP',row_names,3));
success_i= find(strncmpi('succ',row_names,4));
trial_t_i= find(strncmpi('time2s',row_names,6));

% get sampling frequency for every data type
fs_names = fs.Properties.VariableNames;
EMG_fs   = fs{1,strncmpi('EMG',fs_names,3)};
force_fs = fs{1,strncmpi('force',fs_names,5)};
units_fs = fs{1,strncmpi('spike',fs_names,5)};
LFP_fs   = fs{1,strncmpi('LFP',fs_names,3)};

% flags to process [EMG, force, LFPs, spikes, trial_type, trial_success, time2success] data, in that order
data_types = {'trial_type','success','trial_time','EMG','force','spike','LFP','beta','lgamma','hgamma','vhgamma'};    
process_data_flag = ~[isempty(trial_type_i) isempty(success_i) isempty(trial_t_i) (isempty(EMG_i) | iscell(EMG_fs)) isempty(force_i) isempty(units_i) repmat(isempty(LFP_i),1,5)];

for dt = find(~process_data_flag(1:5))
    warning('No %s data was found',data_types{dt});
end

%% Initialize bin variables
    num_emgs   = length(EMG_i);
    num_force  = length(force_fs);
    num_units  = length(units_i);
    num_LFP    = length(LFP_i);
    if process_data_flag(strcmp(data_types,'LFP'))
        norm_lfp_ratio = ones(1,num_LFP);
        if params.norm_lfp
            for l = 1:num_LFP
                % for each raw lfp signal, find the 99th percentile of the absolute value of the lfp signal accross all trials
                norm_lfp_ratio(l) = prctile(abs([datatable{LFP_i(l),:}{:}]),99);
            end
        end
        if params.diff_lfp
            if ~isempty(params.diff_mapping)
                num_LFP = size(params.diff_mapping,1);
            else
                num_LFP = num_LFP/2; %default is row-wise differential of all LFP signals
            end
        end
    end
        
    trial_type = cell(num_trials,1);
    trial_time = cell(num_trials,1);
    success    = cell(num_trials,1);
    trial_dur   = cell(num_trials,1);
    timeframe   = cell(num_trials,1);
    
    emg     = cell(num_trials,num_emgs);
    force   = cell(num_trials,num_force);
    spikes  = cell(num_trials,num_units);
    rawLFP  = cell(num_trials,num_LFP);
    delta   = cell(num_trials,num_LFP);
    theta   = cell(num_trials,num_LFP);
    alpha   = cell(num_trials,num_LFP);
    beta    = cell(num_trials,num_LFP);
    lgamma  = cell(num_trials,num_LFP);
    hgamma  = cell(num_trials,num_LFP);
    vhgamma = cell(num_trials,num_LFP);
    
    if process_data_flag(strcmp(data_types,'EMG'))
        [bh,ah] = butter(4, params.HP*2/EMG_fs, 'high'); %highpass filter params
        [bl,al] = butter(4, params.LP*2/EMG_fs, 'low');  %lowpass filter params
    end
    
%%  Trial per trial, extract and bin all data into new cells

 for trial = 1:num_trials
    
    %use first force signal to infer duration and timeframe for this trial
    num_points       = numel(datatable{force_i(1),trial}{:});
    trial_dur{trial} = num_points/force_fs;
    num_bins         = floor(trial_dur{trial}/params.binsize);
    timeframe{trial} = params.binsize*(0:num_bins-1);
    
    %% 1-Bin trial type
    if process_data_flag(strcmp(data_types,'trial_type'))
       trial_type{trial} = datatable{trial_type_i(1),trial}{:};
    end
    
 
    %% 2-Bin EMG data
    if process_data_flag(strcmp(data_types,'EMG'))     
        % original timeframe
        emgtimebins = (0:numel(datatable{EMG_i(1),trial}{:})-1)/EMG_fs;
        for E=1:num_emgs
            % Filter EMG data
            tempEMG = double(datatable{EMG_i(E),trial}{:});
            tempEMG = filtfilt(bh,ah,tempEMG); %highpass filter
            tempEMG = abs(tempEMG); %rectify
            tempEMG = filtfilt(bl,al,tempEMG); %lowpass filter
            
            %downsample EMG data to desired bin size
            emg{trial,E} = interp1(emgtimebins, tempEMG, timeframe{trial},'linear','extrap')';
        end
    end
    clear tempEMG emgtimebins E bh ah bl al EMGNormRatio;
    
    %% 3-Bin force data    
    if process_data_flag(strcmp(data_types,'force')) 
        forcetimebins = (0:numel(datatable{force_i(1),trial}{:})-1)/force_fs;
        for F = 1:num_force
            tempForce = double(datatable{force_i(F),trial}{:});
            force{trial,F} = interp1(forcetimebins, tempForce, timeframe{trial},'linear','extrap')';
        end
    end
    clear tempForce forcetimebins F forceNormRatio;

    %% 4-Bin spike data
            %todo: separate single vs multiunits
            %todo: remove artifacts based on coincidence and params (find my code for that)
    if process_data_flag(strcmp(data_types,'spike'))
        for S = 1:num_units
            ts = datatable{units_i(S),trial}{:}/units_fs;
            spikes{trial,S} = train2bins(ts,timeframe{trial})';            
        end
    end
        
    %% 5-Bin LFP data    
    if process_data_flag(strcmp(data_types,'LFP'))
        
        %original timeframe
        rawLFPtimebins = (0:numel(datatable{LFP_i(1),trial}{:})-1)/LFP_fs;
        
        LFPs = datatable{LFP_i,trial};
        if params.norm_lfp
            for L = 1:length(LFPs)
                LFPs{L} = LFPs{L}/norm_lfp_ratio(L);
            end
        end
        
        if params.diff_lfp
            LFPs = diff_LFP(LFPs);
        end
        [LFPs, processedLFPtimebins] = process_LFPs(LFPs,LFP_fs);      
        
        for L = 1:num_LFP
            rawLFP{trial,L}  = interp1(rawLFPtimebins      , LFPs.rawLFP{L}  , timeframe{trial},'linear','extrap')';
            delta{trial,L}   = interp1(processedLFPtimebins, LFPs.delta{L}   , timeframe{trial},'linear','extrap')';
            theta{trial,L}   = interp1(processedLFPtimebins, LFPs.theta{L}   , timeframe{trial},'linear','extrap')';
            alpha{trial,L}   = interp1(processedLFPtimebins, LFPs.alpha{L}   , timeframe{trial},'linear','extrap')';
            beta{trial,L}    = interp1(processedLFPtimebins, LFPs.beta{L}    , timeframe{trial},'linear','extrap')';
            lgamma{trial,L}  = interp1(processedLFPtimebins, LFPs.lgamma{L}  , timeframe{trial},'linear','extrap')';
            hgamma{trial,L}  = interp1(processedLFPtimebins, LFPs.hgamma{L}  , timeframe{trial},'linear','extrap')';
            vhgamma{trial,L} = interp1(processedLFPtimebins, LFPs.vhgamma{L} , timeframe{trial},'linear','extrap')';
        end

    end
    clear tempLFP LFPtimebins LFPNormRatio L;

    %% 6-Bin trial_success
    if process_data_flag(strcmp(data_types,'success'))
         trial_time{trial} = datatable{trial_t_i(1),trial}{:};
    end
    
    %% 7-Bin time2success
    if process_data_flag(strcmp(data_types,'trial_time'))
        success{trial} = datatable{success_i(1),trial}{:};
    end
    
end

%% Outputs
binnedData = table(timeframe, trial_type, trial_time, success, emg, force, spikes, rawLFP, delta, theta, alpha, beta, lgamma, hgamma, vhgamma);
binnedData = binnedData(:,[true process_data_flag]);
        
end
