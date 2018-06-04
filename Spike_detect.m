function [maximum_pos1] = Spike_detect(spike,threshold_val)
%SPIKE_DETECT Summary of this function goes here
%   maximum_pos1=position des spikes
if size(spike,1)==1;
   spike=spike'; 
end

% Remove what is over the threshold and keep only the peak of the spike
y1=threshold_val;
if y1>0;
    spike_fantom_p=find(spike>y1);
 
    dif_sp_fantom_p= diff(spike_fantom_p)>1;
    p_end_right=spike_fantom_p(dif_sp_fantom_p);
    spike_reverse=flipud(spike);
    spike_fantom_p=find(spike_reverse>y1);
    dif_sp_fantom_p=find(diff(spike_fantom_p)>1);
    p_end_left=numel(spike)-spike_fantom_p(dif_sp_fantom_p);
end
first_s=p_end_right(1);
p_end_right=p_end_right(2:end);
p_end_left=flipud(p_end_left);
last_s=p_end_left(end);
p_end_left=p_end_left(1:end-1);
maximum_pos1=[];
for i=1:numel(p_end_left);
    d=p_end_left(i);
    f=p_end_right(i);
    
    
    maximum_pos1(i)=d-1;
end
maximum_pos1=[first_s-1 maximum_pos1 last_s+1]; %position des spikes en position échantillon
%retrait des spikes au dessus de la valeur threshold
spike01=zeros(1,numel(spike));
spike01(maximum_pos1)=1;
%plot(spike);hold on;plot(p_end_left,spike(p_end_left),'.r');
end

