function varargout = SimpleSpikeDataProcessor(varargin)
% SIMPLESPIKEDATAPROCESSOR MATLAB code for SimpleSpikeDataProcessor.fig
%      SIMPLESPIKEDATAPROCESSOR, by itself, creates a new SIMPLESPIKEDATAPROCESSOR or raises the existing
%      singleton*.
%
%      H = SIMPLESPIKEDATAPROCESSOR returns the handle to a new SIMPLESPIKEDATAPROCESSOR or the handle to
%      the existing singleton*.
%
%      SIMPLESPIKEDATAPROCESSOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIMPLESPIKEDATAPROCESSOR.M with the given input arguments.
%
%      SIMPLESPIKEDATAPROCESSOR('Property','Value',...) creates a new SIMPLESPIKEDATAPROCESSOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SimpleSpikeDataProcessor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SimpleSpikeDataProcessor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SimpleSpikeDataProcessor

% Last Modified by GUIDE v2.5 27-May-2019 17:41:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SimpleSpikeDataProcessor_OpeningFcn, ...
    'gui_OutputFcn',  @SimpleSpikeDataProcessor_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SimpleSpikeDataProcessor is made visible.
function SimpleSpikeDataProcessor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SimpleSpikeDataProcessor (see VARARGIN)

% Choose default command line output for SimpleSpikeDataProcessor
handles.output    = hObject;

% snip extraction params:
handles.thresh    = -75;
handles.reject    = 400;
handles.presnip   = 50;
handles.presnipT  = [1 5]; %first 8 bins
handles.postsnip  = 0;
handles.postsnipT = [20 25];
handles.postwind  = 100;
handles.postwindT = [35 40];

handles.chanlist     = [];
handles.numchan      = 0;
handles.chan         = 0;
handles.stream_t0    = 0;
handles.stream_width = 60;  % 60 sec of raw data
handles.snip_width   = 40;  % 50 pts ~= 2 ms snippets @ 24.414kHz
handles.numsnips     = 1000; % plot 1000 snips max

handles.data     = [];
handles.store    = 'spik';

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SimpleSpikeDataProcessor wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SimpleSpikeDataProcessor_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



%% BUTTONS

function loadTDT_button_Callback(hObject, eventdata, handles)
BLOCKPATH = uigetdir('/Users/christianethier/Google Drive (Work)/Projects/Chronic Array and Mototrak/sample data/jados-19-04-30-am','Select TDT data block');

if BLOCKPATH
    tsqList = dir([BLOCKPATH filesep '*.tsq']);
    if isempty(tsqList)
        warning('no .tsq file in specified folder');
        return;
    else
        handles.blockpath_edit.String = BLOCKPATH;
        
        % get block info
        heads = TDTbin2mat(BLOCKPATH, 'HEADERS', 1);
        
        % Find spikes store -- always 'spik'? make user specify that? use 'type' from TDTbin2mat to extract 'snips' only?
        if ~isfield(heads.stores, handles.store)
            warning('no ''spik'' store in specified file, sadly this is hardcoded in this function for now... sorry!');
            return;
        end
        
        handles.chanlist    = sort(unique(heads.stores.spik.chan));
        handles.numchan     = length(handles.chanlist);
        handles.chan        = handles.chanlist(1);
        handles.stream_t0   = 0; % start at beginning of data (first 60 sec);
        
        % read data from first channel
        handles = read_chan(handles);
        
    end
end

% Update handles structure
guidata(hObject, handles);

function thresh_button_Callback(hObject, eventdata, handles)
handles = extract_snips(handles);
update_snips(handles);

num_snips = size(handles.data.snips.Snip.data,1);
fprintf('Extracted %d snips\n',num_snips);

% Update handles structure
guidata(hObject, handles);

function reject_button_Callback(hObject, eventdata, handles)
if isempty(handles.data)
    disp('Please threshold data first to extract snips');
    return
end
rem_idx = find(any(abs(handles.data.snips.Snip.data') > handles.reject));

num_snips = size(handles.data.snips.Snip.data,1);

% actually remove all relevant snips
handles.data.snips.Snip.data(rem_idx,:)     = [];
handles.data.snips.Snip.sortcode(rem_idx,:) = [];
handles.data.snips.Snip.ts(rem_idx,:)       = [];

fprintf('Removed %d of %d snips\n',length(rem_idx),num_snips);
update_snips(handles);

% Update handles structure
guidata(hObject, handles);

function pre_snip_wind_button_Callback(hObject, eventdata, handles)
if isempty(handles.data)
    disp('Please threshold data first to extract snips');
    return
end
rem_idx = find(any(abs(handles.data.snips.Snip.data(:,handles.presnipT(1):handles.presnipT(2)))' > handles.presnip));

num_snips = size(handles.data.snips.Snip.data,1);

% actually remove all relevant snips
handles.data.snips.Snip.data(rem_idx,:)     = [];
handles.data.snips.Snip.sortcode(rem_idx,:) = [];
handles.data.snips.Snip.ts(rem_idx,:)       = [];

fprintf('Removed %d of %d snips\n',length(rem_idx),num_snips);
update_snips(handles);

% Update handles structure
guidata(hObject, handles);

function post_snip_thresh_button_Callback(hObject, eventdata, handles)
if isempty(handles.data)
    disp('Please threshold data first to extract snips');
    return
end
rem_idx = find(any(handles.data.snips.Snip.data(:,handles.postsnipT(1):handles.postsnipT(2))' < handles.postsnip));

num_snips = size(handles.data.snips.Snip.data,1);

% actually remove all relevant snips
handles.data.snips.Snip.data(rem_idx,:)     = [];
handles.data.snips.Snip.sortcode(rem_idx,:) = [];
handles.data.snips.Snip.ts(rem_idx,:)       = [];

fprintf('Removed %d of %d snips\n',length(rem_idx),num_snips);
update_snips(handles);

% Update handles structure
guidata(hObject, handles);

function post_snip_wind_button_Callback(hObject, eventdata, handles)
if isempty(handles.data)
    disp('Please threshold data first to extract snips');
    return
end
rem_idx = find(any(abs(handles.data.snips.Snip.data(:,handles.postwindT(1):handles.postwindT(2)))' > handles.postwind));

num_snips = size(handles.data.snips.Snip.data,1);

% actually remove all relevant snips
handles.data.snips.Snip.data(rem_idx,:)     = [];
handles.data.snips.Snip.sortcode(rem_idx,:) = [];
handles.data.snips.Snip.ts(rem_idx,:)       = [];

fprintf('Removed %d of %d snips\n',length(rem_idx),num_snips);
update_snips(handles);

% Update handles structure
guidata(hObject, handles);

function apply_all_button_Callback(hObject, eventdata, handles)
% thresholding
handles = extract_snips(handles);
num_snips = size(handles.data.snips.Snip.data,1);
fprintf('Extracted %d snips\n',num_snips);

% remove snips above reject line
rem_idx = find(any(abs(handles.data.snips.Snip.data') > handles.reject));

% remove snips when outside presnip window
rem_idx = [rem_idx find(any(abs(handles.data.snips.Snip.data(:,handles.presnipT(1):handles.presnipT(2)))' > handles.presnip))];

% remove snips when below postsnip threshold
rem_idx = [rem_idx find(any(handles.data.snips.Snip.data(:,handles.postsnipT(1):handles.postsnipT(2))' < handles.postsnip))];

% remove snips when outside postsnip window
rem_idx = [rem_idx find(any(abs(handles.data.snips.Snip.data(:,handles.postwindT(1):handles.postwindT(2)))' > handles.postwind))];

rem_idx = unique(rem_idx);

% actually remove all relevant snips
handles.data.snips.Snip.data(rem_idx,:)     = [];
handles.data.snips.Snip.sortcode(rem_idx,:) = [];
handles.data.snips.Snip.ts(rem_idx,:)       = [];

fprintf('Removed %d of %d snips\n',length(rem_idx),num_snips);
update_snips(handles);

% Update handles structure
guidata(hObject, handles);

function save_button_Callback(hObject, eventdata, handles)

[filename, pathname] = uiputfile([handles.blockpath_edit.String filesep handles.data.info.blockname '_snips.mat'], 'Save as');

if ~filename
    disp('File not saved');
else
    % save current channel
    fprintf('saving current channel...'); 
    save_chan(handles);
    disp('done.');
    
%     % aggregate stream data in a single struct
%     disp('Reading all streamed channels into a single structure...');
%     
%     % read data from all channels
%     handles.data = TDTbin2mat(handles.blockpath_edit.String, 'STORE', handles.store);
%     % filter data 300-5000 Hz
%     handles.data = TDTdigitalfilter(handles.data, handles.store, [300 5000]);
%     % convert to uV
%     handles.data.streams.(handles.store).data = handles.data.streams.(handles.store).data *1e6;
%     disp('done.');
    
    % aggregate snips from all saved channels
    disp('Aggregating snips from all processed channels...');
    Snip = [];
    for c=handles.chanlist
        fprintf('ch %d...\n',c);
        
        % load saved snips
        if ~isempty(dir([handles.blockpath_edit.String filesep 'chandata' filesep 'ch' num2str(c) '_snips.mat']))
            S = load([handles.blockpath_edit.String filesep 'chandata' filesep 'ch' num2str(c) '_snips.mat']);
            Snip = mergeSnips(S,Snip);
        end
    end
    fprintf('saving...');
    save(fullfile(pathname,filename),'-struct','Snip');
    fprintf('%s saved successfully\n',filename);
        
end

function done_button_Callback(hObject, eventdata, handles)

function prev_chan_button_Callback(hObject, eventdata, handles)

% save snips from current channel
save_chan(handles);

% load prev chan
idx = find(handles.chan == handles.chanlist);
handles.chan = handles.chanlist(idx-1);
handles.stream_t0   = 0; % start at beginning of data (first 60 sec);

handles = read_chan(handles);

% Update handles structure
guidata(hObject, handles);   

function next_chan_button_Callback(hObject, eventdata, handles)
% save snips from current channel
save_chan(handles);

% load next chan
idx = find(handles.chan == handles.chanlist);
handles.chan = handles.chanlist(idx+1);
handles.stream_t0   = 0; % start at beginning of data (first 60 sec);

handles = read_chan(handles);

% Update handles structure
guidata(hObject, handles);    
   
function prev60s_button_Callback(hObject, eventdata, handles)
function next60s_button_Callback(hObject, eventdata, handles)

%% Functions

function update_stream(handles)

set(handles.figure1,'CurrentAxes',handles.stream_axes);

% select and plot relevant data and timeframe
yvals = handles.data.streams.(handles.store).data( handles.stream_timeframe >= handles.stream_t0 & handles.stream_timeframe < handles.stream_t0 + handles.stream_width);
xvals = handles.stream_timeframe( handles.stream_timeframe >= handles.stream_t0 & handles.stream_timeframe < handles.stream_t0 + handles.stream_width);

cla(handles.stream_axes);
hold off; axis auto;
plot(handles.stream_axes,xvals, yvals,'Color',[.5 .5 .5]);
hold on; axis manual;
ylabel('uV'); xlabel('time (s)');
title(sprintf('ch %d',handles.chan));

% if big artifacts, auto scale zooms out too much to see real data. Set a max yrange of +- 500 uV
yy = ylim;  ylim([max(-500,yy(1)) min(500,yy(2))]);

% plot threshold line
plot(handles.stream_axes,[xvals(1) xvals(end)],[handles.thresh handles.thresh],'k','Linestyle','--','LineWidth',2); %plot black dashed line

%plot reject lines
plot(handles.stream_axes,[xvals(1) xvals(end)],[handles.reject handles.reject],'r--','LineWidth',2); %plot red dashed line
plot(handles.stream_axes,[xvals(1) xvals(end)],[-handles.reject -handles.reject],'r--','linewidth',2); %plot red dashed line

function update_snips(handles)

set(handles.figure1,'CurrentAxes',handles.snips_axes);

cla(handles.snips_axes);
hold off; axis auto;

% plot snips in grey
numsnips = min(handles.numsnips,size(handles.data.snips.Snip.data,1));

if numsnips
plot(handles.snips_axes,handles.snips_timeframe,handles.data.snips.Snip.data(1:numsnips,:),'Color',[.5 .5 .5]);
else
    warning('no snips left to display');
end
hold on; axis manual
xlim([handles.snips_timeframe(1) handles.snips_timeframe(end)]);
ylabel('uV'); xlabel('ms'); title(sprintf('first %d snips',numsnips));

% if big artifacts, auto scale zooms out too much to see real data. Set a max yrange of +- 500 uV
yy = ylim;  ylim([max(-500,yy(1)) min(500,yy(2))]);

% plot presnip window line
plot(handles.snips_axes,[handles.snips_timeframe(handles.presnipT(1)) handles.snips_timeframe(handles.presnipT(2))],[ handles.presnip  handles.presnip],'b-','LineWidth',2);
plot(handles.snips_axes,[handles.snips_timeframe(handles.presnipT(1)) handles.snips_timeframe(handles.presnipT(2))],[-handles.presnip -handles.presnip],'b-','LineWidth',2);

% postsnip thresh
plot(handles.snips_axes,[handles.snips_timeframe(handles.postsnipT(1)) handles.snips_timeframe(handles.postsnipT(2))],[handles.postsnip handles.postsnip],'g-','LineWidth',2);

% postsnip window
plot(handles.snips_axes,[handles.snips_timeframe(handles.postwindT(1)) handles.snips_timeframe(handles.postwindT(2))],[ handles.postwind  handles.postwind],'c-','LineWidth',2);
plot(handles.snips_axes,[handles.snips_timeframe(handles.postwindT(1)) handles.snips_timeframe(handles.postwindT(2))],[-handles.postwind -handles.postwind],'c-','LineWidth',2);

% plot threshold line
plot(handles.snips_axes,[handles.snips_timeframe(1) handles.snips_timeframe(end)],[handles.thresh handles.thresh],'k','Linestyle','--','LineWidth',2); %plot black dashed line

% plot reject lines
plot(handles.snips_axes,[handles.snips_timeframe(1) handles.snips_timeframe(end)],[ handles.reject  handles.reject],'r--','LineWidth',2); %plot red dashed line
plot(handles.snips_axes,[handles.snips_timeframe(1) handles.snips_timeframe(end)],[-handles.reject -handles.reject],'r--','linewidth',2); %plot red dashed line

function handles = read_chan(handles)

% read the specified data from our block into a Matlab structure
handles.data = TDTbin2mat(handles.blockpath_edit.String, 'STORE', handles.store, 'CHANNEL', handles.chan);

% filter data 300-5000 Hz
handles.data = TDTdigitalfilter(handles.data, handles.store, [300 5000]);

% convert to uV
handles.data.streams.(handles.store).data = handles.data.streams.(handles.store).data *1e6;

handles.stream_timeframe = ((1:length(handles.data.streams.(handles.store).data))-1)/handles.data.streams.(handles.store).fs;

% per TDTthresh:
%pre_wave = floor(NPTS/4)-1;
%post_wave = NPTS - pre_wave-1;
pre_wave = floor(handles.snip_width/4);
post_wave = handles.snip_width-pre_wave-1;
handles.snips_timeframe  = (-pre_wave:post_wave)/handles.data.streams.(handles.store).fs*1e3; % in ms

% enable/disable buttons
if handles.chan == handles.chanlist(1)
    handles.prev_chan_button.Enable = 'off';
else
    handles.prev_chan_button.Enable = 'on';
end
if handles.chan == handles.chanlist(end)
    handles.next_chan_button.Enable = 'off';
else
    handles.next_chan_button.Enable = 'on';
end

saved_snips      = ~isempty(dir([handles.blockpath_edit.String filesep 'chandata' filesep 'ch' num2str(handles.chan) '_snips.mat']));

% load saved snips if already processed 
if saved_snips
    handles.data.snips.Snip = load([handles.blockpath_edit.String filesep 'chandata' filesep 'ch' num2str(handles.chan) '_snips.mat']);
else
    handles = extract_snips(handles);
    num_snips = size(handles.data.snips.Snip.data,1);
    fprintf('Extracted %d snips\n',num_snips);
end

snips_compat = length(handles.snips_timeframe) == size(handles.data.snips.Snip.data,2);

if ~snips_compat
    error('Incompatible snips detected in %s\nPlease delete this folder''s content to re-process the data',[handles.blockpath_edit.String filesep 'chandata' filesep]);
end


update_stream(handles);
update_snips(handles);

function handles = extract_snips(handles)

% extract snips using specified parameters
handles.data = TDTthresh(handles.data, handles.store, 'MODE', 'manual', 'THRESH', handles.thresh, 'NPTS', handles.snip_width, 'OVERLAP', 0,'VERBOSE',0);

%TDT thresh simply writes '1' in Snip.chan when only one channel at a time. We want that to reflect the real channel number
handles.data.snips.Snip.chan = handles.data.streams.(handles.store).channel;

function Snip = mergeSnips(s,Snip)
if isempty(Snip)
    Snip = s;
    Snip.data = {Snip.data};
    Snip.sortcode = {Snip.sortcode};
    Snip.ts = {Snip.ts};
else
    if ismember(s.chan, Snip.chan)
        warning('duplicate snip data found for chan %d, skipped merging duplicate',s.chan);
        return;
    end
    
    [Snip.chan, order] = sort([s.chan Snip.chan]);
    
    Snip.data = [{s.data} Snip.data];
    Snip.data = Snip.data(order);
    
    Snip.sortcode = [{s.sortcode} Snip.sortcode];
    Snip.sortcode = Snip.sortcode(order);
    
    Snip.ts = [{s.ts} Snip.ts];
    Snip.ts = Snip.ts(order);
    
    Snip.thresh = [s.thresh Snip.thresh];
    Snip.thresh = Snip.thresh(order);
   
end

function save_chan(handles)
% save snips from current channel
if ~isdir([handles.blockpath_edit.String filesep 'chandata'])
    mkdir([handles.blockpath_edit.String filesep 'chandata']);
end
s = handles.data.snips.Snip;
save([handles.blockpath_edit.String filesep 'chandata' filesep 'ch' num2str(handles.chan) '_snips.mat'],'-struct','s');


%% EDIT BOXES

function thresh_edit_Callback(hObject, eventdata, handles)
handles.thresh = str2num(hObject.String);

update_stream(handles);
update_snips(handles);

% Update handles structure
guidata(hObject, handles);
function thresh_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thresh_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function reject_edit_Callback(hObject, eventdata, handles)
handles.reject = str2num(hObject.String);

update_stream(handles);
update_snips(handles);

% Update handles structure
guidata(hObject, handles);
function reject_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to reject_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pre_snip_edit_Callback(hObject, eventdata, handles)
handles.presnip = str2num(hObject.String);

update_stream(handles);
update_snips(handles);

% Update handles structure
guidata(hObject, handles);
function pre_snip_edit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function post_snip_wind_edit_Callback(hObject, eventdata, handles)
handles.postwind = str2num(hObject.String);

update_stream(handles);
update_snips(handles);

% Update handles structure
guidata(hObject, handles);
function post_snip_wind_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to post_snip_wind_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function post_snip_thresh_edit_Callback(hObject, eventdata, handles)
handles.postsnip = str2num(hObject.String);

update_stream(handles);
update_snips(handles);

% Update handles structure
guidata(hObject, handles);
function post_snip_thresh_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to post_snip_thresh_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function blockpath_edit_Callback(hObject, eventdata, handles)
function blockpath_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to blockpath_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end