function EMG_response = mean_EMG_response(EMGs,timeframe,varargin)
%
% usage: EMGvsStimI = recruitment_curve(EMGs,StimAmp,[params])
%
%  This function returns the average EMG response from the EMGs cell array, calculated based on the parameters.
%
%   inputs:
%       EMGs        :  [nStim x Nchan] cell array of EMG data
%       timeframe   :  [nBin x 1] vector of timestamps for EMG data, where time 0 is the (beginning of) stimulus
%       StimAmp     :  [nStim x 1] vector of stimulation amplitude in uA
%
%       params      :  [default values in brackets]
%                      none, one or many of these fields can
%                      be provided in the params argument
%                      structure, any missing field will be
%                      set to its default value. use ('param_name',param_value) pairs in argument
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

nEMGs    = size(EMGs,2);
EMG_response = nan(1,nEMGs);

% 0 - filter... Todo

% 1- rectify
if strcmpi(params.mode, 'rect')
    EMGs = abs(EMGs);
end

% 2- average accross rows (repeated stim values)
EMGs = mean(EMGs,1);

% 3- measure response
switch params.mode
    case 'rect'
        %calculate integral over time window
        range = EMGs(:params.window
end
    
end

