function [EMGvsStimI, StimI] = recruitment_curve(mat_array,StimAmp,EMG_vec,varargin)
%
% usage: [EMGvsStimI, StimI] = recruitment_curve(mat_array,StimAmp,EMG_vec,[params])
%
%  This function calculates, for each structure in the 'mat_array' (obtained with TDT_import + parse_tdt_data),
%  the average EMG response to stimulation and creates one figure plots it as a fonction of stimulation amplitude.
%  A vector of stimulation amplitudes in uA has to be provided, with one value for each row of the mat_array array,
%  in corresponding order. The user also has to provide a vector of EMG channels for which he wants to plot the curve.
%
%   inputs:
%       mat_array   :  [nStim x 2] cell array of "mat_array" structures 
%       StimAmp     :  [nStim x 1] vector of stimulation amplitude in uA
%       EMG_vec     :  vector of EMG channels for which to measure recruitment curve
%
%       params      :  none, one or many of these can be provided, any missing parameter will be
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
%   outputs:
%       EMGvsStimI   : [nStim x nEMGs] array of EMG responses (in uV) for each of the nEMGs channels specified in the EMG_vect
%                      input, and for each stimulation intensity (sorted in ascending order of stimulation intensity)
%       StimI        : Corresponding vector of stim intensity as provided in input, but sorted in ascending order
%
%%%% Ethierlab 2018/01 -- CE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Argument handling

% defaults parameters
params = struct('mode'         ,'rect', ...
                'rem_baseline' ,false, ...
                'window'      ,[0.002 0.010]);
            
params = parse_input_params(params,varargin);

nStimLvl = length(StimAmp);
nEMGs    = length(EMG_vec);

EMGvsStimI = nan(nStimLvl,nEMGs);

% calculate EMG response for each stim Intensity
for stimLvl = 1:nStimLvl
    EMGs      = mat_array{stimLvl,1}.snips.data(:,EMG_vec);
    timeframe = mat_array{stimLvl,1}.snips.timeframe;
    
    EMGvsStimI(stimLvl,:) = mean_EMG_response(EMGs,timeframe,params);    
end

%sort stimAmp in ascending order and re-order EMG responses accordingly
[StimI, sort_i] = sort(StimAmp);
EMGvsStimI  = 1e6*EMGvsStimI(sort_i,:); %convert to uV

%plot recruitment curves
figure;
plot(StimI,EMGvsStimI);
pretty_fig(gca);
leg_labels = cell(1,nEMGs);
for i = 1:nEMGs
    leg_labels{i} = sprintf('ch %d',EMG_vec(i));
end
legend(leg_labels);
xlabel('Stim Amplitude (uA)');
switch params.mode
    case 'rect'
        ylabel('integ. EMG response (uV*ms)');
    case 'p2p'
        ylabel('p2p EMG response (uV)');
end
title('Recruitment Curve');
    
