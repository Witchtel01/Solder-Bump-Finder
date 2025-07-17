folderPath = "D:\16-6 - Solder bump photos\7-15 PCB 1-1 and 1-2\7-15 PCB 1-1\";
lineWidth = 1000; % calibration line width in um
pixels = 1356; % calibration pixels

columns = 10;
rows = 10;

outMatrix = zeros(rows, columns);

% --- Setup Parallel Environment ---
if isempty(gcp('nocreate'))
    parpool; % Start a parallel pool if one is not running
end
p = gcp;
cleanupObj = onCleanup(@() delete(gcp('nocreate'))); % Ensure pool closes on exit

% --- Main Script Setup ---
files = dir(fullfile(folderPath, "*.jpg"));
numFiles = length(files);
data = zeros(1, numFiles);
fprintf('Found %d images to process.\n', numFiles);

if numFiles == 0
    disp('No image files found in the specified directory.');
    return;
end

% --- 1. SUBMIT ALL JOBS TO THE POOL AT ONCE ---
% This creates an array of 'Future' objects, one for each image.
% The background workers will start processing these immediately.
F(1:numFiles) = parallel.FevalFuture; % Pre-allocate the array
fprintf('Submitting all %d jobs to the parallel pool...\n', numFiles);
for idx = 1:numFiles
    fullFilePath = fullfile(files(idx).folder, files(idx).name);
    % Each F(idx) is a placeholder for the results of processImage
    F(idx) = parfeval(p, @processImage, 3, fullFilePath);
end
fprintf('All jobs submitted. Now processing results as they complete.\n\n');


% --- 2. FETCH AND PROCESS RESULTS AS THEY COMPLETE ---
% This loop will run once for each image, waiting for the next available result.
for i = 1:numFiles
    % fetchNext waits for the NEXT completed job from the entire array F
    % It returns the index of the job that finished, plus its results.
    [completedIdx, centers, radii, grayImage] = fetchNext(F);
    
    fileName = files(completedIdx).name;
    fprintf('--> Processing result %d of %d: %s. Found %d circle(s).\n', i, numFiles, fileName, length(radii));

    % --- FAST PATH: Exactly one circle found. No GUI. ---
    if isscalar(radii)
        data(completedIdx) = radii * 2 / pixels * lineWidth;
        fprintf('    AUTO-PROCESSED. Diameter: %.2f micrometers\n', data(completedIdx));
        continue; % Immediately skip to the next fetchNext call
    end

    % --- SLOW PATH: 0 or >1 circles found. Requires user input. ---
    fprintf('    MANUAL REVIEW NEEDED. Displaying GUI...\n');
    h = figure('Name', ['Image: ' fileName], 'NumberTitle', 'off', 'WindowState', 'maximized');
    imshow(grayImage);
    hold on;
    
    selected_radius = []; 

    if ~isempty(radii) % This condition means length(radii) > 1
        title('Click the center of the correct circle to select it.');
        viscircles(centers, radii, 'Color', 'b');
        selection_made = false;
        while ~selection_made
            w = waitforbuttonpress;
            if w == 0 % Mouse click
                click_pt = get(gca, 'CurrentPoint');
                x_click = click_pt(1, 1); y_click = click_pt(1, 2);
                distances = sqrt(sum(bsxfun(@minus, centers, [x_click, y_click]).^2, 2));
                [~, min_idx] = min(distances);
                selected_center = centers(min_idx, :);
                selected_radius = radii(min_idx);
                imshow(grayImage); hold on;
                viscircles(centers, radii, 'Color', 'b');
                viscircles(selected_center, selected_radius, 'Color', 'r');
                title('Selection Confirmed. Press Enter to continue.');
                selection_made = true;
            elseif w == 1 && get(h, 'CurrentCharacter') == 13
                title('ERROR: You must CLICK a circle before pressing Enter.');
                beep;
            end
        end
    else % This is the isempty(radii) case (0 circles)
        title('No circles detected. Select 3 points on the circle circumference.');
        [x_pts, y_pts] = getpts(h, 3);
        if length(x_pts) == 3
            A = [x_pts(1), y_pts(1)]; B = [x_pts(2), y_pts(2)]; C = [x_pts(3), y_pts(3)];
            D = 2 * (A(1) * (B(2) - C(2)) + B(1) * (C(2) - A(2)) + C(1) * (A(2) - B(2)));
            center_x = ((A(1)^2 + A(2)^2) * (B(2) - C(2)) + (B(1)^2 + B(2)^2) * (C(2) - A(2)) + (C(1)^2 + C(2)^2) * (A(2) - B(2))) / D;
            center_y = ((A(1)^2 + A(2)^2) * (C(1) - B(1)) + (B(1)^2 + B(2)^2) * (A(1) - C(1)) + (C(1)^2 + C(2)^2) * (B(1) - A(1))) / D;
            selected_radius = sqrt((A(1) - center_x)^2 + (A(2) - center_y)^2);
            viscircles([center_x, center_y], selected_radius, 'Color', 'g');
            title('Manual measurement complete. Press Enter to continue.');
        else
            title('Did not select 3 points. Press Enter to skip.');
            selected_radius = NaN;
        end
    end
    
    if ~isnan(selected_radius)
        data(completedIdx) = max(selected_radius) * 2 / pixels * lineWidth;
    else
        data(completedIdx) = NaN;
    end
    
    fprintf('    MANUAL INPUT logged. Diameter: %.2f micrometers\n', data(completedIdx));
    
    k = 0;
    while k ~= 13
        w = waitforbuttonpress;
        if w == 1, k = get(h, 'CurrentCharacter'); end
    end
    
    close(h);
end

% Save to matrix
for i = 1:length(data)
    outMatrix(i) = data(i);
end

% Save data
fid = fopen("data.txt", "w");
fprintf(fid, "%f\n", data);
fclose(fid);

% Copy to clipboard

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


disp('All images processed.');