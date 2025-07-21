% Clean the workspace and close all figures before starting
clc;
clear;
close all;

% --- Configuration ---
% Define the conversion from pixels to your desired unit (e.g., micrometers).
% You can adjust this value based on your microscope/camera calibration.
PIXELS_PER_MM = 1356; % (e.g., 680 pixels / 2mm)
MICROMETERS_PER_MM = 1000;
SCALE = MICROMETERS_PER_MM / PIXELS_PER_MM; % Resulting scale in um/pixel
folderPath = "D:\16-6 - Solder bump photos\7-17 prereflow pcb 1\360 consistency test (run 1 dg .325)";
rws = 10; % Rows
cls = 10; % Columns

% Remove quotes from Ctrl+shift+c in Windows Explorer
% folderPath = replace(filePath, '"', '');
files = dir(fullfile(folderPath, "*.jpg"));
data = zeros(1, length(files));
outMatrix = zeros(rws, cls);


for i = 1:length(files)
    filePath = fullfile(files(i).folder, files(i).name);
    % 3. Check if the file exists before trying to open it
    % if ~exist(filePath, 'file')
    %     fprintf('ERROR: File not found. Please check the path and try again.\n\n');
    %     return; % exit program
    % end
    
    % 4. Load and display the image
    try
        img = imread(filePath);
        h = figure('Name', ['Image: ' files(i).name], 'NumberTitle', 'off');
        imshow(img);
        hold on;
    catch ME
        fprintf('ERROR: Could not read the image file. It may be corrupt.\n');
        fprintf('Details: %s\n\n', ME.message);
        continue;
    end
    
    % 5. Get 3 points from the user
    title('Select 3 points on the circle circumference, then press Enter.');
    [x_pts, y_pts] = getpts(h);
    
    % 6. Check if the user provided enough points
    if length(x_pts) < 3
        fprintf('Measurement cancelled for this image (fewer than 3 points selected).\n\n');
        close(h);
        continue;
    elseif length(x_pts) > 3
        fprintf('Note: More than 3 points were selected. Only the first 3 will be used.\n');
    end
    
    % 7. Calculate the circle from the first 3 points
    A = [x_pts(1), y_pts(1)];
    B = [x_pts(2), y_pts(2)];
    C = [x_pts(3), y_pts(3)];
    
    % Mathematical formulation to find the center and radius
    D = 2 * (A(1) * (B(2) - C(2)) + B(1) * (C(2) - A(2)) + C(1) * (A(2) - B(2)));
    
    % Avoid division by zero if points are collinear
    if abs(D) < 1e-6
        fprintf('ERROR: The selected points are collinear (on a straight line). Cannot form a circle.\n\n');
        close(h);
        continue;
    end
    
    center_x = ((A(1)^2 + A(2)^2) * (B(2) - C(2)) + (B(1)^2 + B(2)^2) * (C(2) - A(2)) + (C(1)^2 + C(2)^2) * (A(2) - B(2))) / D;
    center_y = ((A(1)^2 + A(2)^2) * (C(1) - B(1)) + (B(1)^2 + B(2)^2) * (A(1) - C(1)) + (C(1)^2 + C(2)^2) * (B(1) - A(1))) / D;
    
    radius_pixels = sqrt((A(1) - center_x)^2 + (A(2) - center_y)^2);
    diameter_pixels = radius_pixels * 2;
    
    % 8. Convert diameter to real-world units
    diameter_um = diameter_pixels * SCALE;
    data(i) = diameter_um;
    outMatrix(i) = diameter_um;
    
    % 9. Display the result on the image and in the command window
    viscircles([center_x, center_y], radius_pixels, 'Color', 'g', 'LineWidth', 1);
    plot(x_pts(1:3), y_pts(1:3), 'r+', 'MarkerSize', 10, 'LineWidth', 2); % Mark the selected points
    
    result_string = sprintf('Measured Diameter: %.2f micrometers. Press Enter to continue.', diameter_um);
    title(result_string);
    fprintf('--> File: %s | Diameter: %.2f micrometers\n\n', filePath, diameter_um);
    % clipboard("copy", diameter_um);
    % disp("Copied diameter to clipboard");
    
    % 10. Wait for user to press Enter to close the figure
    k = 0;
    while k ~= 13 % 13 is the ASCII code for the Enter key
        w = waitforbuttonpress;
        if w == 1 % 1 indicates a key was pressed
            k = get(h, 'CurrentCharacter');
        end
    end

    close(h);
end

% clipboard("copy", sprintf("%f\n", data));

stringCells = arrayfun(@(x) num2str(x), outMatrix, 'UniformOutput', false);
lengths = cellfun(@length, stringCells);
[rows, cols] = size(outMatrix);
totalChars = sum(lengths(:)) + (cols - 1) * rows + (rows - 1);
clipboardString = blanks(totalChars);
currentIndex = 1;
for i = 1:rows
    for j = 1:cols
        numStr = stringCells{i, j};
        numLength = lengths(i, j);
        clipboardString(currentIndex : currentIndex + numLength - 1) = numStr;
        currentIndex = currentIndex + numLength;
        if j < cols
            clipboardString(currentIndex) = sprintf('\t');
            currentIndex = currentIndex + 1;
        end
    end
    if i < rows
        clipboardString(currentIndex) = newline;
        currentIndex = currentIndex + 1;
    end
end
clipboard('copy', clipboardString);

disp("Copied data to clipboard");

% close(h); % Close the figure

disp('Program exited.');