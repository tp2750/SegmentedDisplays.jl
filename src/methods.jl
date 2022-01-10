"""
    display_values(display::Display)
    Return DataFrame of called values: display, area, method, value, confidence
"""
function display_values(display)
    res = DataFrame[]
    for area in display.digit_areas
        for method in digit_call_methods(area)
            ## TODO: combinedigits found by this method
        end
    end
end

"""
    digit_call_methods(area::DigitArea)
    return vector of digit_call_methods appied to area
"""
function digit_call_methods(area)
    methods = String[]
    for digit in area.digits
        for call in digit.digit_calls
            push!(methods, call.digit_call_method)
        end
    end
    unique(methods)
end


"""
    digits!(display::Display, image; kw)
    Update display with digit-calls using method given by kw
    kwds:
        method:
            "2means": k-means finds fg and bg
            "2point": difference between single points
"""
function display_digits!(display, image; method="2means")
    digit_tetragons!(display) ## Make sure tetragons are defined
    if method == "2means"
        digit_values_2means!(display, image)
    end
end

"""
    digit_values_2means!(display,image)
    Add digit calls based on k-means fg and bg
"""
function digit_values_2means!(display,image)
    for area in display.digit_areas        
        for digit in area.digits
            methods = map(x -> x.digit_call_method, digit.digit_calls)
            if "2means" ∈ methods
                called_value = digit.digit_calls[findfirst("2means"  ∈methods)].digit_value
                @info "digit already called by 2means: $(called_value). Skipping"
                continue
            end
            digit_df = digit_analysis(image, digit.tetragon, area.segment_width)
            push!(digit.digit_calls,
                  DigitCall("2means",
                            replace(join(digit_df.state,""), "on" => "1", "off" => "0"),
                            decode_segments(digit_df.state),
                            digit_df.cluster_centers[1][2] - digit_df.cluster_centers[1][1], ## confidence: disance between centers
                            Dict("cluster_centers" => digit_df.cluster_centers[1], "fg_count" => digit_df.fg_count, "bg_count" => digit_df.bg_count, "state"=> digit_df.state),
                            digit_df,
                            )
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
            @info "We already have $(length(aa.digits)) digits in $(aa.name). Skipping"
            continue
        end
        digit_tetragons = area_digits_tetragons(aa.tetragon, aa.digit_count, aa.digit_width) ## Vector{Tetragon}
        digits = Digit[]
        for digit in digit_tetragons
            push!(digits, Digit(digit, digit_segments(digit), DigitCall[]))
        end
        aa.digits = digits
    end    
end
