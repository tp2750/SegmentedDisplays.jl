module SegmentedDisplays

using Images, FileIO, Plots
import RollingFunctions ## for rollmedian

include("plot.jl")
export segment_dashboard

using ImageDraw, PrettyPrinting, YAML
include("segment.jl")
export segmentation_image_draw!, segmentation_image_draw

end
