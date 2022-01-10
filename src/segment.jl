
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

function area_decimal_segments(corners, digits, digit_width, segment_width)
    ## predict location of decimal points (as segements, ie 2-vectors or corners) similar to digits below
    area_width = corners[1][2] - corners[2][2]
    total_digit_width = digits * digit_width
    inter_digit_width = (area_width - total_digit_width)/(digits -1)
    @debug "area width = $area_width, digit_width=$digit_width, spacing=$inter_digit_width"
    decimal_js = corners[3][2] - round(Int, inter_digit_width/2) .+ [round(Int,(digit_width + inter_digit_width)*x) for x in 1:digits-1]
    slope = (corners[4][1] - corners[3][1])/area_width
    decimal_bottoms = round.(Int,(corners[3][1] .+ slope .* decimal_js)) ## obs: slope
    [[[i,j], [i-segment_width,j]] for (i,j) in zip(decimal_bottoms, decimal_js)]
end

function segment_decimal_analysis(image, ends;  threshold=0.1)
    ## Detect decimal points at segment:
    ## Compare min over segment to max over segment shiftet 2x heght up
    ## call "on" if diff is >= threshold
    ## loop over segments
    image_gray = Float64.(Gray.(image))
    res = map(ends) do e
        segment_size = abs(e[2][1] - e[1][1])
        seg_min = minimum(vec(image_segment_pixels(image_gray, e)))
        ref_max = maximum(vec(image_segment_pixels(image_gray, e - [[2*segment_size,0], [2*segment_size,0]])))
        [ref_max - seg_min , abs(ref_max - seg_min) >= threshold ? "on" : "off"]
    end
    res = permutedims(hcat(res...))
    DataFrame(power = length(ends):-1:1, contrast = Float64.(res[:,1]), state = res[:,2])
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
    @debug "  digit height = $digit_height ± $digit_height_cv_pct %"
    # digit_width = round(digit_height / height_width_ratio)
    @debug "  digit width = $digit_width"
    area_widths = (corners[1][2] - corners[2][2], corners[4][2] - corners[3][2])
    area_width = round(Statistics.mean(area_widths))
    area_width_cv_pct = cv_pct(area_widths)
    @debug "  area width = $area_width  ± $area_width_cv_pct %"
    digit_separation = round((area_width - digits*digit_width)/(digits-1))
    @debug "  digit separation = $digit_separation"
    ## TODO: slopes (top and bottom slopes can differ)
    top_slope = (corners[1][1] - corners[2][1])/(corners[1][2] - corners[2][2])
    bottom_slope = (corners[4][1] - corners[3][1])/(corners[4][2] - corners[3][2])
    res = Tetragon[]
    for digit = 1:digits ## order digits left to right. reverse later for number types.
        dj =  digit * digit_width  +  (digit - 1) * digit_separation
        dj1 =  (digit-1) * digit_width  +  (digit - 1) * digit_separation
        push!(res, Tetragon(
        [
            [corners[2][1] + round(Int,top_slope* dj), ##  top slope
             corners[2][2]  +  digit * digit_width  +  (digit - 1) * digit_separation
             ], 
            [corners[2][1] + round(Int,top_slope* dj1), ##  top slope
             corners[2][2]  +  (digit-1) * digit_width  +  (digit - 1) * digit_separation
             ], 
            [corners[3][1] + round(Int,bottom_slope* dj1), ##  bottom slope
             corners[3][2]  +  (digit-1) * digit_width  +  (digit - 1) * digit_separation
             ], 
            [corners[3][1] + round(Int,bottom_slope* dj), ## bottom slope
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
        @debug "Name: " * aa["name"]
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
    image_gray = Gray.(image)
    digit_pixels = image_tetragon_pixels(image_gray, corners)
    pixel_vector = float64.(vec(digit_pixels))
    pixel_res = kmeans(pixel_vector, 2)
    pixel_centers = vec(pixel_res.centers)
    fg_cluster, bg_cluster = argmin(pixel_centers), argmax(pixel_centers) ## fg is black:0, bg is white: 1
    @debug fg_cluster, bg_cluster
    pixel_std =  map( x-> std(pixel_vector[assignments(pixel_res) .== x]), (1,2))
    img_assignments = predict(image_gray, pixel_centers) ## assign cluster to full image based on local segmentation
    segments = digit_segments(corners)
    segment_counts = map(segments) do s
        segment_assignmets = image_region_pixels(img_assignments, s) ## todo? expand segment line to tetragon?
        res = DataFrame(segment = s.name, fg_count = sum(segment_assignmets .== fg_cluster), bg_count = sum(segment_assignmets .== bg_cluster), segment_size = size(segment_assignmets))
        transform!(res, [:fg_count, :bg_count] => ByRow((x,y) -> x>y ? "on" : "off") => "state")
        ## TODO: compute mean pixel-value of fg and bg pixels in this segment
        res
    end
    res = vcat(segment_counts...)
    insertcols!(res, :cluster_centers => Ref(sort(pixel_centers)))
    res
end

"""
    predict cluster assignment on new data
"""
function predict(image, centers)
    reshape(map(x -> argmin(abs.(x .- centers)), vec(image)), size(image))
end

"""
    SegmentedDisplay(path::String)
    Get Segment description from YAML file
"""
struct SegmentedDisplay
    display::DefaultDict{Any,Any,Missing}
    function SegmentedDisplay(display)
        @assert "display" ∈ keys(display)
        @assert all(["active_areas", "name", "viewing_area"] .∈ Ref(keys(display["display"])))
        new(display)
    end
end
SegmentedDisplay(path::String) = SegmentedDisplay(DefaultDict(missing,YAML.load_file(path)))

"""
    display_DataFrame(disp::SegmentedDisplay)
    Convert segment description to DataFrame
"""
function display_DataFrame(disp::SegmentedDisplay) ## DefaultDict trix to simulate rbind.fill
    res = DataFrame[]
    for display in values(disp.display)
        for area1 in values(display["active_areas"])
            area = DefaultDict(missing, area1)
            push!(res,
                  hcat(
                      DataFrame(display_name = display["name"], viewing_area = Tetragon(display["viewing_area"])),
                      DataFrame(area_name = area["name"],
                                type = area["type"],
                                tetragon=Tetragon(area["tetragon"]),
                                digits = area["digits"],
                                digit_width = area["digitwidth"],
                                segment_width = area["segmentwidth"],
                                ),
                      
                  )
                  )
        end
    end
    vcat(res...)
end

"""
    display_digit_tetragons
    Compute `Tetragon`s for all digits in all aresas in display
    Input can be ::SegmentedDisplay or DataFrame representation from `display_DataFrame`.
    Output: one row per digit.
"""
function display_digit_tetragons(dis::DataFrame)    
    combine(groupby(dis, [:display_name, :type, :area_name, :digits, :digit_width, :segment_width])) do df
        DataFrame(digit_number = 1:df.digits[1], digit_tetragon = area_digits_tetragons(df.tetragon[1], df.digits[1], df.digit_width[1]))
    end
end

display_digit_tetragons(dis::SegmentedDisplay) = display_digit_tetragons(display_DataFrame(dis))


"""
    Convert vector of segment states to encoded digit
"""
function decode_segments(states)
    segment_digits = DefaultDict(missing, Dict{Vector{String}, Union{Int64,Missing}}(
        ["on", "on", "on", "on", "on", "on", "off"] => 0,
        ["off", "on", "on", "off", "off", "off", "off"] => 1,
        ["on", "on", "off", "on", "on", "off", "on"] => 2,
        ["on", "on", "on", "on", "off", "off", "on"] => 3,
        ["off", "on", "on", "off", "off", "on", "on"] => 4,
        ["on", "off", "on", "on", "off", "on", "on"] => 5,
        ["on", "off", "on", "on", "on", "on", "on"] => 6,
        ["on", "on", "on", "off", "off", "off", "off"] => 7,
        ["on", "on", "on", "on", "on", "on", "on"] => 8,
        ["on", "on", "on", "on", "off", "on", "on"] => 9,
    ))
    segment_digits[states]
end

"""
    display_digit_values(image, dis)
    input: image and segmentation info (::SegmentedDisplay or DataFrame representation from `display_DataFrame`).
    output: DataFrame with one row per digit and decoded value in column `digit_value`
    TODO: decode decimal point
    TODO: decode icons. For this we need to communicat ethe cluster means from the digits (no digits are all off, but icons can be all off)
"""
function display_digit_values(image, dis)
    dis_digits = display_digit_tetragons(dis)
    res = DataFrame[]
    for row in eachrow(dis_digits)
        row.type == "7segment" || continue
        @debug row
        dig_df = digit_analysis(image, row.digit_tetragon)
        @debug dig_df
        digit_value = decode_segments(dig_df.state)
        state_string = replace(join(dig_df.state,""), "on" => "1", "off" => "0")
        @debug digit_value
        push!(res, hcat(DataFrame(row), allowmissing!(DataFrame(digit_value = digit_value, state = state_string))))
        ##  push!(res, hcat(DataFrame(row), DataFrame(digit_value = decode_segments(digit_analysis(image, row.digit_tetragon).state))); promote = true)
    end
    vcat(res...)
end


function area_decimalpoints(image, dis)
    ## decimal points are between digits
    ## 0 is black = fg, 1 is white = bg
    ## take max - min in lowest segment width
    ## take max - min in a segmentwidth 
end


function image_display_values(image, display)
    ## return DataFrame: one row per area wit hreadout value
    ## disdf = display_DataFrame(display)
    digit_values = display_digit_values(image,display) ## one row per digit
    decimal_values = image_display_decimal_DataFrame(image,display) ## one row per potential dicmalpoint
    digits = combine_digits(digit_values) ## one row per area
    decimals =  combine_decimals(decimal_values) ##  one row per area
    res = leftjoin(digits, decimals, on = :area_name)
    res = @transform(res, :int_val = something.(tryparse.(Int,:value),missing)) ## convert nothing to missing
    res = @transform(res, :result = :int_val ./ 10 .^:power)
    res
end

function image_display_decimal_DataFrame(image,display)
    decimal_values = DataFrame[]
    for aa in display.display["display"]["active_areas"]
        @debug "area_name: " * aa["name"]
        aa["type"] == "7segment" || continue
        aa_segments = area_decimal_segments(aa["tetragon"], aa["digits"], aa["digitwidth"], aa["segmentwidth"])
        res = segment_decimal_analysis(image, aa_segments)
        insertcols!(res, 1, :area_name => aa["name"])
        push!(decimal_values,res)
    end
    vcat(decimal_values...)
end

function combine_decimals(decimal_df)
    combine(groupby(decimal_df, :area_name)) do df
        res = @subset(df, :state .== "on")
        if nrow(res) == 0
            res = first(df,1)
            res.power = [0]
            res.state = ["none"]
        end
        if nrow(res) > 1
            res = first(res,1)
            res.power = [0]
            res.state = ["multiple"]
        end
        res
    end
end


function combine_digits(digit_df)
    # df = transform(df) # TODO convert missing to "_"
    @combine(groupby(digit_df, :area_name ), :value = join(:digit_value))
end
