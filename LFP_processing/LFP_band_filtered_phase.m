% This function filters the raw LFP signal in specific frequency bands and
% computes the Phase of the signal using hilbert algorithm and bin the data
% in time resolution.
% =========================================================================
% Inputs
% =========================================================================
% Data=LFP raw signal
% LFP_Fs=LFP sampling frequency
% BinTime= In(ms)
% =========================================================================
% Outputs
% =========================================================================
% LFP_ts=LFP time stamp
% Frequency bands
% =========================================================================
function[LFP_ts,DeltaBand,ThetaBand,AlphaBand,BetaBand,LowGammaBand,HighGammaBand]=LFP_band_filtered_phase(data,LFP_Fs,BinTime)
LFP_pnts=length(data);
% LFP time stamp
LFP_ts=(0:LFP_pnts-1)/LFP_Fs;
% Mean normalise and filter the raw LFP signal in delta, theta, Alpha , Beta, Low 
% and high gamma bands
mean_norm_data=data-mean(data);
LFP.DeltaBand=[1 4];
LFP.ThetaBand =[5 8];
LFP.AlphaBand = [9 12];
LFP.BetaBand = [13 30];
LFP.LowGammaBand = [31 80];
LFP.HighGammaBand = [81 150];
% 400th order FIR filter
LFP.filter_order = 400;
a = fir1(LFP.filter_order, LFP.DeltaBand./(LFP_Fs/2), 'band');
b = fir1(LFP.filter_order, LFP.ThetaBand./(LFP_Fs/2), 'band');
c = fir1(LFP.filter_order, LFP.AlphaBand./(LFP_Fs/2), 'band');
d = fir1(LFP.filter_order, LFP.BetaBand./(LFP_Fs/2), 'band');
e = fir1(LFP.filter_order, LFP.LowGammaBand./(LFP_Fs/2), 'band');
f = fir1(LFP.filter_order, LFP.HighGammaBand./(LFP_Fs/2), 'band');
% Filters the LFP data both in forwards and backwards in time
DeltaBand=filtfilt(a,1,mean_norm_data);
ThetaBand=filtfilt(b,1,mean_norm_data);
AlphaBand=filtfilt(c,1,mean_norm_data);
BetaBand=filtfilt(d,1,mean_norm_data);
LowGammaBand=filtfilt(e,1,mean_norm_data);
HighGammaBand=filtfilt(f,1,mean_norm_data);
% Concat band filtered LFP data with time stamp
DeltaBand=[LFP_ts;DeltaBand];
ThetaBand=[LFP_ts;ThetaBand];
AlphaBand=[LFP_ts;AlphaBand];
BetaBand=[LFP_ts;BetaBand];
LowGammaBand=[LFP_ts;LowGammaBand];
HighGammaBand=[LFP_ts;HighGammaBand];
save('Filtered LFP data')
load('Filtered LFP data.mat')
% Finding the Phase of the filtered LFP signal using hilbert algorithm
HPhase.D=Hilbert_Phase(DeltaBand(end,:));
HPhase.T=Hilbert_Phase(ThetaBand(end,:));
HPhase.A=Hilbert_Phase(AlphaBand(end,:));
HPhase.B=Hilbert_Phase(BetaBand(end,:));
HPhase.LG=Hilbert_Phase(LowGammaBand(end,:));
HPhase.HG=Hilbert_Phase(HighGammaBand(end,:));
Delta_Phase=HPhase.D(:,:);
Theta_Phase=HPhase.T(:,:);
Alpha_Phase=HPhase.A(:,:); 
Beta_Phase=HPhase.B(:,:);  
LowGamma_Phase=HPhase.LG(:,:);
HighGamma_Phase=HPhase.HG(:,:);
% % Binning the Phase data 
window_size=floor(LFP_Fs/BinTime);
Data_samples=mod(length(Delta_Phase),window_size);
Binned_Phase_Delta=reshape(Delta_Phase(1:end-Data_samples),window_size,[]);
Data_samples=mod(length(Theta_Phase),window_size);
Binned_Phase_Theta=reshape(Theta_Phase(1:end-Data_samples),window_size,[]);
Data_samples=mod(length(Alpha_Phase),window_size);
Binned_Phase_Alpha=reshape(Alpha_Phase(1:end-Data_samples),window_size,[]);
Data_samples=mod(length(Beta_Phase),window_size);
Binned_Phase_Beta=reshape(Beta_Phase(1:end-Data_samples),window_size,[]);
Data_samples=mod(length(LowGamma_Phase),window_size);
Binned_Phase_LowGamma=reshape(LowGamma_Phase(1:end-Data_samples),window_size,[]);
Data_samples=mod(length(HighGamma_Phase),window_size);
Binned_Phase_HighGamma=reshape(HighGamma_Phase(1:end-Data_samples),window_size,[]);
clear a b c d e f mean_norm_data LFP_Fs LFP_pnts LFP_ts Delta_Phase Theta_Phase Beta_Phase LowGamma_Phase HighGamma_Phase  
save('Hilbert Phase Results')
h = waitbar(0,'Please wait the data is in process...');
steps = 1000;
for step = 1:steps
    waitbar(step / steps)
end
close(h)
end


