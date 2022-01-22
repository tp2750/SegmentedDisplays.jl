using Revise, SegmentedDisplays
using Images, FileIO
#=
# API based on structs

Trying to make it easier to maintain, we define a `Display` data type containing `DigitArea` and other custom data types.

The interface is as follows:

=#

# Load image:
img1 = load("images/cam-hi_2021-12-20_2130_1200x1600.jpg");

# Load display definition into Display data structure
dis1 = Display("images/cam-hi_2021-12-20_2130_1200x1600_display.yml");

# Call the digits
display_call_digits!(dis1, img1; method="2means")

## display the values
display_values(dis1)

# ## Debugging
# If not all values are called correctly, we can dig in to see the details:

# Digit calls:
SegmentedDisplays.display_digits(dis1)

# Segment calls:
SegmentedDisplays.display_segments(dis1)

#=
# Showing annotation on image.

It is easy to show the annotation on an image:

Show the viewing area and digit areas (TODO: icon areas):
=#

draw_areas(img1,dis1)

# Show the position of the digits:

draw_digits(img1,dis1)

# Show position of segments:

draw_segments(img1,dis1)

