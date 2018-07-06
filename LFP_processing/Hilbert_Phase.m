% This function computes the hilbert transform based phase known as 
% hilbert phase for a given discrete time signal and computes the complex 
% valued analytic signal and extracts the argument of the complex time 
% series and limits the value to fundamental interval of 0 to 2*pi.
% =========================================================================
% Input 
% =========================================================================
% Discrete time series LFP data
% =========================================================================
% Output 
% =========================================================================
% Instantaneous hilbert phase as a time series
% =========================================================================
function result = Hilbert_Phase(input)
data = double(input);

%Perform hilbert transform on input data
tdata = hilbert(data);

%Obtain hilbert phase in radians the values ranges from -pi to +pi 
output = atan2(imag(tdata),real(tdata));

% The phase will now range from 0 to 2 pi radians
result = mod(output,2*pi);
end