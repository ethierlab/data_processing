% This function computes the power of frequency intervals for a given
% discrete time signal vector 
% =========================================================================
% Inputs
% =========================================================================
% data=LFP signal
% LFP_Fs=Sampling frequency of LFP data
% f1=Frequency interval (1)
% f2=Frequency interval (2)
% BinTime= In(ms)
% =========================================================================
% Outputs
% =========================================================================
% 1)Band Power
% 2)Total Power
% 3)Percentage power
% =========================================================================
function[Band_Power,Total_Power,Percentage_Power]=Power_freq_bands(data,LFP_Fs,f1,f2,BinTime)
window_size=floor(LFP_Fs/BinTime);
Data_samples=mod(length(data),window_size);
Binned_data=reshape(data(1:end-Data_samples),window_size,[]);

for i=1:size(Binned_data,2) %i: bin rank
    
    [Pxx,F] = periodogram(Binned_data(:,i),rectwin(length(Binned_data(:,i))),length(Binned_data(:,i)),LFP_Fs);
    Band_Power(i) = bandpower(Pxx,F,[f1 f2],'psd');
    Total_Power(i) = bandpower(Pxx,F,'psd');
    Percentage_Power(i) = 100*(Band_Power/Total_Power);   
    
end

save('LFP power results')
h = waitbar(0,'Please wait the data is in process...');
steps = 1000;
for step = 1:steps
    waitbar(step / steps)
end
close(h)
end
%% 
