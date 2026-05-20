clc;
clear;

% -------------------------------
% 1. SET IMAGE FOLDER PATH
% -------------------------------
scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptFolder);
folderPath = fullfile(projectRoot, "data", "images");   % CHANGE THIS
saveFolderPath = fullfile(projectRoot, "data", "sheets");
if ~exist(saveFolderPath, 'dir')
    mkdir(saveFolderPath);
end
files = dir(fullfile(folderPath, "*.png"));
% -------------------------------
% 2. INITIALIZE STORAGE
% -------------------------------
results = cell(0, 14);

% -------------------------------
% 3. LOOP THROUGH ALL IMAGES
% -------------------------------
for i = 1:length(files) % change to length(files) later
    
    filename = fullfile(folderPath, files(i).name);

    
    try
        % -------------------------------
        % 3.1 READ IMAGE + METADATA
        % -------------------------------
        I = im2double(imread(filename));

        % Convert to grayscale if RGB
        if size(I,3) == 3
            I = rgb2gray(I);
        end

        % -------------------------------
        % 3.2 EXTRACT EXPOSURE PARAMETERS
        % -------------------------------
        [age, kV, mAs] = utils.extractImageInfo(files(i).name);


        % -------------------------------
        % 3.3 RESIZE (STANDARDIZE)
        % -------------------------------
        I = imresize(I, [1024 1024]);

        % -------------------------------
        % 3.4 DEFINE ROIs (EDIT FOR YOUR DATASET)
        % -------------------------------
        % lungROI = I(400:600, 400:600); % TODO: Remove this section
        % mediROI = I(650:850, 650:850);
        % airROI  = I(50:150, 50:150);
        [lungROI, boneROI, airROI] = utils.autoRoiThreshold(I);

        % -------------------------------
        % 3.5 COMPUTE METRICS
        % -------------------------------

        % Noise
        noise = std(airROI(:));

        % SNR
        SNR = mean(lungROI(:)) / noise;

        % CNR
        CNR = abs(mean(lungROI(:)) - mean(boneROI(:))) / noise;

        % Contrast
        contrast = abs(mean(lungROI(:)) - mean(boneROI(:)));

        % Sharpness (gradient-based)
        [Gx, Gy] = imgradientxy(I);
        sharpness = mean(sqrt(Gx.^2 + Gy.^2), 'all');

        % Acceptability checks
        snrAcceptable = SNR >= 20 && SNR <= 80;
        cnrAcceptable = CNR >= 4 && CNR <= 10;
        noiseAcceptable = noise < 0.10;
        sharpnessAcceptable = sharpness >= 3 && sharpness <= 7;
        contrastAcceptable = contrast >= 0.3 && contrast <= 0.7;
        overallAcceptable = snrAcceptable && cnrAcceptable && noiseAcceptable && ...
            sharpnessAcceptable && contrastAcceptable;

        % -------------------------------
        % 3.6 STORE RESULTS
        % -------------------------------
        results = [results; {files(i).name, kV, mAs, SNR, CNR, contrast, noise, sharpness, ...
            snrAcceptable, cnrAcceptable, noiseAcceptable, sharpnessAcceptable, ...
            contrastAcceptable, overallAcceptable}];

    catch ME
        fprintf("Error processing: %s\n%s\n", files(i).name, ME.message);
    end
end

% -------------------------------
% 4. CONVERT TO TABLE
% -------------------------------
resultsTable = cell2table(results, ...
    'VariableNames', {'Filename','kV','mAs','SNR','CNR','Contrast','Noise','Sharpness', ...
    'SNRAcceptable','CNRAcceptable','NoiseAcceptable','SharpnessAcceptable', ...
    'ContrastAcceptable','OverallAcceptable'});

% -------------------------------
% 5. SAVE TO CSV
% -------------------------------
outputFile = fullfile(saveFolderPath, "image_quality_results.csv");
writetable(resultsTable, outputFile);

disp("Processing complete!");
disp("Results saved to: " + outputFile);
