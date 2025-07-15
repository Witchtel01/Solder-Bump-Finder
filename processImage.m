function [centers, radii, grayImage] = processImage(fullFilePath)
    % This function performs the non-interactive image processing.
    
    orig = imread(fullFilePath);
    grayImage = orig(:, :, 1);
    
    % Image preprocessing
    grayImage(grayImage > (max(max(grayImage)) - min(min(grayImage)))/2 + min(min(grayImage)) - 40) = 255;
    
    radiusRange = [200 500];
    [centers, radii] = imfindcircles(grayImage, radiusRange, 'ObjectPolarity', 'dark', 'Sensitivity', 0.993, "Method", "PhaseCode");
end