module SegmentedDisplays

using Images, FileIO, Plots
import RollingFunctions ## for rollmedian

include("v1.jl") ## deprecated functions

include("plot.jl")
export segment_dashboard

using ImageDraw, PrettyPrint, YAML
using DataFrames, Clustering, DataStructures, DataFramesMeta
include("segment.jl")
export Tetragon, tetragon_trace, display_area_tetragons
export area_digits_tetragons, display_digits_tetragons

export Segment, digit_segments, hmid, LineSegments, segment_tetragon, image_region_pixels

export SegmentedDisplay, display_DataFrame, digit_analysis,  decode_segments, display_digit_values

export image_display_decimal_DataFrame, image_display_values

using Statistics
include("utils.jl")

export normalize_image, normalize_image!

## deprecated functions for API v1 (2021-12-26)
export segmentation_image_draw!, segmentation_image_draw

## 2022-01-10 New structure
include("structs.jl")
export Display, display_call_digits!, display_values
export display_digits, display_segments
export draw_areas, draw_digits, draw_segments, draw_2points

include("methods.jl")

end
