"""
    display_values(display::Display)
    Return DataFrame of called values: display, area, method, value, confidence
"""
function display_values(display)
    ## Similar to segment.jl:image_display_values
    res = DataFrame[]
    for area in display.digit_areas
        digit_values = display_digits(area) ## one row per digit
        decimal_values = area.decimal_df ## one row per potential dicmalpoint
        digits = combine_digits(digit_values) ## one row per area
        decimals =  combine_decimals(decimal_values) ##  one row per area
        push!(res, leftjoin(digits, decimals, on = :area_name))
    end
    res = reduce(vcat, res)
    res = @transform(res, :int_val = something.(tryparse.(Int,:value),missing)) ## convert nothing to missing
    res = @transform(res, :result = :int_val ./ 10 .^:power)
    res
end

"""
    digit_values_2means!(display,image)
    Add digit calls based on k-means fg and bg
"""
function digit_values_2means!(display,image;force=false)
    for area in display.digit_areas        
        for digit in area.digits
            if !ismissing(digit.digit_call) & !force
                @info "digit_values_2means! found call: $(digit.digit_call.digit_value) (method: $(digit.digit_call.digit_call_method) area: $(area.name)). Skipping"
                continue
            end
            digit_df = digit_analysis(image, digit.tetragon, area.segment_width)
            digit.digit_call = DigitCall("2means",
                      replace(join(digit_df.state,""), "on" => "1", "off" => "0"),
                      decode_segments(digit_df.state),
                      digit_df.cluster_centers[1][2] - digit_df.cluster_centers[1][1], ## confidence: disance between centers
                      Dict("cluster_centers" => digit_df.cluster_centers[1], "fg_count" => digit_df.fg_count, "bg_count" => digit_df.bg_count, "state"=> digit_df.state),
                      digit_df,
                      )
        end
    end
end

"""
    digit_tetragons!(display::Display)
    Update display with digit tetragons
    Used by digits!, We should not need to call this explicitly
"""
function digit_tetragons!(display; force=false)
    ## if we have tegragons, do nothing, unless force
    for aa in display.digit_areas
        if length(aa.digits) > 0 & (!force)
            @info "digit_tetragons!: $(length(aa.digits)) digits defined in $(aa.name). Skipping"
            continue
        end
        digit_tetragons = area_digits_tetragons(aa.tetragon, aa.digit_count, aa.digit_width) ## Vector{Tetragon}
        digits = Digit[]
        for digit in digit_tetragons
            push!(digits, Digit(digit, digit_segments(digit), missing))
        end
        aa.digits = digits
    end    
end

"""
    display_call_digits!(display::Display, image; kw)
    Update display with digit-calls using method given by kw
    kwds:
        method:
            "2means": k-means finds fg and bg
            "2point": difference between single points
"""
function display_call_digits!(display, image; method="2means")
    digit_tetragons!(display) ## Make sure tetragons are defined
    if method == "2means"
        digit_values_2means!(display, image)
    end
    ## Call decmals    
    for area in display.digit_areas
        area_segments = area_decimal_segments(area.tetragon.corners, area.digit_count, area.digit_width, area.segment_width)
        res = segment_decimal_analysis(image, area_segments)
        res.area_name .= area.name
        area.decimal_df = res
    end
end

"""
    display_digits(display)
    Input: a Display wher edigis are called with display_call_digits!()
    Output: DataFrame with one row per digit
"""
function display_digits(display::Display)    
    res = DataFrame[]
    for area in display.digit_areas        
        part = display_digits(area)
        push!(res, part)
        # end
    end
    if length(res) == 0
        @warn "No digits found. Call display_call_digits!() first"
    end
    res = reduce(vcat, res) ## vcat(res...)
    res.display_name .= display.name
    res
end

function display_digits(area::DigitArea)    
    res = DataFrame[]
    digitnumber = 0
    for digit in area.digits
        digitnumber += 1
        part = DataFrame(digit_number = digitnumber,
                         digit_value = digit.digit_call.digit_value,
                         digit_call_method = digit.digit_call.digit_call_method,
                         digit_call_confidence = digit.digit_call.confidence,
                         digit_segment_string = digit.digit_call.segment_string,
                         )
        push!(res, part)
    end
    res = reduce(vcat, res) ## vcat(res...)
    res.area_name .= area.name
    res
end


"""
    display_segments(display)
    Input: display with digits called
"""
function display_segments(display)
    ## similar to display_digit_values(image, dis) is segment.jl    
    res = DataFrame[]
    for area in display.digit_areas
        digitnumber = 0
        for digit in area.digits
            digitnumber += 1
            part = digit.digit_call.method_result_df
            part.area_name .= area.name
            part.digit_number .= digitnumber
            part.digit_call_method .= digit.digit_call.digit_call_method
            part.display .= display.name
            push!(res, part)
        end
    end
    if length(res) == 0
        @warn "No digits found. Call display_call_digits!() first"
    end
    reduce(vcat, res) ## vcat(res...)
end

function image_display_decimal_DataFrame(area::DigitArea, image)
    ## OBS almost same as segment.jl:image_display_decimal_DataFrame(image,display), but signature reversed to dispatch
    decimal_values = DataFrame[]
    for aa in area
        aa_segments = area_decimal_segments(aa.tetragon.corners, aa.digit_count, aa.digit_width, aa.segment_width)
        res = segment_decimal_analysis(image, aa_segments)
        insertcols!(res, 1, :area_name => aa.name)
        push!(decimal_values,res)
    end
    vcat(decimal_values...)
end

"""
    draw_areas(image, display)
    Draw the view area and active areas on the image.
    Usage: imshow(draw_areas(image, display))
"""
function draw_areas(image, display; color=RGB{N0f8}(0,1,0))
    ## TODO better color names
    ## TODO Add icon areas
    tetragons = Tetragon[]
    push!(tetragons, display.viewing_area)
    for area in display.digit_areas
        push!(tetragons, area.tetragon)
    end
    draw(image, tetragon_trace(tetragons), color)
end

"""
    draw_digits(image, display)
    Draw the Tetragons of the digits on the image
    Usage: imshow(draw_digits(image, display))
"""
function draw_digits(image, display; color = RGB{N0f8}(0,1,0))
    ## TODO better color names
    ## TODO Add icon areas
    tetragons = Tetragon[]
    for area in display.digit_areas
        for digit in area.digits
            push!(tetragons, digit.tetragon)
        end
    end
    draw(image, tetragon_trace(tetragons), color)
end

function draw_segments(image, display; color = RGB{N0f8}(0,0,1))
    segments = Segment[]
    for area in display.digit_areas
        for digit in area.digits
            for segment in digit.segments
                push!(segments, segment)
            end
        end
    end
    draw(image, LineSegments(segments), color)
end
