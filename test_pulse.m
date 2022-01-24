% load bit file
bit_file = 'CO2_pulse_control.bit';
mex_ok_interface('open')
mex_ok_interface('configure', bit_file)

%% set default levels
mex_ok_interface('swi', 6, 3);
mex_ok_interface('uwi');

%% Set the parameters
% in units of ms

shoot_trig_delay = 0;
trig_pulse_delay = 1;
laser_shutter_delay1 = 10;
laser_shutter_delay2 = 20;
laser_low_time1 = 20;
laser_low_time2 = 30;
laser_width = 40;
end_delay = 1;
mex_ok_interface('swi', 0, shoot_trig_delay*10);
mex_ok_interface('swi', 1, trig_pulse_delay*10);
mex_ok_interface('swi', 2, laser_shutter_delay1*10);
mex_ok_interface('swi', 3, laser_low_time1*10);
mex_ok_interface('swi', 4, laser_width*10);
mex_ok_interface('swi', 5, end_delay*10);
mex_ok_interface('swi', 7, laser_low_time2*10);
mex_ok_interface('swi', 8, laser_shutter_delay2*10);
mex_ok_interface('uwi');

%% activate trigger
mex_ok_interface('ati', 64, 1);

%% activate trigger
mex_ok_interface('ati', 64, 2);

%%
mex_ok_interface('close')
