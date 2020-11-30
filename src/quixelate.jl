# Function to convert image pixels into quilt quarter squares, called
# quilt-pixel or quixels

using StatsBase

# TODO: enable half and quarter squares
struct Quixel
    color::Union{Vector{RGB}, RGB}
    length::Int64
end

function quixel_to_rgb(q::Quixel)
    out = Array{RGB,2}(undef, q.length, q.length)

    out[:] .= q.color

    return out
end

function quixel_to_img(quixels::Array{Quixel, 2})
    quixel_length = quixels[1].length
    out = Array{RGB,2}(undef, quixel_length*size(quixels)[1],
                       quixel_length*size(quixels)[2])

    for i = 1:length(out)
        out[i] = RGB(0)
    end

    for i = 1:size(quixels)[1]
        for j = 1:size(quixels)[2]
            out[1+(i-1)*quixel_length : i*quixel_length,
                1+(j-1)*quixel_length : j*quixel_length] = 
                    quixel_to_rgb(quixels[i,j])

            # Draw black border around quixels
            out[1+(i-1)*quixel_length : i*quixel_length,
                1+(j-1)*quixel_length] .= RGB(0)
            out[1+(i-1)*quixel_length,
                1+(j-1)*quixel_length : j*quixel_length] .= RGB(0)
        end
    end

    return out
end

function quixelate(img, quixel_length; average_method=:mode)

    quixels = Array{Quixel, 2}(undef, floor(Int, size(img)[1]/quixel_length),
                               floor(Int, size(img)[2]/quixel_length))

    offsety = floor(Int, size(img)[1]%quixel_length/2)
    offsetx = floor(Int, size(img)[2]%quixel_length/2)

    for i = 1:size(quixels)[1]
        for j = 1:size(quixels)[2]
            color = mode(img[1+(i-1)*quixel_length : i*quixel_length,
                             1+(j-1)*quixel_length : j*quixel_length])

            if color == RGB(0)
                println(i,j)
            end

            quixels[i,j] = Quixel(color, quixel_length)
        end
    end

    return quixel_to_img(quixels)
end
