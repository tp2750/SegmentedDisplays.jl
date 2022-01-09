"""
    CV in percent: standard deviation relative to mean in %
"""
cv_pct(x) = 100. *Statistics.std(x)/Statistics.mean(x)

"""
    subtract running median from image
"""
function normalize_image(image, window=42)
    @assert mod(window,2)==0
    img = Float64.(Gray.(image)) ## works on Gray.(image)
    hw = Int(window/2)
    img2 = copy(img)
    for line in 1:size(img)[1]
        dat1 = RollingFunctions.rollmedian(img[line,:], window)
        img2[line,:] = vcat(zeros(Float64,hw), img[line,hw+1:end-hw+1] .- dat1, zeros(Float64,hw-1))
    end
    Gray.(img2) ## Todo convert to N0f8
end
