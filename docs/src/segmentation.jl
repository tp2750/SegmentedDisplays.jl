#=
# Segmentation
tp, 2021-12-26
Describe the segmentation of a segmented display.

# YAML file

We use a [YAML]() formatted file to do manual annotation of the segmentation of the display.

Here's the top of the file:

```
display:
  name: flowIQ2200
  tetragon:
    - [426, 1459]
    - [449, 157]
    - [904, 160]
    - [890, 1469]
  values:
    -
      name: consumption
      type: number
      elements:
        -
          name: v1d1
          type: digit
          segments:
            - # A
              - [512, 1249]
              - [513, 1192]
              - [528, 1193]
              - [529, 1248]
            - # B

```

This is read in to a `Dict`:

=#

using YAML, PrettyPrinting
seg1 = YAML.load_file("../../images/cam-hi_2021-12-20_2130_1200x1600_segments.yml");

pprint(seg1)

#=

# Showing a segmentation on an image

To see that the segmentation matched the image, we plot it on top of the image

=#

using Images, FileIO, ImageDraw
using SegmentedDisplays

img1= load("../../images/cam-hi_2021-12-20_2130_1200x1600.jpg");
segmentation_image_draw(seg1, img1)
