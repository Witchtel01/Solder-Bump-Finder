folderPath = "D:/16-6 - Solder bump photos/7-14 Run 1/Grid Row 1";
lineWidth = 1000; % calibration line width in um
pixels = 1356; % calibration pixels

% --- Setup Parallel Environment ---
% Check if a parallel pool exists; if not, create one.
if isempty(gcp('nocreate'))
    parpool;
end
% Get the current pool
p = gcp; 

% Ensure the pool is shut down automatically when the script finishes or errors
cleanupObj = onCleanup(@() delete(gcp('nocreate')));

% --- Main Script ---
files = dir(fullfile(folderPath, "*.jpg"));
data = zeros(1, length(files));

% --- Prime the Pipeline ---
% Asynchronously start processing the FIRST image
fprintf('Starting job for image 1: %s\n', files(1).name);
F = parfeval(p, @processImage, 3, fullfile(files(1).folder, files(1).name)); % 3 output arguments

for i = 1:length(files)
    % --- 1. FETCH RESULTS for the CURRENT image ---
    % fetchOutputs will wait here until the job for image 'i' is complete
    [centers, radii, grayImage] = fetchOutputs(F);
    fprintf('Results received for image %d. Displaying for review.\n', i);

    % --- 2. LAUNCH NEXT JOB (if one exists) ---
    % While we interact with image 'i', the worker will process 'i+1'
    if (i + 1) <= length(files)
        fprintf('Starting job for image %d: %s\n', i + 1, files(i+1).name);
        nextFilePath = fullfile(files(i+1).folder, files(i+1).name);
        F = parfeval(p, @processImage, 3, nextFilePath);
    end

    % --- 3. INTERACT WITH USER (This logic is mostly unchanged) ---
    fileName = files(i).name;
    h = figure('Name', ['Image: ' fileName], 'NumberTitle', 'off');
    imshow(grayImage);
    hold on;
    
    selected_radius = []; 

    if ~isempty(radii)
        if length(radii) > 1
            % (Error checking logic for multiple circles is the same as before)
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
        else
            selected_radius = radii;
            viscircles(centers, radii, 'Color', 'r');
            title('Circle detected. Press Enter to continue.');
        end
    else
        gettingPts = true;
        while gettingPts
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
                gettingPts = false;
            else
                title('Did not select 3 points.');
                % selected_radius = NaN;
            end
        end
    end
    
    if ~isnan(selected_radius)
        data(i) = max(selected_radius) * 2 / pixels * linewidth;
    else
        data(i) = NaN;
    end
    
    disp(['Diameter for ', fileName, ': ', num2str(data(i)), ' micrometers']);
    
    k = 0;
    while k ~= 13
        w = waitforbuttonpress;
        if w == 1, k = get(h, 'CurrentCharacter'); end
    end
    
    close(h);
end

disp('All images processed.');