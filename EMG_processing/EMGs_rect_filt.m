function rect_EMGs = EMGs_rect_filt(EMGs, fs, varargin)
%
% usage: rect_EMGs = EMGs_rect_filt(EMGs,varargin)
%
%  This function rectifies and filters an EMG signals.
%       it applies a highpass filter, recitifies, and applies a lowpass filter, in that order
%
%   inputs:
%       EMGs        :  [npts x nEMGs] array of EMG signals
%       fs          :  sampling rate in Hz of EMG data
%
%       params      :  [default values in brackets]
%                      none, one or many of these fields can be provided in the params argument
%                      structure, any missing field will be set to its default value.
%                      use ('param_name',param_value) pairs in 
%
%           'lp'    : [10] lowpass cutoff frequency in Hz
%           'hp'    : [50] highpass cutoff frequency in Hz
%           
%
%
%%%% Ethierlab 2021/02 -- CE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[npts, nEMGs] = size(EMGs);
rect_EMGs     = nan(npts, nEMGs);   

% defaults parameters
params = struct('lp' , 10, ...
                'hp' , 50 );
            
params = parse_input_params(params,varargin);

for e = 1:nEMGs
    tmp_emg = EMGs(:,e);
       
    % 1 - high-pass
    tmp_emg = highpass(tmp_emg,params.hp,fs);
    
    % 2 - rectify
    tmp_emg = abs(tmp_emg);
    
    % 3 - low pass
    tmp_emg = lowpass(tmp_emg,params.lp,fs);
    
    rect_EMGs(:,e) = tmp_emg;
end