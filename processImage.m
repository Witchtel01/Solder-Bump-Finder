function [centers, radii, grayImage] = processImage(fullFilePath)
    % This function performs the non-interactive image processing.
    
    orig = imread(fullFilePath);
    grayImage = im2gray(orig);
    grayImage = ~imbinarize(grayImage);
    grayImage = imfill(grayImage, "holes");
    % imshow(grayImage);
    % Image preprocessing
    % grayImage(grayImage > (max(max(grayImage)) - min(min(grayImage)))/2 + min(min(grayImage)) - 40) = 255;
    % grayImage(grayImage < (max(max(grayImage)) - min(min(grayImage)))/2 + min(min(grayImage)) - 40) = 0;
    
    % final = imopen(imfill(grayImage, "holes"), strel("disk", 10));
    % imshow(final);

    radiusRange = [400 1500];
    [centers, radii] = imfindcircles(grayImage, radiusRange, 'ObjectPolarity', 'bright', 'Sensitivity', 0.99, "Method", "PhaseCode");
end