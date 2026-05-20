clc;
clear;

% -------------------------------
% 1. SET IMAGE FOLDER PATH
% -------------------------------
folderPath = "data/images";   % CHANGE THIS
saveFolderPath = "data/sheets/";
files = dir(fullfile(folderPath, "*.png"));
% -------------------------------
% 2. INITIALIZE STORAGE
% -------------------------------
results = [];

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

        % -------------------------------
        % 3.6 STORE RESULTS
        % -------------------------------
        results = [results; {files(i).name, kV, mAs, SNR, CNR, contrast, noise, sharpness}];

    catch
        fprintf("Error processing: %s\n", files(i).name);
    end
end

% -------------------------------
% 4. CONVERT TO TABLE
% -------------------------------
resultsTable = cell2table(results, ...
    'VariableNames', {'Filename','kV','mAs','SNR','CNR','Contrast','Noise','Sharpness'});

% -------------------------------
% 5. SAVE TO CSV
% -------------------------------
outputFile = fullfile(saveFolderPath, "image_quality_results.csv");
writetable(resultsTable, outputFile);

disp("Processing complete!");
disp("Results saved to: " + outputFile);