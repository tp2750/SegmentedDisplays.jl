# # Segment Dashboard
using SegmentedDisplays
using Images, FileIO, Plots

#=
## Background

This work is motivated by the need to decode a water meter display based on images taken by an esp32 camera.

Below we analyse sucha an image in order to detect the placements of the segments of the display.

## Load image and convert to gray-scale

We have obtained an image using from and ESP32 camera using
 * First version of our mount:
 * The WifiCam script from :

We immediately convert the imag to gray-scale.

=#

img1_original = load("../../images/cam-hi_2021-12-20_2130_1200x1600.jpg");
img1 = Gray.(img1_original);

#=
## Segment Dashboard

The `segment_dashboard` function helpt us analyze the image.
It has 4 panels:
* Q1 (upper right): the image with the selected lines shown
* Q2 (upper left): the gray-scale value along the selected horizontal pixel
* Q3 (lower left): the rolling median value to subtract to correct for differences in lighting
* Q4 (lower right): thebackground corrected gray-scale values alon the pixel line.

The optional vertical line is shown on all 4 sub-plots as well.
=#

segment_dashboard(img1, 650, 230)

#=
## Lessons learned

With the first version of our mount, there is a strong light gradient over the image (from the in-built LED of the ESP32 cam).
This is seen as an overall parabola-shape of the intensity along a horizontal line (Q2).

We are able to remove this by subtracting a rolling median (Q3).
In this case, the original image is 1600 pixels wide, the horizontal width of a segment is 14 pixels, and the distance between segments is 42 pixels. A windo size of 42 works well.

## Limitations

We see below, that the horizontal segments are not detectable in this way.
We will need to detect those using vertical lines.

=#

segment_dashboard(img1, 680, 400)

#=
A larger window size helps:

=#

segment_dashboard(img1, 680, 230; window=200)

# That window size also works for the vertical segments:

segment_dashboard(img1, 650, 230; window=200)

