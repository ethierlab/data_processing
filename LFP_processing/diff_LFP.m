function dlfp = diff_LFP(LFP,varargin)
%
% Usage: dlfp = diff_LFP(LFP,[mapping])
% 
% this function calculates differential LFP values based on the 'mapping' optional input argument
%   by default, it uses TDT electrodes channels next to each other, in different 'columns')
%   e.g. in a 2x8, 16 ch array, 'mapping' will be like this:
%
%    ch1+   ch1-    => i.e. LFPch1 = TDTelec10- TDTelec1
%    ch2+   ch2-    => i.e. LFPch1 = TDTelec12- TDTelec3
%    ch3+   ch3-    => i.e. LFPch1 = TDTelec14- TDTelec5
%    ch4+   ch4-    => i.e. LFPch1 = TDTelec16- TDTelec7
%    ch5+   ch5-    => i.e. LFPch1 = TDTelec9 - TDTelec2
%    ch6+   ch6-    => i.e. LFPch1 = TDTelec11- TDTelec4
%    ch7+   ch7-    => i.e. LFPch1 = TDTelec13- TDTelec6
%    ch8+   ch8-    => i.e. LFPch1 = TDTelec15- TDTelec8
%
%   see http://www.tdt.com/files/manuals/Sys3Manual/ZIFArrays.pdf for corresponding electrode mapping.
%   for a 4x8, 32ch array, the organization is similar, with ch 9 to 16 on the next two columns.
%
%   LFP    : num_LFPs x num_trials cell array of LFP data
%
%   optional params:
%       mapping : alternate mapping can be obtained by providing an array for this optional argument.
%                 'mapping' should have two columns with ch numbers to differentiate, and num_LFPs/2 rows.
%
%%%% EthierLab 2018 %%(CE-july2018)

default_mapping = [...
    1   10  ;...
    3   12  ;...
    5   14  ;...
    7   16  ;...
    2   9   ;...
    4   11  ;...
    6   13  ;...
    8   15  ;...
    26  17  ;...
    28  19  ;...
    30  21  ;...
    32  23  ;...
    25  18  ;...
    27  20  ;...
    29  22  ;...
    31  24  ];


if nargin>1
    mapping = varargin{1};
    if isempty(mapping)
        mapping = default_mapping(1:size(LFP,1)/2,:);
    end
else
    mapping = default_mapping(1:size(LFP,1)/2,:);
end

num_ch      = size(mapping,1);
num_trials  = size(LFP,2);
dlfp        = cell(num_ch,num_trials);

for c = 1:num_ch
    for t = 1:num_trials
        dlfp{c,t} = LFP{mapping(c,2),t}-LFP{mapping(c,1),t};
    end
end
