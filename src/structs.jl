struct DigitCall
    digit_call_method::String
    segment_string::String ## 0: "1111110"
    digit_value::Int
    confidence::Float64
    method_result_dict::Dict
    method_result_df::DataFrame
end

mutable struct Digit
    tetragon::Tetragon
    segments::Vector{Segment}
    digit_calls::Vector{DigitCall}
end

struct DecimalCall
    decimal_call_method::String
    segment_string::String ## "0" or "1"
    decimal_value::Int
    confidence::Float64
end

mutable struct DecimalPoint
    segment::Segment
    decimal_calls::Vector{DecimalCall}
end


mutable struct DigitArea
    name::String
    tetragon::Tetragon
    digit_count::Int
    digit_width::Int
    segment_width::Int
    digits::Vector{Digit}
    decimal_points::Vector{DecimalPoint}
end

struct Display
    name::String
    viewing_area::Tetragon
    digit_areas::Vector{DigitArea}
    ## icon_areas::Vector{IconArea}
end


## Populate from yaml-file

function Display(path::String)
    display = YAML.load_file(path)
    digit_areas = DigitArea[]
    for aa in display["display"]["active_areas"]
        aa["type"] == "7segment" || continue
        push!(digit_areas, DigitArea(aa["name"],Tetragon(aa["tetragon"]), aa["digits"], aa["digitwidth"], aa["segmentwidth"], Digit[], DecimalPoint[]))
    end
    Display(display["display"]["name"], Tetragon(display["display"]["viewing_area"]), digit_areas)
end

