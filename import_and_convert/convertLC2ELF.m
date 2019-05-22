function ELF_data = convertLC2ELF(filepath, time_before, time_after)
% In order to work, this function requires that channels are specifically labelled in LabChart
%
% valid channel names are as follow (all are case insensitive)
%       'EMG'     : EMG chanels have to contain the string 'emg' in their names
%       'LFP'     : LFP chanels  have to contain the string 'lfp' in their names
%       'Cx Stim' : channels with logical pulses indicating begining of cortical stimuli (one pulse per stim for trains)

min_stim_interval = 0.2;

LC_data = load(filepath);

ELF_data.format = 'ELF';

%% parse data

[num_chan,num_bloc]  = size(LC_data.datastart);


chan_data    = cell (1,num_chan);
emg_chans    = false(1,num_chan);
lfp_chans    = false(1,num_chan);
cx_stim_chan = false(1,num_chan);


for c = 1:num_chan
    % extract data from all channels
    idx = [];
    for b = 1:num_bloc
        idx = [idx LC_data.datastart(c,b):LC_data.dataend(c,b)];
    end
    chan_data{c}    = LC_data.data(idx);
    % find channel types
    emg_chans(c)    = ~isempty(strfind(lower(LC_data.titles(c,:)),'emg'));
    lfp_chans(c)    = ~isempty(strfind(lower(LC_data.titles(c,:)),'lfp'));
    cx_stim_chan(c) = ~isempty(strfind(lower(LC_data.titles(c,:)),'cx'));
    m_stim_chan(c) = ~isempty(strfind(lower(LC_data.titles(c,:)),'m'));
    n_stim_chan(c) = ~isempty(strfind(lower(LC_data.titles(c,:)),'n'));
    opto_stim_chan(c)= ~isempty(strfind(lower(LC_data.titles(c,:)),'opto'));
    % add more channel type extraction here when needed
end

emg_chans    = find(emg_chans);
lfp_chans    = find(lfp_chans);
num_emg      = length(emg_chans);
num_lfp      = length(lfp_chans);
cx_stim_chan = find(cx_stim_chan);
m_stim_chan = find(m_stim_chan);
n_stim_chan = find(n_stim_chan);
opto_stim_chan = find(opto_stim_chan);

%% extract info
ELF_data.info.date         = datestr(LC_data.blocktimes,29);
ELF_data.info.utcStartTime = datestr(LC_data.blocktimes,13);
[~,ELF_data.info.blockname] = fileparts(filepath);
ELF_data.info.duration      = length(chan_data{1})/LC_data.samplerate(1); %to do: convert to datestr

%% find stim epocs
trig_chan = [];
if ~isempty(cx_stim_chan)
    trig_chan = cx_stim_chan;
elseif ~isempty(opto_stim_chan)
    trig_chan = opto_stim_chan;
elseif ~isempty(m_stim_chan)
    trig_chan = m_stim_chan;
elseif ~isempty(n_stim_chan)
    trig_chan = n_stim_chan;
end

if isempty(trig_chan)
    warning('Found no stim channel in data');
   return;
else
    if length(trig_chan)>1
        warning('Found multiple Stim channels');
        tmp_ch = find(cx_stim_chan,1,'first');
        fprintf('Using first Stim chan : %s\n',LC_data.titles(tmp_ch,:));
        trig_chan = trig_chan(1);
    end
    
    ELF_data.epocs.Stim.name = deblank(LC_data.titles(trig_chan,:));
    
    % get sample number of when stim occured
    thresh   = range(chan_data{trig_chan})/2;
%     stim_bin = Spike_detect(chan_data{trig_chan},thresh);
    
    % debounce in case multiple stim trigger per stim train (min 50 ms between stim)
    stim_bin = find(chan_data{trig_chan} > thresh);
    stim_bin = debounce(stim_bin,min_stim_interval*LC_data.samplerate(trig_chan,1));
    num_stim = length(stim_bin);
    
    % convert to time
    ELF_data.epocs.Stim.onset = stim_bin'/LC_data.samplerate(trig_chan,1);
end

%% extract snips in ELF
if isempty(emg_chans) && isempty(lfp_chans)
    warning('Found no EMG or LFP data in file %s, operation aborted',ELF_data.info.blockname);
    ELF_data = {};
    return;
else
    %check all emg have same fs
    if any(diff(LC_data.samplerate([emg_chans lfp_chans])))
        warning('the emg and lfp signals do not have the same sampling frequency in file %s, operation aborted',ELF_data.info.blockname);
        ELF_data = {};
        return;
    end
    ELF_data.snips.num_snips = num_stim;
    ELF_data.snips.onsets    = ELF_data.epocs.Stim.onset - time_before;
    ELF_data.snips.chan_list = [emg_chans lfp_chans]; 
    if ~isempty(emg_chans)
        ELF_data.snips.fs        = LC_data.samplerate(emg_chans(1));
    else
        ELF_data.snips.fs        = LC_data.samplerate(lfp_chans(1));
    end
    ELF_data.snips.timeframe = (-time_before:(1/ELF_data.snips.fs):time_after)';
    
    % extract snips from continuous data
    ELF_data.snips.data  = cell(num_stim,num_emg+num_lfp);
    bins_before = time_before * ELF_data.snips.fs;
    bins_after  = time_after  * ELF_data.snips.fs;
    
    %%%% extract emg only:
%     for s = 1:num_stim
%         for e = 1:num_emg
%             if stim_bin(s)-bins_before < 0 
%                 warning('skipped first stim as it occurred too early');
%                 continue;
%             elseif stim_bin(s)+bins_after > length(chan_data{emg_chans(e)})
%                 warning('skipped last stim as it occurred too late');
%                 continue;
%             end
%             ELF_data.snips.data{s,e} = chan_data{emg_chans(e)}((stim_bin(s)-bins_before):(stim_bin(s)+bins_after));
%         end
%     end

   %%%%% OR.... 
    % concat emgs and lfps for now:
    data_chans = [emg_chans lfp_chans];
    num_chans = num_emg+num_lfp;    
    for s = 1:num_stim
        for c = 1:num_chans
            if stim_bin(s)-bins_before < 0 
                warning('skipped first stim as it occurred too early');
                continue;
            elseif stim_bin(s)+bins_after > length(chan_data{data_chans(c)})
                warning('skipped last stim as it occurred too late');
                continue;
            end
            ELF_data.snips.data{s,c} = chan_data{data_chans(c)}((stim_bin(s)-bins_before):(stim_bin(s)+bins_after));
        end
    end
    

%% extract streams

    ELF_data.streams.EMGs.fs   = ELF_data.snips.fs;
    ELF_data.streams.EMGs.data = chan_data(emg_chans);
  
end


