
"""
    Tetragon is defined by the corners in this order (as qaudrants in coordinate system):
    upper-right, upper-left, lower-left, lower-right
    The corners are given as pixel-vectors [i,j], where i is row number (from top) and j is column number (from left)
"""
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

function tetragon_trace(v::Vector{Tetragon})
    vcat([tetragon_trace(t.corners) for t in v]...)
end

"""
    tetragon_trace(t)
    Generate vector of LineSegment's that can be drawn to an image using draw()
    t can be a Tetragon, Vector{Tetragon} or just a 4-vector of 2-vectors.
"""
function tetragon_trace(t::Tetragon)
    tetragon_trace(t.corners)
end

function tetragon_trace(tetragon) ## using in  segmentation_overlay!
    @assert length(tetragon) == 4
    [ImageDraw.LineSegment(CartesianIndex(tetragon[1]...), CartesianIndex(tetragon[2]...)),
     ImageDraw.LineSegment(CartesianIndex(tetragon[2]...), CartesianIndex(tetragon[3]...)),
     ImageDraw.LineSegment(CartesianIndex(tetragon[3]...), CartesianIndex(tetragon[4]...)),
     ImageDraw.LineSegment(CartesianIndex(tetragon[4]...), CartesianIndex(tetragon[1]...)),
     ]
end

function display_area_tetragons(display)
    res = Tetragon[]
    for aa in display["display"]["active_areas"]
        push!(res, Tetragon(aa["tetragon"]))
    end
    res
end

"""
    area_digits_tetragons(area, digits, digit_width = 46)
    area::Tetragon, or vector of corners (4-vector of 2-vectors)
    digits::Int number of digts to detect
    digit_width::Int width of individual digit (the height is given by the area height).
    The coordinates trace the mid-lines of the segments (for 7-segment digits).
"""
function area_digits_tetragons(corners, digits, digit_width = 46)
    digit_heights = (corners[4][1] - corners[1][1], corners[3][1] - corners[2][1])
    digit_height = round(Statistics.mean(digit_heights))
    digit_height_cv_pct = cv_pct(digit_heights)
    @info "  digit height = $digit_height ± $digit_height_cv_pct %"
    # digit_width = round(digit_height / height_width_ratio)
    @info "  digit width = $digit_width"
    area_widths = (corners[1][2] - corners[2][2], corners[4][2] - corners[3][2])
    area_width = round(Statistics.mean(area_widths))
    area_width_cv_pct = cv_pct(area_widths)
    @info "  area width = $area_width  ± $area_width_cv_pct %"
    digit_separation = round((area_width - digits*digit_width)/(digits-1))
    @info "  digit separation = $digit_separation"
    ## TODO: slopes (top and bottom slopes can differ)
    res = Tetragon[]
    for digit = 1:digits ## order digits left to right. reverse later for number types.
        push!(res, Tetragon(
        [
            [corners[2][1], ## Todo: top slope
             corners[2][2]  +  digit * digit_width  +  (digit - 1) * digit_separation
             ], 
            [corners[2][1], ## Todo: top slope
             corners[2][2]  +  (digit-1) * digit_width  +  (digit - 1) * digit_separation
             ], 
            [corners[3][1], ## Todo: top slope
             corners[3][2]  +  (digit-1) * digit_width  +  (digit - 1) * digit_separation
             ], 
            [corners[3][1], ## Todo: bottom slope
             corners[3][2]  +  digit * digit_width  +  (digit - 1) * digit_separation
             ], 
        ]
        )
              )
    end
    res
end
area_digits_tetragons(area::Tetragon, digits, digit_width = 46) = area_digits_tetragons(area.corners,  digits, digit_width)

"""
    display_digits_tetragons(display)
    Return a vector of `Tetragon`s. Each corresponding to a digit in the display.
"""
function display_digits_tetragons(display)
    res1 = Tetragon[]
    for aa in display["display"]["active_areas"]
        @info "Name: " * aa["name"]
        push!(res1, area_digits_tetragons(Tetragon(aa["tetragon"]), aa["digits"], aa["digitwidth"])...)
    end
    res1
end


## Functions below are for the API v1 from 2021-12-26
function segmentation_image_draw!(segmentation, image)
    for val in segmentation["display"]["values"]
        for ele in val["elements"]
            for seg in ele["segments"]
                isnothing(seg) && continue
                draw!(image,  tetragon_trace(seg))
            end
        end
    end
end

function segmentation_image_draw(segmentation, image)
    img1 = copy(image)
    segmentation_image_draw!(segmentation, img1)
    img1
end
