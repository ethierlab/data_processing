function matdata_array = parse_tdt_data(tdt_struct_array,varargin)
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
matdata_array = cell(size(tdt_struct_array));

for b = 1:num_blocks
    
    tdt_struct = tdt_struct_array(b,1);
    if iscell(tdt_struct)
        tdt_struct = cell2mat(tdt_struct);
    end
    
    %% Snips
    % extract snip data from data structure
    snips_names = fieldnames(tdt_struct.snips);
    num_snips_types = length(snips_names);
    blockname = strrep(tdt_struct.info.blockname,'_','');
    
    for s = 1:num_snips_types
        
        %extract snips into data tables: extract individual channels into rows, 'trials' into columns and create timeframe
        snips_tmp   = tdt_struct.snips.(snips_names{s});
        snip_onsets = unique(snips_tmp.ts);
        num_snips   = length(snip_onsets);
        chan_list   = unique(snips_tmp.chan);
        num_chan    = length(chan_list);
        num_bins    = size(snips_tmp.data,2);
        
        %check if there was an extra snip recorded at the very beginning of the file
        if snip_onsets(1) < 0.5
            warning('first snip (out of %d) detected to begin only %.4f seconds after recording start.\n', ...
                num_snips, snip_onsets(1));
            remove = input('Do you want to exclude this first snip? Y/N [N]:','s');
            if strcmpi(remove,'y')
                snip_onsets    = snip_onsets(2:end);
                num_snips      = length(snip_onsets);
                
                snips_tmp.data     = snips_tmp.data(num_chan+1:end,:);
                snips_tmp.chan     = snips_tmp.chan(num_chan+1:end,:);
                snips_tmp.sortcode = snips_tmp.sortcode(num_chan+1:end,:);
                snips_tmp.ts       = snips_tmp.ts(num_chan+1:end,:);
                disp('first snip removed, %d snips extracted',num_snips);
            end
        end
        
        sys_time_delay = pz5_delay(params.pz5_fs,params.snip_gizmo_level);
        
        bin_dur   = double(1/snips_tmp.fs);
        timeframe = 0:bin_dur:(num_bins-1)*bin_dur;
        timeframe = timeframe - params.snip_offset - sys_time_delay;
        
        % extract data, one column per channel
        snips_array = cell(num_snips,num_chan);
        chan_list_sort = sort(chan_list)';
        for c = 1:num_chan            
            snips_array(:,c) = mat2cell(double(snips_tmp.data(snips_tmp.chan==chan_list_sort(c),:)),ones(num_snips,1));
        end
        
        matdata_array{b,1}.snips{s} = struct(...
            'timeframe'     ,{timeframe},...
            'blockname'     ,{blockname},...
            'snip_name'     ,snips_names(s),...
            'num_snips'     ,{num_snips},...
            'onsets'        ,{snip_onsets},...
            'chan_list'     ,{chan_list_sort},...
            'data'          ,{snips_array});
    end

    %% Streams
    %TODO
    
    %% Epochs
    %TODO
    
    %% Scalars
    %TODO
    
    matdata_array{b,1}.info = tdt_struct_array{b,1}.info;
    matdata_array{b,2}      = tdt_struct_array{b,2};
    
    
end


