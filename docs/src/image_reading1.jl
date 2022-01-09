using Revise, SegmentedDisplays, Images, FileIO, YAML, PrettyPrinting, Statistics, ImageDraw
#=
# Trying on a real image

=#

dis = SegmentedDisplay("images/cam-hi_2021-12-20_2130_1200x1600_display.yml");

img = load("images/cam-hi_2021-12-20_2130_1200x1600.jpg")

#=

Now parse results

=#

image_display_values(img, dis)
