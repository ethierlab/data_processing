function EMG_response = mean_EMG_response(EMGs,timeframe,varargin)
%
% usage: EMG_response = mean_EMG_response(EMGs,timeframe,[params])
%
%  This function returns the average EMG response from the EMGs cell array, calculated based on the parameters.
%
%   inputs:
%       EMGs        :  [nStim x Nchan] cell array of EMG data, where each cell contain a row vector of a single EMG signal
%       timeframe   :  [nBin x 1] vector of timestamps for EMG data, where time 0 is the (beginning of) stimulus
%
%       params      :  (optional) none, one or many of these can be provided, any missing parameter will be
%                      set to its default value, indicated in brackets here below.
%                      Use either the ('param_name',param_value) pairs or a params structure with 'param_name' fields
%
%           'mode'         :  ['rect'] either 'p2p' or 'rect'.
%                             'p2p' : calculates the peak-to-peak value of unrectified EMG data
%                             'rect': calculates the integral of the rectified signal
%
%           'rem_baseline' :  [false] logic flag indicating whether to remove the average baseline
%                             EMG prior to stim onset from measured EMG response
%
%           'window'       :  [0.002 0.010] two-element vector to delimit the EMG response analysis time window (in seconds)
%
%
%%%% Ethierlab 2018/01 -- CE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Argument handling

% defaults parameters
params = struct('mode'         ,'rect', ...
                'rem_baseline' ,false, ...
                'window'      ,[0.002 0.010]);

params = parse_input_params(params,varargin);

%% EMG processing

nEMGs        = size(EMGs,2);
EMG_response = nan(1,nEMGs);
timebin      = timeframe(2)-timeframe(1);

for e = 1:nEMGs
    %loop individual channels to extract data from cell array to 2D-matrix
    tmp_emg = vertcat(EMGs{:,e});
    
    % 0 - filter... Todo
    
    % 1- average accross rows (repeated stim values)
    tmp_emg = mean(tmp_emg,1);
    
    % 2- measure response
    %extract data over time window
    tmp_emg =  tmp_emg(timeframe>=params.window(1) & timeframe<=params.window(2));
    
    switch params.mode
        case 'rect'
            %calculate integral over time window
            tmp_resp = sum(abs(tmp_emg))*timebin;
        case 'p2p'
            %calculate peak-to-peak value during time window
            tmp_resp = range(tmp_emg);
        otherwise
            error('unrecognised emg processing mode');
    end
    
    EMG_response(e) = tmp_resp;
    
end

