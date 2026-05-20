clc;
clear;

% -------------------------------
% 1. SET FOLDER PATHS
% -------------------------------
scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptFolder);
imagesRootPath = fullfile(projectRoot, "data", "images");
saveFolderPath = fullfile(projectRoot, "data", "sheets");

if ~exist(saveFolderPath, 'dir')
    mkdir(saveFolderPath);
end

% -------------------------------
% 2. PROCESS EACH IMAGE SUBFOLDER
% -------------------------------
imageSubfolders = dir(imagesRootPath);
imageSubfolders = imageSubfolders([imageSubfolders.isdir]);
imageSubfolders = imageSubfolders(~ismember({imageSubfolders.name}, {'.', '..'}));

if isempty(imageSubfolders)
    fprintf("No image subfolders found in: %s\n", imagesRootPath);
end

for i = 1:length(imageSubfolders)
    subfolderName = imageSubfolders(i).name;
    inputFolder = fullfile(imagesRootPath, subfolderName);
    outputFile = fullfile(saveFolderPath, subfolderName + ".csv");

    fprintf("Processing folder: %s\n", inputFolder);
    utils.processImageDirectory(inputFolder, outputFile);
    fprintf("Results saved to: %s\n", outputFile);
end

disp("Processing complete!");
