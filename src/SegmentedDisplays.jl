module SegmentedDisplays

using Images, FileIO, Plots
import RollingFunctions ## for rollmedian

include("plot.jl")
export segment_dashboard

using ImageDraw, PrettyPrinting, YAML
using DataFrames, Clustering, DataStructures
include("segment.jl")
export Tetragon, tetragon_trace, display_area_tetragons
export area_digits_tetragons, display_digits_tetragons

export Segment, digit_segments, hmid, LineSegments, segment_tetragon, image_region_pixels

export SegmentedDisplay, display_DataFrame, digit_analysis,  decode_segments, display_digit_values

using Statistics
include("utils.jl")

## deprecated functions for API v1 (2021-12-26)
export segmentation_image_draw!, segmentation_image_draw

end
