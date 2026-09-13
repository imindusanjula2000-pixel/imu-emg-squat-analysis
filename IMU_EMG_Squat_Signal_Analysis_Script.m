fs_lmu=128;
%% thigh............................................................................................
thigh = load("Thigh_Group1_Session1_IMU2_Calibrated_SD.mat");

thigh_accel_x = IMU2_Accel_WR_X_CAL;
thigh_accel_y = IMU2_Accel_WR_Y_CAL;
thigh_accel_z = IMU2_Accel_WR_Z_CAL;

thigh_gyro_x = IMU2_Gyro_X_CAL;
thigh_gyro_y = IMU2_Gyro_Y_CAL;
thigh_gyro_z = IMU2_Gyro_Z_CAL;

figure;
subplot(211);
plot(thigh_accel_x);hold on;
plot(thigh_accel_y);hold on;
plot(thigh_accel_z);hold on;

subplot(212);
plot(thigh_gyro_x);hold on;
plot(thigh_gyro_y);hold on;
plot(thigh_gyro_z);hold on;

figure; plot(thigh_gyro_z);
title("Thigh, Find Impact Peaks");

t_imu = (0:length(thigh_gyro_z)-1) / fs_lmu;

[pk, locs] = findpeaks(thigh_gyro_z, 'MinPeakHeight', 40, 'MinPeakDistance', 200);

dlocs= diff(locs);
figure;
plot(thigh_gyro_z); hold on;
plot(locs, pk, 'rv', 'MarkerFaceColor', 'r');
xlabel('Time (s)');
ylabel('Angular Velocity (deg/s)');
title('Thigh, Segmented Gyro Data with Detected Peaks');


thigh_accel_mag = sqrt(thigh_accel_x.^2 + thigh_accel_y.^2 + thigh_accel_z.^2);


figure;
plot(thigh_accel_mag);
title('Tigh, Acceleration Magnitude');
ylabel('m/s^2');
xlabel('Samples');

%%
%Hip

hip = load("hip_Group1_Session1_IMU1_Calibrated_SD.mat");

hip_accel_x = IMU1_Accel_WR_X_CAL;
hip_accel_y = IMU1_Accel_WR_Y_CAL;
hip_accel_z = IMU1_Accel_WR_Z_CAL;

hip_gyro_x = IMU1_Gyro_X_CAL;
hip_gyro_y = IMU1_Gyro_Y_CAL;
hip_gyro_z = IMU1_Gyro_Z_CAL;

h_imu = (0:length(hip_gyro_z)-1) / fs_lmu;
[pk, locs] = findpeaks(hip_gyro_z, 'MinPeakHeight', 20, 'MinPeakDistance', 100);

dhlocs= diff(locs);
figure;
plot(thigh_gyro_z); hold on;
plot(locs, pk, 'rv', 'MarkerFaceColor', 'r');
xlabel('Time (s)');
ylabel('Angular Velocity (deg/s)');
title('Hip, Segmented Gyro Data with Detected Peaks');


hip_accel_mag = sqrt(hip_accel_x.^2 + hip_accel_y.^2 + hip_accel_z.^2);


figure;
plot(thigh_accel_mag);
title('Hip, Acceleration Magnitude');
ylabel('m/s^2');
xlabel('Samples');

%%
%Calf
calf = load("Calf_Group1_Session1_IMU3_Calibrated_SD.mat");

calf_accel_x = IMU3_Accel_WR_X_CAL;
calf_accel_y = IMU3_Accel_WR_Y_CAL;
calf_accel_z = IMU3_Accel_WR_Z_CAL;

calf_gyro_x = IMU3_Gyro_X_CAL;
calf_gyro_y = IMU3_Gyro_Y_CAL;
calf_gyro_z = IMU3_Gyro_Z_CAL;

c_imu = (0:length(calf_gyro_z)-1) / fs_lmu;

[pk, locs] = findpeaks(calf_gyro_z, 'MinPeakHeight', 20, 'MinPeakDistance', 100);

dclocs= diff(locs);
figure;
plot(calf_gyro_z); hold on;
plot(locs, pk, 'rv', 'MarkerFaceColor', 'r');
xlabel('Time (s)');
ylabel('Angular Velocity (deg/s)');
title('Calf, Segmented Gyro Data with Detected Peaks');


calf_accel_mag = sqrt(calf_accel_x.^2 + calf_accel_y.^2 + calf_accel_z.^2);


figure;
plot(calf_accel_mag);
title('Calf, Acceleration Magnitude');
ylabel('m/s^2');
xlabel('Samples');

%%
%EMG 
fs_emg= 256;
emg = load('EMG_Group1_Session1_EMG_Calibrated_SD.mat');
emg = emg.EMG_EMG_CH1_24BIT_CAL;
emg = emg(296251:315236);

figure;
plot(emg);
title('Raw EMG Signal');
xlabel('Samples');
ylabel('Amplitude');

emg_filt = bandpass(emg, [20 100], fs_emg);


figure;
plot(emg_filt);
title('Bandpass Filtered EMG (20–100 Hz)');
xlabel('Samples');
ylabel('Amplitude');



emg_rect = abs(emg_filt);


figure;
plot(emg_rect);
title('Rectified EMG Signal');
xlabel('Samples');
ylabel('Amplitude');

rms_signal = sqrt(movmean(emg_rect.^2, 100));

figure;
plot(rms_signal);
title('RMS of EMG Signal');
xlabel('Samples');
ylabel('Amplitude');

t_emg = 1/fs_emg: 1/fs_emg:100;

emg_env = envelope(emg_filt, 200, 'rms');

figure;
plot(emg_env);
title('EMG Envelope (RMS Envelope)');
xlabel('Samples');
ylabel('Amplitude');
%%