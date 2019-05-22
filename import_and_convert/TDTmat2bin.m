function raw_spike_data = TDTmat2bin(datafile, varargin)

if ~isstruct(datafile)
    datafile = load(datafile);
end

%scale to uV
raw_spike_data = datafile.streams.spik.data * 1e6;

if nargin>1
    save_path = varargin{1};
else
    save_path = cd;
end

fname = fullfile(save_path,[datafile.info.blockname '.dat']);

fid = fopen(fname,'w');
fwrite(fid, raw_spike_data, 'int16');
fclose(fid);

