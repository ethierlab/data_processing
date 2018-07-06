
% FUNCTION: LC_import.m
% Purpose: To import Lab Chart Data into a matlab structure for further processing
%
% usage: [tdt_struct_array, num_data_files, save_path] = LC_import( [load_path], [save_path],[format],[parse_params])
%
%   inputs parameters ->provide ('param_name',param_value) pairs
%       param names   :  [default_value] comments
%       'load_path'   :  [] path of tdt files to import
%       'save_path'   :  [] path where to save the mat files
%       'time_before' :  [0.5] duration of emg data to extract before each stim, in seconds
%       'time_after'  :  [0.5] duration of emg data to extract after  each stim, in seconds
%                        (user will be queried to select load and save folders if paths are not specified)
%
%
%   outputs:
%       ELFdata  : cell array of data in Ethier Lab Format (see convertTDT2ELformat.m) with extracted data and filenames
%       num_data_files   : number of data files converted to tdt_struct format
%       save_path        : string of path where tdt_struct files where saved.
%
%%%%%Ethier lab, 06/2018, CE%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = LC_import(varargin)

% default options
params = struct(...
    'load_path'         ,[],...
    'save_path'         ,[],...
    'time_before'       ,0.5,...
    'time_after'        ,1);

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
data_dir = params.load_path;

LC_mat_files = dir([data_dir '/*.mat']);

num_data_files = length(LC_mat_files);
if ~num_data_files
    disp('no data files found in this folder');
    varargout = {[],[],[]};
    return;
end

[~,index] = sortrows({LC_mat_files.date}.'); LC_mat_files = LC_mat_files(index); clear index

blocknames = {LC_mat_files.name};

matdata = cell(num_data_files,2);

%save folder:
if isempty(params.save_path)
    disp('Where do you want the mat files to be saved');
    params.save_path = uigetdir('','Where do you want the mat files to be saved');
    if ~params.save_path
        %user pressed cancel
        varargout = {[],[],[]};
        return;
    end
end


% Load and convert all data files
for f = 1:num_data_files
    % remove file extension
    [~,block] = fileparts(blocknames{f});
    
    ELF_struct = convertLC2ELF(fullfile(data_dir,blocknames{f}),params.time_before,params.time_after);
    
    
    %name the structure the same as the file and save it.
    %but modify name to make sure it starts with a letter
    %and doesn't have the '-' or space character
    if ~isnan(str2double(block(1)))
        %starts with number
        block = ['m' block];
    end
    block = strrep(block,'-','');
    block = strrep(block,' ','');
    eval([block '= ELF_struct;']);
       
    matdata(f,:) = [ {ELF_struct}, {block} ];
    
    save(fullfile(params.save_path,block),block);
    
end
save(fullfile(params.save_path,'all_data_combined'),'matdata');

varargout = {matdata, num_data_files, params.save_path};
end