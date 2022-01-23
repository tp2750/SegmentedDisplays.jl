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

# Call the digits using "2means" method. It fails to parse the flow area (small digits).
display_call_digits!(dis1, img1; method="2means");

# Display the values
display_values(dis1)

# Call display using 2-point method:
dis2 = Display("images/cam-hi_2021-12-20_2130_1200x1600_display.yml");
display_call_digits!(dis2, img1; method="2points")

# Note that this also works for the flow area.

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

# Show points used for 2-point method:
draw_2points(img1, dis1)
