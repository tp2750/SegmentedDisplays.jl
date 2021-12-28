#=
# Segmentation of displays

LCD nomenclature: https://www.pacificdisplay.com/lcd_glossary.htm

We use a YAML file to annotate the active areas. See an example at the end.
The annotation includes:

* name
* tetragon
* number of digits
* width of individual digit

`Tetragon`s are specified by the 4 corners in the order: upper-right, upper-left, lower-left, lower-right (as qaudrants in coordinate system).
The corners are given as pixel-vectors [i,j], where i is row number (from top) and j is column number (from left).

Everything is measured in pixels.

When we annotate 7-segment digits, we trace the middle of the segments, as seen in the examples below.

## Annotation

Finding the `Tetragon`s of the active areas is done using the `imshow` function in ImageView.
It shows the coordinate of the mouse in the lower left corner.
Format is [i,j] as we use here as well.

```
using ImageView
using Images, FileIO
img = load("../../images/display_reference.png");
imshow(img)
```

## Structs

The `Tetragon` constructor is given a 4-vector of 2-vectors (corners).
It checks that the order of the corners is as described above.

```
struct Tetragon
    corners::Vector{Vector{Int}}
    function Tetragon(corners)
        @assert length(corners) == 4
        if corners[1][2] <= min(corners[2][2], corners[3][2]) || corners[1][1] >= max(corners[3][1], corners[4][1])
            error("first corner must be top-right, then top-left. Coordinates: [i,j] row from top, column from left.")
        end
        new(corners)
    end
end
```

We have a `tetragon_trace` function to draw one or more `Tetragon`s on an image.
It has methods for:
* `Tegragon`
*  `Vector{Tetragon}`
* a 4-vector of 2-vectors (corners)

Here's an example, where we trace the active areas of the reference display image:

=#

using Images, FileIO, ImageDraw, YAML, PrettyPrinting, Statistics
using Revise, SegmentedDisplays

img = load("../../images/display_reference.png");
seg = YAML.load_file("../../images/display_reference_display.yml");
pprint(seg)

#imshow(
draw(img,tetragon_trace(display_area_tetragons(seg)), RGB{N0f8}(0,1,0))
#)

#=
Above we used the function `display_area_tetragons` to extract the `Tetragon`s of the active areas.

# Finding digits

Next, we use the annotated digit width and number of digits to split each active are into `Tetragon`s identifying the digits.

This is done by the function `area_digits_tetragons(area, digits, digit_width=46)`.
The `area` can be a `Tetragon` or a 4-vector of 2-vectors (corners).

Below we use it to find the digits of the main area of the reference display:
=#

#imshow(
draw(img, tetragon_trace(area_digits_tetragons(display_area_tetragons(seg)[1], 9, 46)), RGB{N0f8}(0,1,0))
#)

#=
We also define a function to find all digits in all active areas and assign them `Tetragon`s:
`display_digits_tetragons` 

Below we use it on the reference display.
Note that the annunicators (icons) in the bottom-right corner are not perfectly segmented.
The plan is to test if they are on or off by evaluating the average intensity inside the `Tetragon`.
=#

#imshow(
draw(img, tetragon_trace(display_digits_tetragons(seg)), RGB{N0f8}(0,1,0))
#)

#=
# Annotation of display reference

Below is the full annotation of the reference display (parsed from YAML file).
Note that `digitseparation` is not used, and will probably be removed.

=#

pprint(seg)

