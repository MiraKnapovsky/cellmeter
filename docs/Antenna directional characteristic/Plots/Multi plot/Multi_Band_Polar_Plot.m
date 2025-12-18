%% MULTI-FREQUENCY POLAR PLOTTER
% Vykreslí všechny frekvence pro danou anténu do jednoho polárního grafu.
% Inspirace: "XZ PLANE" overlay plot.

clear; clc; close all;

% Načtení seznamu CSV souborů (jen data)
files = dir('*.csv');
validFiles = {};
for i = 1:numel(files)
    % Ignoruj configy a statistiky
    if ~contains(files(i).name, {'minY', 'stats', 'summary'})
        validFiles{end+1} = files(i).name; %#ok<SAGROW>
    end
end

if isempty(validFiles)
    error('Žádná datová CSV nenalezena.');
end

% === 1. PARSE A TŘÍDĚNÍ ===
% Potřebujeme tabulku: [Filename, AntennaName, FrequencyValue]
fileList = table();

for i = 1:numel(validFiles)
    fname = validFiles{i};
    
    % Regex na vytažení jména antény (např. "ant1")
    antMatch = regexp(fname, '(ant\d+)', 'tokens');
    if isempty(antMatch), continue; end
    antName = antMatch{1}{1};
    
    % Regex na vytažení frekvence (např. "0.8" z "0.8GHz")
    freqMatch = regexp(fname, '([\d\.]+)GHz', 'tokens');
    if isempty(freqMatch)
        freqVal = 0; % Fallback
    else
        freqVal = str2double(freqMatch{1}{1});
    end
    
    fileList = [fileList; table({fname}, {antName}, freqVal, ...
        'VariableNames', {'File', 'Antenna', 'Freq'})]; %#ok<AGROW>
end

% Získej unikátní antény
uniqueAntennas = unique(fileList.Antenna);

fprintf('Nalezeny antény: %s\n', strjoin(uniqueAntennas, ', '));

% === 2. VYKRESLOVÁNÍ ===

for i = 1:numel(uniqueAntennas)
    thisAnt = uniqueAntennas{i};
    
    % Vyfiltruj soubory jen pro tuto anténu
    rows = strcmp(fileList.Antenna, thisAnt);
    subData = fileList(rows, :);
    
    % SEŘAĎ PODLE FREKVENCE (Důležité pro hezkou legendu!)
    [~, sortIdx] = sort(subData.Freq);
    subData = subData(sortIdx, :);
    
    % Vytvoř okno: Vlevo Vertikální, Vpravo Horizontální
    f = figure('Name', ['Multi-Freq: ' thisAnt], 'Visible', 'off', ...
               'Position', [100 100 1200 600]);
    t = tiledlayout(1, 2, 'TileSpacing', 'compact');
    title(t, sprintf('Multi-Frequency Analysis: %s', thisAnt), 'FontSize', 16);
    
    % Připrav barvy (od modré do červené podle počtu frekvencí)
    nFreqs = height(subData);
    colors = turbo(nFreqs); % 'turbo' nebo 'jet' dělá hezkou duhu
    
    legends = cell(nFreqs, 1);
    
    % --- LOOP PRO FREKVENCE ---
    % Musíme si pamatovat handle grafů pro legendu
    axV = nexttile; polaraxes(axV); hold on; title('E-Plane (Vertical)');
    axH = nexttile; polaraxes(axH); hold on; title('H-Plane (Horizontal)');
    
    plotsV = [];
    plotsH = [];
    
    for k = 1:nFreqs
        fname = subData.File{k};
        freqLabel = sprintf('%.2f GHz', subData.Freq(k));
        legends{k} = freqLabel;
        
        T = readtable(fname);
        az_rad = deg2rad(T.Azimuth);
        
        % Vykresli do levého (Vert)
        axes(axV);
        p1 = polarplot(az_rad, T.Vertical_dB, 'Color', colors(k,:), 'LineWidth', 1.5);
        plotsV = [plotsV; p1]; %#ok<AGROW>
        
        % Vykresli do pravého (Horiz)
        axes(axH);
        p2 = polarplot(az_rad, T.Horizontal_dB, 'Color', colors(k,:), 'LineWidth', 1.5);
        plotsH = [plotsH; p2]; %#ok<AGROW>
    end
    
    % Nastav limity a legendu
    axes(axV); 
    rlim([-40 5]); % Pevný rozsah, aby to neškubalo
    lgd = legend(plotsV, legends, 'Location', 'eastoutside');
    title(lgd, 'Frequency');
    
    axes(axH); 
    rlim([-40 5]);
    % Legenda stačí jen u jednoho grafu, ať to nezabírá místo
    
    % Uložení
    outName = ['MULTI_PLOT_' thisAnt '.png'];
    exportgraphics(f, outName, 'Resolution', 150);
    close(f);
    
    fprintf('  -> Uloženo: %s (%d frekvencí)\n', outName, nFreqs);
end

fprintf('Hotovo. Všechny multiband grafy jsou vygenerované.\n');