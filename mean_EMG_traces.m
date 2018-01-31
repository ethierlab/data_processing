function [EMGm, EMGsd] = mean_EMG_traces(data_array,EMG_vec,varargin)
%
% usage: mEMG = mean_EMG_trace(data_array,EMG_vec,[params])
%
%  This function averages the mean EMG signals specified in EMG_vec for each data structure present in the first column of the cell array matdata_array.
%  It returns the average EMG traces for each data structure plots them all if the "plot_flag" optional argument is true.
%
%   inputs:
%       data_array  :  cell array of data structure, as provided by parse_tdt_data.m
%       EMG_vec     :  vector of EMG channels for which to measure recruitment 
%       params      :  (optional) none, one or many of these can be provided, any missing parameter will be
%                      set to its default value, indicated in brackets here below.
%                      Use either the ('param_name',param_value) pairs or a params structure with 'param_name' fields
%
%           'plot'  :  [true], whether or not to produce one figure of all mean EMG traces for each data structure
%           'mode'  :  [raw],  either 'raw' or 'rect'.
%                             'raw' : averages unrectified raw EMG data
%                             'rect': rectifies and filters the EMG signal (hp 50Hz, rect, lp 20Hz)
%           'HP','LP': [50 10]  high pass and low pass cut off frequencies for EMG filtering
%
%   outputs:
%       EMGm        :  averaged EMG traces
%       EMGsd       :  EMG standard deviation for each time point
%
%%%% Ethierlab 2018/01 -- CE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Argument handling

% defaults parameters
params = struct('mode'         ,'raw', ...
                'plot'         , true);
params = parse_input_params(params,varargin);

%% EMG processing

num_blocks    = size(data_array,1);
nEMGs         = length(EMG_vec);
EMGm          = cell(num_blocks,nEMGs);
EMGsd         = cell(num_blocks,nEMGs);


for b = 1:num_blocks 
    EMGs      = data_array{b,1}.snips.data(:,EMG_vec);
    timeframe = data_array{b,1}.snips.timeframe;
    numpts    = length(timeframe);
    EMG_fs    = 1/(timeframe(2)-timeframe(1));
    EMG_list  = {};

    %loop individual channels to extract data from cell array to 2D-matrix
    for e = 1:nEMGs
    
        EMG_number = EMG_vec(e);
        EMG_list   = [EMG_list ['EMG ch ' num2str(EMG_number)]];
        tmp_emg = vertcat(EMGs{:,EMG_number});
        
        switch params.mode
            case 'raw'
            case 'rect'
                % Filter for EMG data
                [bh,ah] = butter(4, params.HP*2/EMG_fs, 'high'); %highpass filter params
                [bl,al] = butter(4, params.LP*2/EMG_fs, 'low');  %lowpass filter params
        
                tempEMG = filtfilt(bh,ah,tempEMG); %highpass filter
                tempEMG = abs(tempEMG); %rectify
                tempEMG = filtfilt(bl,al,tempEMG); %lowpass filter
            otherwise
                error('unrecognised EMG processing mode');
        end
        
        EMGm{b,e}  = mean(tmp_emg)';
        EMGsd{b,e} =  std(tmp_emg)';
    end
    
    if params.plot
        %convert to mV
        plotShadedSD(timeframe,1000*reshape([EMGm{b,:}],numpts,nEMGs),1000*reshape([EMGsd{b,:}],numpts,nEMGs));
        xlabel('Time (s)');
        ylabel(['mean ' params.mode ' EMG (mV)']);
        title(['mean EMG trace for file' data_array{b,2}]);
        legend(EMG_list);
    end
end

