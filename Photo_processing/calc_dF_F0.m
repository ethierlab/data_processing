function [dF_F0, t] = calc_dF_F0(raw_data_table,Fch,F0ch)

rows = ~isnan(raw_data_table.(Fch))&~isnan(raw_data_table.(F0ch));

Fdata  = raw_data_table.(Fch)(rows);
F0data = raw_data_table.(F0ch)(rows);
t      = raw_data_table.(1)(rows);

dF_F0 = (zscore(Fdata)-zscore(F0data));

Fs = 1/(t(2)-t(1));




%1 - detrend:
Fdata = detrend(Fdata);
F0data= detrend(F0data);

% %2 - low-pass
% lpFilt = designfilt('lowpassfir', 'FilterOrder',8,...
%              'CutoffFrequency', 12/Fs, 'SampleRate', Fs);
%          
% Fdata = filter(lpFilt,Fdata);
% F0data- filter(lpFilt,F0data);

% 2- zscore

Fdata = zscore(Fdata);


