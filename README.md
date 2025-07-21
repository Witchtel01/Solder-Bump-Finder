# Solder Bump Finder

Allows microscope images to be automatically processed and diameters to be automatically measured.

## Installation Instructions

1. Ensure MATLAB is installed
2. Ensure MATLAB Image Processing Toolbox and Parallel Computing Toolbox are installed
3. Clone the repository
4. Change initial parameters
5. Run the program

## Program Descriptions

### [allManual.m](allManual.m)

#### Loops through the given folder and runs the manual diameter finder on all images

Use this when automaticGUI and automaticNoGUI are consistently not finding the correct diameters.

To use this program, set up the parameters (microscope calibration, image folder, grid size) and run the program. Click any 3 points on the circle's circumference and hit \<Enter> to view the resulting circle. Hit \<Enter> again to move to the next image.

This program automatically copies the output in a matrix form that can be easily pasted into Excel or other spreadsheet applications.

---

### [automaticGUI.m](automaticGUI.m)

#### Loops through the given folder and runs the automatic diameter finder on all images while showing a GUI for each processed image

To use this program, set up the parameters (microscope calibration, image folder, grid size) and run the program. After processing every image, it will show the image to you. Move on to the next image with \<Enter>. If no circles are found, click any 3 points on the circle's circumference and then hit \<Enter> to view the resulting circle. Hit \<Enter> again to move to the next iamge. If more than 1 circle is found, click close to the center of a highlighted circle which most accurately shows the circle you want.

This program automatically copies the output in a matrix form that can easily be pasted into Excel or other spreadsheet applications.

[Note](#known-issues)

---

### [automaticNoGUI.m](automaticNoGUI.m)

#### Loops through the given folder and runs the auomatic diameter finder on all images

To use this program, set up the parameters (microscope, calibration, image folder, grid size) and run the program.

This program automatically copies the output in a matrix form that can easily be pasted into Excel or other spreadsheet applications.

[Note](#known-issues)

---

### [manualMeasurements.m](manualMeasurements.m)

#### Opens singular images for manual review and measurements

To use this program, set up the parameters (microscope calibration) and run the program. In the terminal, paste the path to the image you need to measure and hit \<Enter>. Click on any 3 points on the circumference of the circle and hit \<Enter> to view the resulting circle. Hit \<Enter> again to move to the next image. The calculated diameter is displayed in the terminal and also copied to your clipboard. To exit the program, hit \<Enter> in the terminal.

---

### [manualMeasurementsClipboard.m](manualMeasurementsClipboard.m)

#### Opens singular images from the clipboard's path for manual review and measurements. Especially helpful when using Windows

To use this program, set up the parameters (microscope calibration). Copy the path to the desired image (in Windows file explorer, you can use the shortcut `Ctrl+Shift+C` after selecting the image in the explorer), and run the program. In the GUI that opens up, click on any 3 points on the circle's circumferencce and hit \<Enter> to view the resulting circle. Hit \<Enter> again to move to the next image. The calculated diameter is displayed in the terminal and also copied to your clipboard.

---

### [processImage.m](processImage.m)

#### This is a helper function that contains the circle-finding logic

You may find it helpful to modify this program as necessary to get it to find your circles.

---

### [processImageOriginal.m](processImageOriginal.m)

#### This is another helper function that contains the circle-finding logic

You may find it helpful to modify this program as necessary to get it to find your circles.

## Known Issues

The automaticGUI and automaticNoGUI programs may crash if the `clear` command is not entered into the terminal before running the program. The MATLAB processing pool must be shut down first before attempting to run these multithreaded programs.
