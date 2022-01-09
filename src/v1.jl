
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
