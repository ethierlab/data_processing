function binnedData = convertMDF2binned(datatable,varargin)
%
% usage:  binnedData = convertMDF2binned(datastruct,[params])
%
% converts a "Michael Data Format" file to the binned format, according to parameters
% specified in the optional [params] argument.
%
%         datatable               : string of mdf.mat file path and name, or string of variable name in workspace, or actual data table
%
%         params fields:            [default values in brackets]
%                                   none, one or many of these fields can
%                                   be provided in the params argument
%                                   structure, any missing field will be
%                                   set to its default value.
%
%             binsize             : [0.05]   desired bin size in seconds
%             pre_capture         : [0.5]    duration of pre-trial recording
%             HP, LP              : [50 10]  high pass and low pass cut off frequencies for EMG filtering
%             NormData            : [false]  specify whether the output data is to be normalized to unity
%             ArtRemEnable        : [false]  Whether or not to attempt detecting and deleting artifacts
%             NumChan             : [10]     Number of channels from which the artifact removal needs to detect simultaneous spikes to consider it an artifact
%             TimeWind            : [0.0005] time window, in seconds, over which the artifact remover will consider event to be "simultaneous"
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

%update missing params with default values
params = get_default_binning_params(varargin{:});

if isempty(params)
    disp('Invalid binning parameter(s)');
    return
end

%% Get general data table information
row_names    = datatable.Properties.RowNames;
num_rows     = length(row_names);
trial_labels = datatable.Properties.VariableNames;
num_trials   = length(trial_labels);

% get row indexes of every data type
trial_type_i = find(strcmpi('trial_type', row_names));
EMG_i    = find(strncmpi('EMG',row_names,3));
force_i  = find(strcmpi('force',row_names));
spike_i  = find(strncmpi('clust',row_names,5));
LFP_i    = find(strncmpi('LFP',row_names,3));

% flags to process [EMG, force, LFPs, spikes, trial_type] data, in that order
data_types = {'trial_type','EMG','force','spike','LFP','beta','lgamma','hgamma','vhgamma'};        
process_data_flag = ~[isempty(trial_type_i) isempty(EMG_i) isempty(force_i) isempty(spike_i) repmat(isempty(LFP_i),1,5)];
for dt = find(~process_data_flag(1:5))
    warning('No %s data was found',data_types{dt});
end

% get sampling frequency for each data type
fs_names = fs.Properties.VariableNames;
EMG_fs   = fs{1,strncmpi('EMG',fs_names,3)};
force_fs = fs{1,strncmpi('force',fs_names,5)};
spike_fs = fs{1,strncmpi('spike',fs_names,5)};
LFP_fs   = fs{1,strncmpi('LFP',fs_names,3)};

%% Initialize bin variables
    num_emgs    = length(EMG_i);
    num_force   = length(force_fs);
    num_spikes  = length(spike_i);
    num_LFP     = length(LFP_i);
  
    trial_type = cell(num_trials,1);
    emg     = cell(num_trials,num_emgs);
    force   = cell(num_trials,num_force);
    spikes  = cell(num_trials,num_spikes);
    LFP     = cell(num_trials,num_LFP);
    beta    = cell(num_trials,num_LFP);
    lgamma  = cell(num_trials,num_LFP);
    hgamma  = cell(num_trials,num_LFP);
    vhgamma = cell(num_trials,num_LFP);
    
    trial_dur   = cell(num_trials,1);
    timeframe   = cell(num_trials,1);

    if process_data_flag(strcmp(data_types,'LFP'))
        LFPs = process_LFPs(datatable{LFP_i,:},LFP_fs);
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % EMG data is hi-pass filtered at 50Hz, rectified and low pass filtered
        % at 10Hz, unless otherwise specified. It is downsampled to match the desired binsize.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        % Filter for EMG data
        [bh,ah] = butter(4, params.HP*2/EMG_fs, 'high'); %highpass filter params
        [bl,al] = butter(4, params.LP*2/EMG_fs, 'low');  %lowpass filter params
        
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
%             %Normalize EMGs
%             if params.NormData             
%                 %normalize to 99% percentile. Dont use the max because of possible large artefacts
%                 EMGNormRatio     = prctile(emg{trial,E},99);
%                 emg{trial,E} = emg{trial,E}/EMGNormRatio;
%             end
        end
    end
    clear tempEMG emgtimebins E bh ah bl al EMGNormRatio;
    
    %% 3-Bin force data    
    if process_data_flag(strcmp(data_types,'force')) 
        forcetimebins = (0:numel(datatable{force_i(1),trial}{:})-1)/force_fs;
        for F = 1:num_force
            tempForce = double(datatable{force_i(F),trial}{:});
            force{trial,F} = interp1(forcetimebins, tempForce, timeframe{trial},'linear','extrap')';
%             %Normalize Force
%             if params.NormData            
%                 %dont use the max because of possible outliars, use 99% percentile
%                 forceNormRatio     = prctile(force{trial,F},99);
%                 force{trial,F} = force{trial,F}/forceNormRatio;
%             end
        end
    end
    clear tempForce forcetimebins F forceNormRatio;

    %% 4-Bin spike data

    if process_data_flag(strcmp(data_types,'spike'))
        for S = 1:num_spikes
            ts = datatable{spike_i(S),trial}{:}/spike_fs;
            spikes{trial,S} = train2bins(ts,timeframe{trial})';            
        end
    end
        
    %% 5-Bin LFP data    
    if process_data_flag(strcmp(data_types,'LFP'))
        LFPtimebins = (0:numel(datatable{LFP_i(1),trial}{:})-1)/LFP_fs;
        for L = 1:num_LFP
            LFP{trial,L}     = interp1(LFPtimebins, datatable{LFP_i(L),trial}{:}, timeframe{trial},'linear','extrap')';
            beta{trial,L}    = interp1(LFPtimebins, LFPs.beta{L,trial}          , timeframe{trial},'linear','extrap')';
            lgamma{trial,L}  = interp1(LFPtimebins, LFPs.lgamma{L,trial}        , timeframe{trial},'linear','extrap')';
            hgamma{trial,L}  = interp1(LFPtimebins, LFPs.hgamma{L,trial}        , timeframe{trial},'linear','extrap')';
            vhgamma{trial,L} = interp1(LFPtimebins, LFPs.vhgamma{L,trial}       , timeframe{trial},'linear','extrap')';
%             %Normalize LFP
%             if params.NormData            
%                 %dont use the max because of possible outliars, use 99% percentile
%                 LFP{trial,L} = LFP{trial,L}/prctile(LFP{trial,L},99);
%                 beta{trial,L} = beta{trial,L}/prctile(beta{trial,L},99);
%                 LFP{trial,L} = LFP{trial,L}/prctile(LFP{trial,L},99);
%                 LFP{trial,L} = LFP{trial,L}/prctile(LFP{trial,L},99);
%                 LFP{trial,L} = LFP{trial,L}/prctile(LFP{trial,L},99);
%             end
        end
    end
    clear tempLFP LFPtimebins LFPNormRatio L;
end


%% Outputs
binnedData = table(timeframe, trial_type, emg, force, spikes, LFP, beta, lgamma, hgamma, vhgamma);
binnedData = binnedData(:,[true process_data_flag]);
        
end
