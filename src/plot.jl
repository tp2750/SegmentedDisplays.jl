"""
    remove_background(line, window)
    line: vector of grey-scale pixels
    window: size of window to compute median over

    Subtracts median over window and pads with zeros to restore length)
    This is used to correct for light imbalance.
"""
function remove_background(line, window)
    @assert mod(window,2) == 0
    v1 = Float64.(line) ## works on Gray.(image)
    m1 = RollingFunctions.rollmedian(v1, window)
    hw = Int(window/2)
    vcat(zeros(Float64,hw), v1[hw:end-hw] .- m1, zeros(Float64,hw))
end

"""
    segment_dashboard(image, window, line, line2=missing)
    image: Gray-scale image (from Gray.(image))
    line: horizontal pixel-line to extract
    line2: vertical pixel-line to indicate on plots

    kw arguments:
    window: width of window for `remove_background` (default: 42). Must be even.

    Used to analyze a line of an image to find segment elements.
    Performs a background correction based on windowed median.
    For a 1600 pixel image with 9 digits, as window of 42 is good.
"""
function segment_dashboard(image, line, line2=missing; window=42) 
    @assert mod(window,2) == 0
    img = Float64.(image) ## works on Gray.(image)
    dat1 = RollingFunctions.rollmedian(img[line,:], window)
    hw = Int(window/2)
    dat2 = vcat(zeros(Float64,hw), img[line,hw:end-hw] .- dat1, zeros(Float64,hw))
    plot(vline!(plot(img[line,:], label="h:$line"), [line2], label="v:$line2"),
         vline!(hline!(plot(image), [line], label="h:$line"), [line2], label="v:$line2"),
         vline!(plot(dat1, label="rollmedian($window)"),[line2]),
         vline!(plot(dat2, label="corrected"), [line2], label="v:$line2"),
         layout=(2,2)
         )
end
