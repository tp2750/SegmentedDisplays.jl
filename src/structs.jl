struct DigitCall
    digit_call_method::String
    segment_string::String ## 0: "1111110"
    digit_value::Union{Int, Missing}
    confidence::Float64
    method_result_dict::Dict
    method_result_df::DataFrame
end

mutable struct Digit
    tetragon::Tetragon
    segments::Vector{Segment}
    digit_call::Union{DigitCall,Missing}
end

# struct DecimalCall
#     decimal_call_method::String
#     segment_string::String ## "0" or "1"
#     decimal_value::Int
#     confidence::Float64
# end

# mutable struct DecimalPoint
#     segment::Segment
#     decimal_call::Union{DecimalCall,Missing}
# end


mutable struct DigitArea
    name::String
    tetragon::Tetragon
    digit_count::Int
    digit_width::Int
    segment_width::Int
    digits::Vector{Digit}
    decimal_df::DataFrame
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
        push!(digit_areas, DigitArea(aa["name"],Tetragon(aa["tetragon"]), aa["digits"], aa["digitwidth"], aa["segmentwidth"], Digit[], DataFrame()))
    end
    dis = Display(display["display"]["name"], Tetragon(display["display"]["viewing_area"]), digit_areas)
    digit_tetragons!(dis) ## Make sure tetragons are defined
    dis
end

