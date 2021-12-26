function tetragon_trace(tetragon) ## using in  segmentation_overlay!
    @assert length(tetragon) == 4
    [ImageDraw.LineSegment(CartesianIndex(tetragon[1]...), CartesianIndex(tetragon[2]...)),
     ImageDraw.LineSegment(CartesianIndex(tetragon[2]...), CartesianIndex(tetragon[3]...)),
     ImageDraw.LineSegment(CartesianIndex(tetragon[3]...), CartesianIndex(tetragon[4]...)),
     ImageDraw.LineSegment(CartesianIndex(tetragon[4]...), CartesianIndex(tetragon[1]...)),
     ]
end

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
