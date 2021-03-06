% FUNCTION: TDT_import.m
% C Ethier, W Ting, 2017
% Purpose: To import TDT Data into a matlab structure for further processing
%
% usage: [tdt_struct_array, num_data_files, save_path] = TDT_import( [load_path], [save_path],[format],[parse_params]) 
%     
%   inputs parameters ->provide ('param_name',param_value) pairs
%       param names   :  [default_value] comments
%       'load_path'   :  [] path of tdt files to import
%       'save_path'   :  [] path where to save the mat files
%                        (user will be queried to select load and save folders if paths are not specified)
%       'format'      :  ['raw_tdt'] either 'raw_tdt' or 'parse'.
%                          'raw_tdt' output has the raw .epochs, .snips, .streams... output from TDT2mat.m
%                          'parse' option processes the data a bit more to extract channels, account for delays, etc.,
%                           by calling parse_tdt_data.m at the end of the import.
%       'parse_params':  if the 'parse' format is selected, you have to provide a structure containing the parsing parameters for the
%                           parse_tdt_data function. See parse_tdt_data.m for further description.
%
%
%   outputs:
%       tdt_struct_array : cell array of tdt_structs with extracted data and filenames
%       num_data_files   : number of data files converted to tdt_struct format
%       save_path        : string of path where tdt_struct files where saved.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = TDT_import(varargin)
    
    % default options
    params = struct(...
        'load_path'         ,[],...
        'save_path'         ,[],...
        'format'            ,'raw_tdt',...
        'parse_params'      ,struct('snip_offset'       ,0.025, ...
                                    'snip_gizmo_level'  ,3, ...
                                    'pz5_fs'            ,3) );
    
    params = parse_input_params(params,varargin);
    
    % load folder:
    if isempty(params.load_path)  
        disp('Open parent directory where DATA is stored');
        params.load_path = uigetdir('','Open parent directory where DATA is stored');
        if ~params.load_path
            varargout = {[],[],[]};
            return
        end
    end
    
    if params.load_path(end) == filesep
        params.load_path = params.load_path(1:end-1);
    end
    
    data_dir = dir(params.load_path);
    
    if isempty(data_dir)
        warning('empty directory');
        varargout = {[],[],[]};
        return;
    end

    
    dir_idx = find([data_dir.isdir] & ~strncmp({data_dir.name},'.',1));

    num_data_files = length(dir_idx);

    % if no sub folders, maybe user already specified a specific file within a tdt tank
    if ~num_data_files
        tsqList =  dir([params.load_path filesep '*.tsq']);
        if isempty(tsqList) || length(tsqList)>1
            warning('no TDT files found or multiple .tsq files in folder, something is wrong')
            num_data_files = 0;
            tdt_struct = [];
            params.save_path = [];
        else
        % there is 1 .tsq file within specified folder, that's the data to import
        num_data_files = length(tsqList); % which is 1...
        filesep_idx = strfind(params.load_path,filesep);
        blocknames  = {params.load_path(filesep_idx(end)+1:end)};
        blockpath   = params.load_path(1:filesep_idx(end)-1);
        end
    else
        blocknames = {data_dir(dir_idx).name};
        blockpath  = params.load_path;
    end
    matdata = cell(num_data_files,2);
      
    %save folder:
    if isempty(params.save_path)
        disp('Where do you want the mat files to be saved');
        params.save_path = params.load_path;
        params.save_path = uigetdir(params.save_path,'Where do you want the mat files to be saved');
        if ~params.save_path
            %user pressed cancel
            varargout = {[],[],[]};
            return;
        end
    end
    
    
    % Load and convert all data files
    for f = 1:num_data_files
        % TODO: check file extension if it really looks like a data tank
        block = blocknames{f};
        
        tdt_struct = TDTbin2mat(fullfile(blockpath,block));

   
        %name the structure the same as the file and save it.
        %but modify name to make sure it starts with a letter
        %and doesn't have the '-' character
        block = ['m' strrep(block,'-','')];   
        eval([block '= tdt_struct;']);
        
        % check if there is a mismatch between stim epocs onsets and snips ts
        % also creates a "timeframe" variable in snips, relative to stim epocs
        if isfield(tdt_struct.epocs, 'Stim')
            % check if there is a stim structure...
            tdt_struct = fix_snips_epocs_mismatch(tdt_struct);
        end
        
        matdata(f,:) = [ {tdt_struct}, {block} ];
        clear tdt_struct;
        
        save(fullfile(params.save_path,block),block,'-v7.3');
        
    end
        
    if strcmp(params.format,'parse')
        matdata = parse_tdt_data(matdata,params.parse_params);
    end
    
    if num_data_files > 1
        save(fullfile(params.save_path,'all_data_combined'),'matdata','-v7.3');
    else
        matdata = matdata{1,1};
    end

    varargout = {matdata, num_data_files, params.save_path};
end