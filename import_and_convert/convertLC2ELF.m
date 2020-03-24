
function ELF_data = convertLC2ELF(filepath, time_before, time_after)
% In order to work, this function requires that channels are specifically labelled in LabChart
%
% valid channel names are as follow (all are case insensitive)
%       'EMG'     : EMG chanels have to contain the string 'emg' in their names
%       'LFP'     : LFP chanels  have to contain the string 'lfp' in their names
%       'Cx Stim' : channels with logical pulses indicating begining of cortical stimuli (one pulse per stim for trains)

min_stim_interval = 0.2;

LC_data = load(filepath);
[~,fname] = fileparts(filepath);

ELF_data.format = 'ELF';

%% parse data
disp(sprintf('detected channel labels in file %s:',fname));

[num_chan,num_bloc]  = size(LC_data.datastart);
for c = 1:num_chan
    disp(sprintf('ch %d: %s',c,LC_data.titles(c,:)));
end

% prompt={'Enter channel numbers to analyze:'};
% name='Data channels';
% numlines=1;
% defaultanswer={num2str(1:num_chan-1)};
% data_chans=inputdlg(prompt,name,numlines,defaultanswer);
% data_chans = str2num(cell2mat(data_chans));
% 
% prompt={'Enter trigger channel:'};
% name = 'Trig channel';
% defaultanswer={num2str(num_chan)};
% trig_chan=inputdlg(prompt,name,numlines,defaultanswer);
% trig_chan = str2num(trig_chan{1});

disp(['enter channel numbers to analyze [' num2str(1:num_chan-1) ']:']);
data_chans = input(['enter channel numbers to analyze [' num2str(1:num_chan-1) ']:']);
if isempty(data_chans)
    data_chans = 1:num_chan-1;
end
disp(['enter trig channel [' num2str(num_chan) ']:']);
trig_chan= input(['enter trig channel [' num2str(num_chan) ']:']);
if isempty(trig_chan)
    trig_chan = num_chan;
end


for c = 1:num_chan
    % extract data from all channels
    idx = [];
    for b = 1:num_bloc
        idx = [idx LC_data.datastart(c,b):LC_data.dataend(c,b)];
    end
    % remove offset while extracting
    chan_data{c}    = detrend(LC_data.data(idx),'constant');
end

%% extract info
ELF_data.info.date         = datestr(LC_data.blocktimes,29);
ELF_data.info.utcStartTime = datestr(LC_data.blocktimes,13);
[~,ELF_data.info.blockname] = fileparts(filepath);
ELF_data.info.duration      = length(chan_data{1})/LC_data.samplerate(1); %to do: convert to datestr

%% find stim epocs

ELF_data.epocs.Stim.name = deblank(LC_data.titles(trig_chan,:));

% get sample number of when stim occured
thresh   = range(chan_data{trig_chan})/2;
%     stim_bin = Spike_detect(chan_data{trig_chan},thresh);

% debounce in case multiple stim trigger per stim train (min_stim_interval)
stim_bin = find(chan_data{trig_chan} > thresh);
stim_bin = debounce(stim_bin,min_stim_interval*LC_data.samplerate(trig_chan,1));
num_stim = length(stim_bin);

% convert to time
ELF_data.epocs.Stim.onset = stim_bin'/LC_data.samplerate(trig_chan,1);

    
%% extract snips in ELF
% if isempty(data_chans) && isempty(lfp_chans)
%     warning('Found no EMG or LFP data in file %s, operation aborted',ELF_data.info.blockname);
%     ELF_data = {};
%     return;
% else
    %check all emg have same fs
    if any(diff(LC_data.samplerate(data_chans)))
        warning('all data chans do not have the same sampling frequency in file %s, operation aborted',ELF_data.info.blockname);
        ELF_data = {};
        return;
    end
    ELF_data.snips.num_snips = num_stim;
    ELF_data.snips.onsets    = ELF_data.epocs.Stim.onset - time_before;
    ELF_data.snips.chan_list = data_chans; 
    ELF_data.snips.fs        = LC_data.samplerate(data_chans(1));
    
    ELF_data.snips.timeframe = (-time_before:(1/ELF_data.snips.fs):time_after)';
    
    % extract snips from continuous data
    ELF_data.snips.data  = cell(num_stim,length(data_chans));
    bins_before = time_before * ELF_data.snips.fs;
    bins_after  = time_after  * ELF_data.snips.fs;
    
    %%%% extract emg only:
    for s = 1:num_stim
        for c = 1:length(data_chans)
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
    ELF_data.streams.EMGs.data = chan_data(data_chans);
  
% end


