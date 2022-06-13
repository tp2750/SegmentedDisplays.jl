function simulate(val, corners, seg_width, dig_width, dig_sep; n_digits=9)
    bg = 1.
    c1 = corners
    dj = max(c1[1][2] - c1[2][2], c1[4][2] - c1[3][2])+1
    di = max(c1[4][1] - c1[1][1], c1[3][1] - c1[2][1])+1
    @info "di: $di, dj: $dj"
    img = Gray.(reshape(ones(Float64,di*dj),di, dj))
    offset = [1,1]
    for dig in reverse(digits(val, pad=n_digits))
        @info dig
        render_digit!(img, dig, offset, seg_width, dig_width)
        offset += [0, dig_width + dig_sep]
    end
    img
end

function render_digit!(img, dig, anc, seg_width, dig_width) ## render digit on image at anc (top-left)
    dig_segs = digits_segments[dig]
    if dig_segs[1] == "on"
        render_segment!(img, anc, seg_width, dig_width)
    end
    if dig_segs[2] == "on"
        render_segment!(img, anc+[0,dig_width-seg_width], dig_width, seg_width, fg = 0.)
    end
    if dig_segs[3] == "on"
        render_segment!(img, anc+[dig_width, dig_width-seg_width], dig_width, seg_width, fg = 0.)
    end
    if dig_segs[4] == "on"
        render_segment!(img, anc+[2*dig_width-seg_width,0], seg_width, dig_width, fg = 0.)
    end
    if dig_segs[5] == "on"
        render_segment!(img, anc+[dig_width,0], dig_width, seg_width, fg = 0.)
    end
    if dig_segs[6] == "on"
        render_segment!(img, anc , dig_width, seg_width, fg = 0.)
    end
    if dig_segs[7] == "on"
        render_segment!(img, anc +[dig_width - Int(ceil(seg_width/2)),0], seg_width, dig_width, fg = 0.)
    end    
end

function render_segment!(img, x0, di, dj; fg = 0.)
    for i in x0[1] .+ (0:di) 
        for j in x0[2] .+ (0:dj)
            img[i,j] = Gray(fg)
        end
    end    
end



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
));

digits_segments = Dict{Int, Vector{String}}(
    0 => ["on", "on", "on", "on", "on", "on", "off"] ,
    1 => ["off", "on", "on", "off", "off", "off", "off"],
    2 => ["on", "on", "off", "on", "on", "off", "on"] ,
    3 => ["on", "on", "on", "on", "off", "off", "on"] ,
    4 => ["off", "on", "on", "off", "off", "on", "on"],
    5 => ["on", "off", "on", "on", "off", "on", "on"],
    6 => ["on", "off", "on", "on", "on", "on", "on"],
    7 => ["on", "on", "on", "off", "off", "off", "off"], 
    8 => ["on", "on", "on", "on", "on", "on", "on"],
    9 => ["on", "on", "on", "on", "off", "on", "on"],
);
