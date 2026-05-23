function resultsTable = processImageDirectory(folderPath, outputFile)
%PROCESSIMAGEDIRECTORY Compute image quality metrics for all PNG images in a folder.

files = dir(fullfile(folderPath, "*.png"));

% -------------------------------
% INITIALIZE STORAGE
% -------------------------------
results = cell(0, 15);

% -------------------------------
% LOOP THROUGH ALL IMAGES
% -------------------------------
for i = 1:length(files)
    filename = fullfile(folderPath, files(i).name);
    
    try
        % -------------------------------
        % READ IMAGE + METADATA
        % -------------------------------
        I = im2double(imread(filename));
        
        % Convert to grayscale if RGB
        if size(I, 3) == 3
            I = rgb2gray(I);
        end
        
        % -------------------------------
        % EXTRACT EXPOSURE PARAMETERS
        % -------------------------------
        [~, kV, mAs] = utils.extractImageInfo(files(i).name);
        
        % -------------------------------
        % RESIZE (STANDARDIZE)
        % -------------------------------
        I = imresize(I, [1024 1024]);
        
        % -------------------------------
        % DEFINE ROIs
        % -------------------------------
        [lungROI, boneROI, airROI] = utils.autoRoiThreshold(I);
        
        % -------------------------------
        % COMPUTE METRICS
        % -------------------------------
        noise = std(airROI(:));
        SNR = mean(lungROI(:)) / noise;
        CNR = abs(mean(lungROI(:)) - mean(boneROI(:))) / noise;
        contrast = abs(mean(lungROI(:)) - mean(boneROI(:)));
        
        [Gx, Gy] = imgradientxy(I);
        sharpness = mean(sqrt(Gx.^2 + Gy.^2), 'all');
        
        % -------------------------------
        % ACCEPTABILITY CHECKS
        % -------------------------------
        snrAcceptable = SNR >= 20 && SNR <= 80;
        cnrAcceptable = CNR >= 4 && CNR <= 10;
        noiseAcceptable = noise < 0.10;
        sharpnessAcceptable = sharpness >= 3 && sharpness <= 7;
        contrastAcceptable = contrast >= 0.3 && contrast <= 0.7;
        overallAcceptable = noiseAcceptable && sharpnessAcceptable && contrastAcceptable;

        % -------------------------------
        % SCORE
        % -------------------------------
        score = 0.4 * contrastAcceptable + 0.25 * sharpnessAcceptable + ...
            0.2 * noiseAcceptable;
        
        % -------------------------------
        % STORE RESULTS
        % -------------------------------
        results = [results; {files(i).name, kV, mAs, SNR, CNR, contrast, noise, sharpness, ...
            snrAcceptable, cnrAcceptable, noiseAcceptable, sharpnessAcceptable, ...
            contrastAcceptable, overallAcceptable, score}];
        
    catch ME
        fprintf("Error processing: %s\n%s\n", files(i).name, ME.message);
    end
end

% -------------------------------
% CONVERT TO TABLE
% -------------------------------
resultsTable = cell2table(results, ...
    'VariableNames', {'Filename', 'kV', 'mAs', 'SNR', 'CNR', 'Contrast', 'Noise', 'Sharpness', ...
    'SNRAcceptable', 'CNRAcceptable', 'NoiseAcceptable', 'SharpnessAcceptable', ...
    'ContrastAcceptable', 'OverallAcceptable', 'Score'});

% -------------------------------
% SAVE TO CSV
% -------------------------------
writetable(resultsTable, outputFile);

end
