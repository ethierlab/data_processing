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
                'snip_gizmo_level'  ,3, ...
                'pz5_fs'            ,25);

params = parse_input_params(params,varargin);


%% go through data blocks 1 by 1

num_blocks = size(tdt_struct_array,1);

%copy everything
matdata_array = tdt_struct_array;

for b = 1:num_blocks
    
    tdt_struct = tdt_struct_array(b,1);
    if iscell(tdt_struct)
        tdt_struct = cell2mat(tdt_struct);
    end
    
    %% add 'Ethier Lab Format (ELF)' format variable
    matdata_array{b,1}.format = 'ELF';
    
    %% overwrite snips in ELF:
    
    snips_name = fieldnames(tdt_struct.snips);
    if length(snips_name)>1
        error('D''oh! This function does not support multiple snip types per files');
    end
    
    snips       = tdt_struct.snips.(snips_name{:});
    snip_onsets = unique(snips.ts);
    num_snips   = length(snip_onsets);
    chan_list   = unique(snips.chan);
    num_chan    = length(chan_list);
    num_bins    = size(snips.data,2);
    
%     sys_time_delay = pz5_delay(params.pz5_fs,params.snip_gizmo_level);
%     
%     % create timeframe
%     bin_dur   = double(1/snips.fs);
%     timeframe = 0:bin_dur:(num_bins-1)*bin_dur;
%     timeframe = timeframe - params.snip_offset - sys_time_delay;

    % extract data, one column per channel
    snips_array = cell(num_snips,num_chan);
    sort_code   = nan(num_snips,num_chan);
    chan_list_sort = sort(chan_list)';
    for c = 1:num_chan
        snips_array(:,c) = mat2cell(double(snips.data(snips.chan==chan_list_sort(c),:)),ones(num_snips,1));
        sort_code(:,c)   = snips.sortcode(snips.chan==chan_list_sort(c),:);
    end
    
    matdata_array{b,1}.snips = struct(...
        'timeframe'     ,snips.timeframe,...
        'snip_name'     ,snips_name,...
        'num_snips'     ,{num_snips},...
        'onsets'        ,{snip_onsets},...
        'chan_list'     ,{chan_list_sort},...
        'data'          ,{snips_array},...
        'fs'            ,snips.fs,...
        'sortcode'      ,sort_code );
        

%% Streams
%TODO

%% Epochs
%TODO

%% Scalars
%TODO

end


