
"""
    Tetragon is defined by the corners in this order (as qaudrants in coordinate system):
    upper-right, upper-left, lower-left, lower-right
    The corners are given as pixel-vectors [i,j], where i is row number (from top) and j is column number (from left)
"""
struct Tetragon
    corners::Vector{Vector{Int}}
    function Tetragon(corners)
        @assert length(corners) == 4
        if corners[1][2] < min(corners[2][2], corners[3][2]) || corners[1][1] > max(corners[3][1], corners[4][1])
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


"""
    Segment
    2-vector of 2-vectors giving the ends of a line segment
    [[i1,j1], [i2,j2]]
"""
struct Segment
    ends::Vector{Vector{Int}}
    name::String
end    


"""
    digit_segments
    Input: Tetragon of 7-segment digit
    Output: vector of Segments
"""
function digit_segments(corners)
    midline = hmid(corners)
    segments = Segment[]
    push!(segments, Segment([corners[1], corners[2]],"A"))
    push!(segments, Segment([corners[1], midline[1]],"B"))
    push!(segments, Segment([midline[1], corners[4]],"C"))
    push!(segments, Segment([corners[4], corners[3]],"D"))
    push!(segments, Segment([corners[3], midline[2]],"E"))
    push!(segments, Segment([midline[2], corners[2]],"F"))
    push!(segments, Segment([midline[1], midline[2]],"G"))
    segments
end
digit_segments(t::Tetragon) = digit_segments(t.corners)

"""
    hmid: compute horizontal midline
    input: corners (4vector of 2vectors) or Tetragon
    output: 2vector of 2vectors: [rightend, leftend]
"""
function hmid(corners) ## was digit7s_midsegment
    ## Output: 2-vector of 2-vectors
    [
        round.(Int, [Statistics.mean([corners[4][1], corners[1][1]]),  Statistics.mean([corners[4][2], corners[1][2]])]),
        round.(Int, [Statistics.mean([corners[2][1], corners[3][1]]),  Statistics.mean([corners[2][2], corners[3][2]])]),
    ]
end
hmid(t::Tetragon) = hmid(t.corners)



"""
    generate a vector of `ImageDraw.LineSegment`s from a vector of 2-vectors
    A 2-vector of 2-vectors give a line
    A 4-vector of 2-vectos give a tetragon
    Also a method for `Tegragon` and `Segment`, and vectors of those.
    close = true is needed to close tetragons.

    Note, this is not Type Piracy, as ImageDraw exports `LineSegment`, but not `LineSegments`
    This generalizes the older `tetragon_trace()`

    Example:
    imshow(draw(img,LineSegments(display_digits_tetragons(seg)), RGB{N0f8}(0,1,0)))
    # imshow(draw(img,vcat(LineSegments.(digit_tetragons)..., LineSegments.(hmid.(digit_tetragons))...) , RGB{N0f8}(0,1,0)))
"""
function LineSegments(v::Vector{Vector{Int}}; close = true)
    Lines = LineSegment[]
    for i in 2:length(v)
        push!(Lines, ImageDraw.LineSegment(CartesianIndex(v[i]...), CartesianIndex(v[i-1]...)))
    end
    if close
        push!(Lines, ImageDraw.LineSegment(CartesianIndex(v[end]...), CartesianIndex(v[1]...)))
    end
    Lines
end
LineSegments(t::Tetragon) = LineSegments(t.corners)
LineSegments(s::Segment)  = LineSegments(s.ends)
## Vector versions for ergonomy:
LineSegments(tv::Vector{Tetragon}) = vcat(LineSegments.(tv)...)
LineSegments(sv::Vector{Segment})  = vcat(LineSegments.(sv)...)



"""
    segment_tetragon
    convert a segment (2vector of 2vectos) to a `Tetragon` of the given width.
    If inner is true it only expands perpendicularly to the segment
"""
function segment_tetragon(ends, width=0; inner=true)
    is = [ends[1][1], ends[2][1]]
    js = [ends[1][2], ends[2][2]]
    hwi = hwj =round(Int, width/2) ## Half-width
    if inner
        hwi = abs(diff(js)[1]) < abs(diff(is)[1]) ? -hwi : hwi ## dont extend horizontal
        hwj = abs(diff(is)[1]) < abs(diff(js)[1]) ? -hwj : hwj ## dont extend vertical
    end
    Tetragon(
    [
        [min(is...) - hwi, max(js...) + hwj], ## 1 is min i, max j
        [min(is...) - hwi, min(js...) - hwj], ## 2 is min i, min j
        [max(is...) + hwi, min(js...) - hwj], ## 3 is max i, min j
        [max(is...) + hwi, max(js...) + hwj], ## 4 is max i, max j
    ]
    )    
end
segment_tetragon(s::Segment, width=0; inner=true) = segment_tetragon(s.ends, width; inner=inner)

"""
    Get the pixels of a region
"""
image_region_pixels(image, t::Tetragon) = image_tetragon_pixels(image, t)
image_region_pixels(image, s::Segment) = image_segment_pixels(image, s)

"""
    Get the pixels of a Tetragon
"""
function image_tetragon_pixels(image, corners) ## outer rectangle TODO restrict to parallelogram
    image[min(corners[2][1],corners[3][1]):max(corners[2][1],corners[3][1]),
          min(corners[2][2],corners[1][2]):max(corners[2][2],corners[1][2]),
          ]
end
image_tetragon_pixels(image, t::Tetragon) = image_tetragon_pixels(image, t.corners)

"""
    Get the pixels of a segment
"""
function image_segment_pixels(image, corners) ## outer rectangle
    image[min(corners[2][1],corners[1][1]):max(corners[2][1],corners[1][1]),
          min(corners[2][2],corners[1][2]):max(corners[2][2],corners[1][2]),
          ]
end
image_segment_pixels(image, s::Segment) = image_segment_pixels(image, s.ends)

"""
    Analyze a tetragon as a seven-segment digit
    input: image and tetragon bounding the digit
    output: DataFrame with one row per segment indicating if the segment is on or off.
    TODO for now, the segmentwidth is not used
"""
digit_analysis(image, t::Tetragon,  segmentwidth=8) = digit_analysis(image, t.corners, segmentwidth)
function digit_analysis(image, corners, segmentwidth=8)
    ## Find foreground and background
    digit_pixels = Gray.(image_tetragon_pixels(image, corners))
    pixel_vector = float64.(vec(digit_pixels))
    pixel_res = kmeans(pixel_vector, 2)
    pixel_centers = vec(pixel_res.centers)
    fg_cluster, bg_cluster = argmin(pixel_centers), argmax(pixel_centers) ## fg is black:0, bg is white: 1
    @info fg_cluster, bg_cluster
    pixel_std =  map( x-> std(pixel_vector[assignments(pixel_res) .== x]), (1,2))
    img_assignments = predict(Gray.(image), pixel_centers) ## assign cluster to full image based on local segmentation
    segments = digit_segments(corners)
    segment_counts = map(segments) do s
        segment_assignmets = image_region_pixels(img_assignments, s) ## todo? expand segment line to tetragon?
        res = DataFrame(segment = s.name, fg_count = sum(segment_assignmets .== fg_cluster), bg_count = sum(segment_assignmets .== bg_cluster), segment_size = size(segment_assignmets))
        transform(res, [:fg_count, :bg_count] => ByRow((x,y) -> x>y ? "on" : "off") => "state")
    end
    vcat(segment_counts...)
end

"""
    predict cluster assignment on new data
"""
function predict(image, centers)
    reshape(map(x -> argmin(abs.(x .- centers)), vec(image)), size(image))
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
