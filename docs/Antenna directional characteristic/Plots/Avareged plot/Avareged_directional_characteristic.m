%% Initialization and Setup
clear; clc; close all;

antennas = {'ant1', 'ant2', 'ant3', 'ant4'};
files = dir('*.csv'); % Load all CSV files in the current folder

% Parameters for smoothing and noise floor
smooth_factor = 10; % Window size for moving average (higher = smoother)
floor_db = -25;     % Minimum dB threshold for better visualization (noise floor)

for a = 1:length(antennas)
    current_ant = antennas{a};
    
    % Search for files related to the specific antenna
    ant_files = files(contains({files.name}, current_ant));
    
    if isempty(ant_files)
        fprintf('No files found for %s.\n', current_ant);
        continue;
    end
    
    sum_vert = 0;
    sum_horiz = 0;
    num_freqs = length(ant_files);
    azimuth = [];

    % 1. Data Loading and Accumulation
    for f = 1:num_freqs
        data = readtable(ant_files(f).name);
        
        % Assuming columns: Azimuth, Vertical_dB, Horizontal_dB
        if f == 1
            azimuth = data.Azimuth;
        end
        
        sum_vert = sum_vert + data.Vertical_dB;
        sum_horiz = sum_horiz + data.Horizontal_dB;
    end
    
    % 2. Average Calculation
    avg_vert = sum_vert / num_freqs;
    avg_horiz = sum_horiz / num_freqs;
    
    % 3. Outlier Removal and Smoothing
    % Apply moving average to visualize the trend
    clean_vert = smoothdata(avg_vert, 'movmean', smooth_factor);
    clean_horiz = smoothdata(avg_horiz, 'movmean', smooth_factor);
    
    % Floor clipping (prevents "broken" plots at the center)
    clean_vert(clean_vert < floor_db) = floor_db;
    clean_horiz(clean_horiz < floor_db) = floor_db;

    % 4. Plotting
    figure('Name', ['Average Radiation Pattern: ' current_ant], 'Position', [100, 100, 1000, 450]);
    
    % E-Plane (Vertical)
    subplot(1, 2, 1);
    polarplot(deg2rad(azimuth), clean_vert, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
    title(['E-Plane (Vertical) - ' current_ant]);
    rlim([floor_db 0]); % dB range from noise floor to 0
    thetaticks(0:30:330);
    
    % H-Plane (Horizontal)
    subplot(1, 2, 2);
    polarplot(deg2rad(azimuth), clean_horiz, 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
    title(['H-Plane (Horizontal) - ' current_ant]);
    rlim([floor_db 0]);
    thetaticks(0:30:330);
    
    sgtitle(['Averaged Radiation Pattern: ' current_ant]);
end