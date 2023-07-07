function matdata_array = convertTDT2ELformat(tdt_struct_array,varargin)
%
% usage:  matdata_array = parse_tdt_data(tdt_struct_array,[params])
%
% converts "tdt_struct" file(s) to a more readable format, according to parameters specified
%                                   as ('param names', param_value) pairs
%
%         tdt_struct_array        : single or array of data structures with Streams, epocs, etc., as obtained with TDT_import.m
%
%         parameters :            [default values in brackets]
%                                   none, one or many of these fields can
%                                   be provided in the params argument
%                                   structure, any missing field will be
%                                   set to its default value. use ('param_name',param_value) pairs in argument
%
%               'snip_offset'      : [0]  time in seconds of recorded data before 'time 0' (buffered data)
%                                      TODO: read the snip_offset from TDT file somehow
%               'snip_gizmo_level' : [3] this is really annoying, but each 'level' of gizmo branching adds a 2 sample delay
%                                     to the data recordings. We have to take that into account for precise timing analysis.
%                                     By default, we will assume the snip gizmo is on the third level like so:
%                                        pz5
%                                         -map(1)
%                                            -filter(2)
%                                               -snip storage(3)
%                                       TODO: get this info directly from TDT file ?????
%               'pz5_fs'           : [25] pz5 sampling frequency, in kHz
%                                        TODO: get this info directly from TDT file ?????
%
%%%% Ethierlab 2017/12/13 -- CE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Params handling
% defaults parameters
params = struct('snip_offset'       ,0, ...
                'snip_gizmo_level'  ,1, ...
                'pz5_fs'            ,25);

params = parse_input_params(params,varargin);


%% go through data blocks 1 by 1

num_blocks = size(tdt_struct_array,1);

%copy everything
if num_blocks == 1
    matdata_array = {tdt_struct_array};
else
    matdata_array = tdt_struct_array;
end

for b = 1:num_blocks

    tdt_struct = tdt_struct_array(b,1);
    if iscell(tdt_struct)
        tdt_struct = cell2mat(tdt_struct);
    end

    %% add 'Ethier Lab Format (ELF)' format variable
    if isfield(tdt_struct,'format')
        if strcmpi(tdt_struct.format,'ELF')
            disp('Data already in ELF');
            return
        end
        matdata_array{b,1}.format = 'ELF';
    end

    %% overwrite snips in ELF:

    snips_name = fieldnames(tdt_struct.snips);
    if length(snips_name)>1
        warning('multiple snip types per files');
        fprintf('processing snips for %s\n', snips_name{1});
        snips_name = snips_name(1);
    end

    snips       = tdt_struct.snips.(snips_name{:});
    snip_onsets = snips.ts;
    num_snips   = length(snip_onsets);
    chan_list   = unique(snips.chan);
    num_chan    = length(chan_list);
    num_bins    = size(snips.data,2);

    sys_time_delay = pz5_delay(params.pz5_fs,params.snip_gizmo_level);

    % create timeframe
    bin_dur   = double(1/snips.fs);
    timeframe = 0:bin_dur:(num_bins-1)*bin_dur;
    timeframe = timeframe - params.snip_offset - sys_time_delay;

    % extract data, one column per channel
    snips_array = cell(1,num_chan);
    sort_code   = cell(1,num_chan);
    chan_list_sort = sort(chan_list)';
    for c = 1:num_chan
%         snips_array(:,c) = mat2cell(double(snips.data(snips.chan==chan_list_sort(c),:)),ones(num_snips,1));
        snips_array(:,c) = {double(snips.data(snips.chan==chan_list_sort(c),:))};
        sort_code(:,c)   = {snips.sortcode(snips.chan==chan_list_sort(c),:)};
    end

    matdata_array{b,1}.snips = struct(...
        'timeframe'     ,timeframe,...
        'snip_name'     ,snips_name,...
        'num_snips'     ,{num_snips},...
        'onsets'        ,{snip_onsets},...
        'chan_list'     ,{chan_list_sort},...
        'data'          ,{snips_array},...
        'fs'            ,snips.fs,...
        'sortcode'      ,sort_code );

    clear snips timeframe snips_name num_snips snip_onsets chan_list_sort snips_array sort_code num_chan num_bins

%% Streams

    streams_name = fieldnames(tdt_struct.streams);
    if length(streams_name)>1
        error('D''oh! This function does not yet support multiple stream types per files');
    end

    streams  = tdt_struct.streams.(streams_name{:});
    num_bins = size(streams.data,2);

    % create timeframe
    bin_dur   = double(1/streams.fs);
    timeframe = 0:bin_dur:(num_bins-1)*bin_dur;

    %copy original struct directly in data
    matdata_array{b,1}.streams = streams;

    % add timeframe and reformat data to double and column-wise
    matdata_array{b,1}.streams.timeframe = timeframe;
    matdata_array{b,1}.streams.data = double(streams.data');

    clear timeframe streams_name num_streams stream_onsets chan_list_sort streams_array streams sort_code num_chan num_bins

%% Epochs
%TODO

%% Scalars
%TODO

end
