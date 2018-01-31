function sys_time_delay = pz5_delay(pz5_rate,gizmo_level)
% This function is a look-up table, built from tdt documentation (http://www.tdt.com/files/fastfacts/IODelays.pdf)
%  It outputs the time delay of the PZ5 recording, based on its sampling frequency and gizmo level
%  This code assumes delays were not corrected using Gizmos and delay components provided in RPvdsEx%  
%  and that the RZ2 is running at 25 kHz.


% table of SF and Delays:
sf_delay = [25     22;
            12     40;
             6     76;
             3    141;
             1.5  270;
             0.75 543];
         
         
num_samples = sf_delay(sf_delay(:,1)==pz5_rate,2);

if isempty(num_samples)
    error('pz5_sample_delay: could not find the specified sampling frequency (%g kHz) in the lookup table',pz5_rate);
end

% and additional delay of 2 samples per gizmo level in synapse:
num_samples = num_samples + 2*gizmo_level;

sys_time_delay = num_samples/25000;