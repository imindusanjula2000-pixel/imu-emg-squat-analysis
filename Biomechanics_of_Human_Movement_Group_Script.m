%% ========================================================
%  Biomechanics Group Report - Full Analysis Pipeline
%% ========================================================

clear; clc; close all;

%% ========================================================
%% SECTION 1: Load Data
%% ========================================================

load('data.mat');

fs_imu = 128;   % IMU sampling rate (Hz)
fs_emg = 256;   % EMG sampling rate (Hz)

t_imu = (0:size(thigh_gyro_z, 1)-1) / fs_imu;
t_emg = (0:size(emg, 1)-1) / fs_emg;

%% ========================================================
%% SECTION 2: Data Quality Screening - Plot all 12
%% ========================================================

N_all = 12;

for i = 1:N_all
    figure('Name', sprintf('Participant %d - Gyroscope', i), ...
           'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);

    % Thigh Gyroscope only for quality screening
    subplot(2, 1, 1);
    plot(t_imu, thigh_gyro_z(:, i), 'b', 'LineWidth', 1.2);
    title(sprintf('Participant %d – Thigh Gyro Z', i), 'FontSize', 14);
    ylabel('rad/s', 'FontSize', 12);
    xlim([0 150]);
    grid on;

    % Calf Gyroscope
    subplot(2, 1, 2);
    plot(t_imu, calf_gyro_z(:, i), 'Color', [1 0.5 0], 'LineWidth', 1.2);
    title(sprintf('Participant %d – Calf Gyro Z', i), 'FontSize', 14);
    ylabel('rad/s', 'FontSize', 12);
    xlabel('Time (s)', 'FontSize', 12);
    xlim([0 150]);
    grid on;

    sgtitle(sprintf('Participant %d – Gyroscope Signals (Quality Check)', i), ...
            'FontSize', 15, 'FontWeight', 'bold');
end

%% Exclude participants 5 and 12
exclude = [5, 12];
keep    = setdiff(1:12, exclude);  % [1,2,3,4,6,7,8,9,10,11]

thigh_gyro_z  = thigh_gyro_z(:, keep);
calf_gyro_z   = calf_gyro_z(:, keep);
thigh_accel_z = thigh_accel_z(:, keep);
calf_accel_z  = calf_accel_z(:, keep);
emg           = emg(:, keep);

N = 10;  % remaining participants

fprintf('Excluded participants: %s\n', num2str(exclude));
fprintf('Remaining participants: %s\n', num2str(keep));

%% ========================================================
%% SECTION 3: IMU Comparison - Thigh vs Calf (Gyro + Accel)
%% ========================================================

for i = 1:N

    figure('Name', sprintf('Participant %d - IMU Comparison', keep(i)), ...
           'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.88]);

    % Thigh Gyroscope
    subplot(4, 1, 1);
    plot(t_imu, thigh_gyro_z(:, i), 'b', 'LineWidth', 1.2);
    title('Thigh Gyro Z', 'FontSize', 12);
    ylabel('rad/s', 'FontSize', 11);
    xlim([0 150]); grid on;

    % Calf Gyroscope
    subplot(4, 1, 2);
    plot(t_imu, calf_gyro_z(:, i), 'Color', [1 0.5 0], 'LineWidth', 1.2);
    title('Calf Gyro Z', 'FontSize', 12);
    ylabel('rad/s', 'FontSize', 11);
    xlim([0 150]); grid on;

    % Thigh Accelerometer
    subplot(4, 1, 3);
    plot(t_imu, thigh_accel_z(:, i), 'Color', [0.1 0.7 0.1], 'LineWidth', 1.2);
    title('Thigh Accel Z', 'FontSize', 12);
    ylabel('m/s²', 'FontSize', 11);
    xlim([0 150]); grid on;

    % Calf Accelerometer
    subplot(4, 1, 4);
    plot(t_imu, calf_accel_z(:, i), 'Color', [0.7 0 0.7], 'LineWidth', 1.2);
    title('Calf Accel Z', 'FontSize', 12);
    ylabel('m/s²', 'FontSize', 11);
    xlabel('Time (s)', 'FontSize', 11);
    xlim([0 150]); grid on;

    sgtitle(sprintf('Participant %d – Thigh & Calf: Gyro and Accel', keep(i)), ...
            'FontSize', 15, 'FontWeight', 'bold');
end

%% ========================================================
%% ========================================================
%% ========================================================
%% SECTION 4: Gyroscope Peak Detection
%% ========================================================

peak_vel_slow = zeros(1, N);
peak_vel_fast = zeros(1, N);
rep_dur_slow  = zeros(1, N);
rep_dur_fast  = zeros(1, N);

for i = 1:N

    % --- Find peaks: Thigh ---
    [pk_thigh, locs_thigh] = findpeaks(thigh_gyro_z(:, i), ...
        'MinPeakHeight', 40, 'MinPeakDistance', 200);

    % --- Find peaks: Calf ---
    [pk_calf, locs_calf] = findpeaks(calf_gyro_z(:, i), ...
        'MinPeakHeight', 16, 'MinPeakDistance', 200);

    % --- Separate slow and fast peaks using time windows ---
    slow_mask_t = t_imu(locs_thigh) >= 40  & t_imu(locs_thigh) <= 80;
    fast_mask_t = t_imu(locs_thigh) >= 95  & t_imu(locs_thigh) <= 125; % tightened end to 125s

    pk_slow   = pk_thigh(slow_mask_t);
    pk_fast   = pk_thigh(fast_mask_t);
    locs_slow = locs_thigh(slow_mask_t);
    locs_fast = locs_thigh(fast_mask_t);

    % --- Cap at 5 peaks per condition ---
    if length(pk_slow) > 5
        pk_slow   = pk_slow(1:5);
        locs_slow = locs_slow(1:5);
    end
    if length(pk_fast) > 5
        pk_fast   = pk_fast(1:5);
        locs_fast = locs_fast(1:5);
    end

    % --- Additional protection: remove outlier durations ---
    % If any inter-peak interval > 15s it is likely an artefact, remove it
    if length(locs_slow) > 1
        diffs_slow = diff(locs_slow) / fs_imu;
        valid_slow = diffs_slow < 15;
        if any(~valid_slow)
            locs_slow = locs_slow([true; valid_slow(:)]);
            pk_slow   = pk_slow([true; valid_slow(:)]);
        end
        rep_dur_slow(i) = mean(diff(locs_slow)) / fs_imu;
    end
    if length(locs_fast) > 1
        diffs_fast = diff(locs_fast) / fs_imu;
        valid_fast = diffs_fast < 15;
        if any(~valid_fast)
            locs_fast = locs_fast([true; valid_fast(:)]);
            pk_fast   = pk_fast([true; valid_fast(:)]);
        end
        rep_dur_fast(i) = mean(diff(locs_fast)) / fs_imu;
    end

    % --- Store peak velocity metrics ---
    if ~isempty(pk_slow)
        peak_vel_slow(i) = mean(pk_slow);
    end
    if ~isempty(pk_fast)
        peak_vel_fast(i) = mean(pk_fast);
    end

    % --- Print verification ---
    fprintf('P%d | Slow: %d peaks  dur=%.2fs | Fast: %d peaks  dur=%.2fs\n', ...
        keep(i), length(pk_slow), rep_dur_slow(i), ...
                 length(pk_fast), rep_dur_fast(i));

    % --- Plot peak detection figure ---
    figure('Name', sprintf('Participant %d - Peak Detection', keep(i)), ...
           'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);

    % Thigh subplot
    subplot(2, 1, 1);
    plot(t_imu, thigh_gyro_z(:, i), 'b', 'LineWidth', 1.2); hold on;
    plot(t_imu(locs_thigh), pk_thigh, 'rv', ...
        'MarkerFaceColor', 'r', 'MarkerSize', 8);
    plot(t_imu(locs_slow), pk_slow, 'gv', ...
        'MarkerFaceColor', 'g', 'MarkerSize', 10);
    plot(t_imu(locs_fast), pk_fast, 'yv', ...
        'MarkerFaceColor', 'y', 'MarkerSize', 10);
    xlabel('Time (s)', 'FontSize', 11);
    ylabel('Angular Velocity (rad/s)', 'FontSize', 11);
    title(sprintf('Thigh Gyro Z – Total: %d  |  Slow (green): %d  |  Fast (yellow): %d', ...
        length(pk_thigh), length(pk_slow), length(pk_fast)), 'FontSize', 12);
    xlim([0 150]); grid on;
    legend('Thigh Gyro', 'All Peaks', 'Slow Peaks', 'Fast Peaks', 'Location', 'best');

    % Calf subplot
    subplot(2, 1, 2);
    plot(t_imu, calf_gyro_z(:, i), 'Color', [1 0.5 0], 'LineWidth', 1.2); hold on;
    plot(t_imu(locs_calf), pk_calf, 'rv', ...
        'MarkerFaceColor', 'r', 'MarkerSize', 8);
    xlabel('Time (s)', 'FontSize', 11);
    ylabel('Angular Velocity (rad/s)', 'FontSize', 11);
    title(sprintf('Calf Gyro Z – Detected Peaks: %d', length(pk_calf)), 'FontSize', 12);
    xlim([0 150]); grid on;
    legend('Calf Gyro', 'Peaks', 'Location', 'best');

    sgtitle(sprintf('Participant %d – Gyroscope Peak Detection', keep(i)), ...
            'FontSize', 15, 'FontWeight', 'bold');
end
%% ========================================================
%% SECTION 5: EMG Analysis
%% ========================================================

t_emg = (0:size(emg, 1)-1) / fs_emg;

% Rectify and envelope
emg_rectify  = abs(emg);
emg_envelope = movmean(emg_rectify, 100);

% Storage arrays for EMG metrics
rms_slow_all  = zeros(1, N);
rms_fast_all  = zeros(1, N);
iemg_slow_all = zeros(1, N);
iemg_fast_all = zeros(1, N);

% Time windows for slow and fast squat periods
slow_start = 40;  slow_end = 75;
fast_start = 100; fast_end = 120;

for i = 1:N

    emg_raw = emg(:, i);
    emg_rec = emg_rectify(:, i);
    emg_env = emg_envelope(:, i);

    % --- Plot Raw, Rectified, Envelope together ---
    figure('Name', sprintf('Participant %d - EMG Processing', keep(i)), ...
           'Units', 'normalized', 'Position', [0.05 0.05 0.85 0.80]);

    subplot(3, 1, 1);
    plot(t_emg, emg_raw, 'b', 'LineWidth', 0.8);
    title('Raw EMG', 'FontSize', 12);
    ylabel('mV', 'FontSize', 11);
    xlim([0 150]); grid on;

    subplot(3, 1, 2);
    plot(t_emg, emg_rec, 'r', 'LineWidth', 0.8);
    title('Rectified EMG', 'FontSize', 12);
    ylabel('mV', 'FontSize', 11);
    xlim([0 150]); grid on;

    subplot(3, 1, 3);
    plot(t_emg, emg_env, 'y', 'LineWidth', 1.2);
    title('EMG Envelope', 'FontSize', 12);
    ylabel('mV', 'FontSize', 11);
    xlabel('Time (s)', 'FontSize', 11);
    xlim([0 150]); grid on;

    sgtitle(sprintf('Participant %d – EMG Processing', keep(i)), ...
            'FontSize', 15, 'FontWeight', 'bold');

    % --- Calculate RMS and iEMG for slow and fast periods ---
    emg_rectified = abs(emg(:, i));

    slow_seg = emg_rectified((slow_start*fs_emg):(slow_end*fs_emg));
    fast_seg = emg_rectified((fast_start*fs_emg):(fast_end*fs_emg));

    rms_slow_all(i)  = sqrt(mean(slow_seg.^2));
    rms_fast_all(i)  = sqrt(mean(fast_seg.^2));
    iemg_slow_all(i) = sum(slow_seg) * (1/fs_emg);
    iemg_fast_all(i) = sum(fast_seg) * (1/fs_emg);

    fprintf('Participant %d | SLOW: RMS=%.4f  iEMG=%.4f | FAST: RMS=%.4f  iEMG=%.4f\n', ...
            keep(i), rms_slow_all(i), iemg_slow_all(i), rms_fast_all(i), iemg_fast_all(i));
end

%% ========================================================
%% SECTION 6: Results - Table + Boxplots
%% ========================================================

%% --- 6.1 Print Results Table to Console ---
fprintf('\n============================================================\n');
fprintf('GROUP RESULTS TABLE\n');
fprintf('============================================================\n');
fprintf('%-12s | %-10s %-10s %-10s %-10s | %-10s %-10s %-10s %-10s\n', ...
    'Participant', ...
    'PkVel_Sl', 'RepDur_Sl', 'RMS_Sl', 'iEMG_Sl', ...
    'PkVel_Fs', 'RepDur_Fs', 'RMS_Fs', 'iEMG_Fs');
fprintf('%s\n', repmat('-', 1, 100));

for i = 1:N
    fprintf('%-12d | %-10.2f %-10.2f %-10.4f %-10.4f | %-10.2f %-10.2f %-10.4f %-10.4f\n', ...
        keep(i), ...
        peak_vel_slow(i), rep_dur_slow(i), rms_slow_all(i), iemg_slow_all(i), ...
        peak_vel_fast(i), rep_dur_fast(i), rms_fast_all(i), iemg_fast_all(i));
end

fprintf('%s\n', repmat('-', 1, 100));
fprintf('%-12s | %-10.2f %-10.2f %-10.4f %-10.4f | %-10.2f %-10.2f %-10.4f %-10.4f\n', ...
    'Mean', ...
    mean(peak_vel_slow), mean(rep_dur_slow), mean(rms_slow_all), mean(iemg_slow_all), ...
    mean(peak_vel_fast), mean(rep_dur_fast), mean(rms_fast_all), mean(iemg_fast_all));
fprintf('%-12s | %-10.2f %-10.2f %-10.4f %-10.4f | %-10.2f %-10.2f %-10.4f %-10.4f\n', ...
    'SD', ...
    std(peak_vel_slow), std(rep_dur_slow), std(rms_slow_all), std(iemg_slow_all), ...
    std(peak_vel_fast), std(rep_dur_fast), std(rms_fast_all), std(iemg_fast_all));
fprintf('============================================================\n');

%% --- 6.2 Boxplots ---
figure('Name', 'Boxplots - Slow vs Fast Squats', ...
       'Units', 'normalized', 'Position', [0.02 0.02 0.96 0.92]);

slow_color = [0.2 0.4 0.8];
fast_color = [0.8 0.2 0.2];

% 1. Peak Angular Velocity
subplot(2, 2, 1);
boxchart([ones(N,1); 2*ones(N,1)], [peak_vel_slow'; peak_vel_fast'], ...
    'BoxFaceColor', slow_color);
hold on;
boxchart([ones(N,1); 2*ones(N,1)], [peak_vel_slow'; peak_vel_fast']);
% Cleaner approach:
b1 = boxplot([peak_vel_slow', peak_vel_fast'], ...
    'Labels', {'Slow', 'Fast'}, ...
    'Colors', [slow_color; fast_color], ...
    'Width', 0.5);
set(b1, 'LineWidth', 1.5);
ylabel('rad/s', 'FontSize', 13);
xlabel('Squat Condition', 'FontSize', 13);
title('Peak Angular Velocity', 'FontSize', 14, 'FontWeight', 'bold');
grid on;

% 2. Repetition Duration
subplot(2, 2, 2);
b2 = boxplot([rep_dur_slow', rep_dur_fast'], ...
    'Labels', {'Slow', 'Fast'}, ...
    'Colors', [slow_color; fast_color], ...
    'Width', 0.5);
set(b2, 'LineWidth', 1.5);
ylabel('Seconds (s)', 'FontSize', 13);
xlabel('Squat Condition', 'FontSize', 13);
title('Repetition Duration', 'FontSize', 14, 'FontWeight', 'bold');
grid on;

% 3. RMS
subplot(2, 2, 3);
b3 = boxplot([rms_slow_all', rms_fast_all'], ...
    'Labels', {'Slow', 'Fast'}, ...
    'Colors', [slow_color; fast_color], ...
    'Width', 0.5);
set(b3, 'LineWidth', 1.5);
ylabel('mV', 'FontSize', 13);
xlabel('Squat Condition', 'FontSize', 13);
title('EMG RMS', 'FontSize', 14, 'FontWeight', 'bold');
grid on;

% 4. iEMG
subplot(2, 2, 4);
b4 = boxplot([iemg_slow_all', iemg_fast_all'], ...
    'Labels', {'Slow', 'Fast'}, ...
    'Colors', [slow_color; fast_color], ...
    'Width', 0.5);
set(b4, 'LineWidth', 1.5);
ylabel('mV·s', 'FontSize', 13);
xlabel('Squat Condition', 'FontSize', 13);
title('iEMG', 'FontSize', 14, 'FontWeight', 'bold');
grid on;

sgtitle('Group Results – Slow vs Fast Squats (N=10)', ...
        'FontSize', 16, 'FontWeight', 'bold');

%% --- 6.3 Summary Figure ---
figure('Name', 'Summary Figure', ...
       'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);

% Peak angular velocity per participant
subplot(2, 2, 1);
bar_data = [peak_vel_slow', peak_vel_fast'];
b = bar(bar_data);
b(1).FaceColor = slow_color;
b(2).FaceColor = fast_color;
set(gca, 'XTickLabel', keep);
xlabel('Participant', 'FontSize', 11);
ylabel('rad/s', 'FontSize', 11);
title('Peak Angular Velocity per Participant', 'FontSize', 12, 'FontWeight', 'bold');
legend('Slow', 'Fast', 'Location', 'best');
grid on;

% Repetition duration per participant
subplot(2, 2, 2);
bar_data2 = [rep_dur_slow', rep_dur_fast'];
b2 = bar(bar_data2);
b2(1).FaceColor = slow_color;
b2(2).FaceColor = fast_color;
set(gca, 'XTickLabel', keep);
xlabel('Participant', 'FontSize', 11);
ylabel('Seconds (s)', 'FontSize', 11);
title('Repetition Duration per Participant', 'FontSize', 12, 'FontWeight', 'bold');
legend('Slow', 'Fast', 'Location', 'best');
grid on;

% RMS per participant
subplot(2, 2, 3);
bar_data3 = [rms_slow_all', rms_fast_all'];
b3 = bar(bar_data3);
b3(1).FaceColor = slow_color;
b3(2).FaceColor = fast_color;
set(gca, 'XTickLabel', keep);
xlabel('Participant', 'FontSize', 11);
ylabel('mV', 'FontSize', 11);
title('EMG RMS per Participant', 'FontSize', 12, 'FontWeight', 'bold');
legend('Slow', 'Fast', 'Location', 'best');
grid on;

% iEMG per participant
subplot(2, 2, 4);
bar_data4 = [iemg_slow_all', iemg_fast_all'];
b4 = bar(bar_data4);
b4(1).FaceColor = slow_color;
b4(2).FaceColor = fast_color;
set(gca, 'XTickLabel', keep);
xlabel('Participant', 'FontSize', 11);
ylabel('mV·s', 'FontSize', 11);
title('iEMG per Participant', 'FontSize', 12, 'FontWeight', 'bold');
legend('Slow', 'Fast', 'Location', 'best');
grid on;

sgtitle('Summary – All Variables per Participant (N=10)', ...
        'FontSize', 15, 'FontWeight', 'bold');