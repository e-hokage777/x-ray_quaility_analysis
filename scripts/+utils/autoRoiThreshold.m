function [lungROI, boneROI, airROI] = autoRoiThreshold(I)

I = mat2gray(I);

% Segment using Otsu thresholding
level = graythresh(I);
BW = imbinarize(I, level);

% Air = very dark pixels
airMask = I < 0.2;

% Bone = very bright pixels
boneMask = I > 0.7;

% Soft tissue (lungs) = mid range
lungMask = I >= 0.3 & I <= 0.6;

% Extract largest connected region (cleaning)
airMask = bwareafilt(airMask, 1);
boneMask = bwareafilt(boneMask, 1);
lungMask = bwareafilt(lungMask, 1);

% Convert masks to ROI pixel values
airROI  = I(airMask);
boneROI = I(boneMask);
lungROI = I(lungMask);

end