#=
# Digit Identification

Given a `Tetragon` idenfifying a digit, we need to figure out which digit it is showing.

The strategy is as follows:

1. Identify the fg (black=0) and bg (white=1) levels using k-means clustering with 2 levels
2. Identify which pixels belong to segments
3. For each segment counf foreground and background pixels to determine if element is on or off
4. Assing digit value based on combination of on segments
5. Warn if the found segment combination is not a known digit

## Struct `Segment`

A `Segment` is given by the coordinates of the ends of the mid-line and its name:

```
struct Segment
    ends::Vector{Vector{Int}} ## [[i1,j1], [i2,j2]]
    name::String
end    
```

We have a function to split a digit-`Tetragon` into `Segment`s: `digit_segments(t::Tetragon)`

Below we show the segmentation of digit number 4
=#
using SegmentedDisplays, Images, FileIO, YAML, PrettyPrinting, Statistics, ImageDraw
img = load("../../images/display_reference.png");
seg = YAML.load_file("../../images/display_reference_display.yml");

digit4 = display_digits_tetragons(seg)[4]
digit4_segments = digit_segments(digit4)

draw(img,LineSegments(digit4_segments), RGB{N0f8}(0,1,0))


#=

## Segment expansion

Next, we expand segments to `Tegragons` of a given width.
By default we take care not to expand into the background. This is controlled by the kw `iiner`. 

This is done by the function `segment_tetragon(s::Segment, width=0; inner=true)`
Below, we show the segments "A" and "B" of digit 4:
=#

draw(img, LineSegments(segment_tetragon(digit4_segments[1], 8)), RGB{N0f8}(0,1,0))
draw(img, LineSegments(segment_tetragon(digit4_segments[2], 8)), RGB{N0f8}(0,1,0))

#=

## Pixel values in `Tetragon`s

This far we have operated on abstract `Segment`s and `Tetragon`s. Now we connect them to the image and extract pixel values.

The main function is `image_region_pixels(image, t::Tetragon)`, which works for `Tegraon`s and `Segment`s.
**TODO:** For now, `image_region_pixels` returns pixels in the outer rectangle of the `Tetragon`, so it is wrong if it is too skew.

Below, we extract the median grey-scale values of segment "B" of letter 4 using a whdth of 10 pixels (as showen above):
=#
using Statistics
median(image_region_pixels(Gray.(img), segment_tetragon(digit4_segments[2], 10)))

#=
Now we are ready to identify the digits as described.

This is done in the function `digit_analysis(image, t::Tetragon,  segmentwidth=8)`.
Below we analyze digit 4:
=#

using DataFrames
digit_analysis(img, digit4)

