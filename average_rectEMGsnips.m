function [mean_rect_EMGs]= average_rectEMGsnips(tdt_struct,varargin)
%
%   usage: mean_rect_EMGs = average_rectEMGsnips(tdt_struct,varargin)
%
%

plot_flag = 0;
if nargin >1
    plot_flag = varargin{1};
end

StS_names = fieldnames(tdt_struct.snips);

if length(StS_names) > 1
    warning('not implemented to multiple strobe signals yet');
end
    
StS = getfield(tdt_struct.snips,StS_names{1});

chan_list     = unique(StS.chan);
num_chan      = length(chan_list);
num_data_pts  = size(StS.data,2);

mean_rect_EMGs = nan(num_data_pts,num_chan);

for ch = 1:num_chan
    ch_idx = StS.chan(:,1)==ch;
    %mean_rect_EMGs(:,ch) = mean(abs(StS.data(ch_idx,:)),1)';
    mean_rect_EMGs(:,ch) =abs(mean(StS.data(ch_idx,:),1))';
end

epoc_names =  fieldnames(tdt_struct.epocs);
stim_field = strcmpi(epoc_names,'stim');
stim_epoc  = getfield(tdt_struct.epocs,epoc_names{stim_field});
stim_onset1= stim_epoc.onset(1,1);

time_bin  = 1/tdt_struct.streams.EMGs.fs;
pre_stim_t= StS.ts(1,1)-stim_onset1;

time_axis = pre_stim_t:time_bin:(pre_stim_t+(num_data_pts*time_bin)-time_bin); 

if plot_flag
    ymax = max(max(mean_rect_EMGs));
    for ch=1:num_chan
        figure;
        plot(time_axis,mean_rect_EMGs(:,ch));
        ylim([-ymax/10 ymax]);
        xlabel('time (s)'); ylabel('mean rect EMG (uV?)');
        ttl_str = printf('mean rect EMG ch %d, file %s',ch,tdt_struct.info.blockname);
        ttl_str = strrep(ttl_str,'_','\_');
        title(ttl_str);
    end
end
        
    
    