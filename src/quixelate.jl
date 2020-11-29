# Function to convert image pixels into quilt quarter squares, called
# quilt-pixel or quixels

using StatsBase

@enum Quixel_type full half quarter

# TODO: enable half and quarter squares
mutable struct Quixel
    type::Quixel_type
    color::Union{RGB, Nothing}
    length::Int64
end

function quixelate(img, quixel_size; average_method=:mode)

    out = Array{RGB}(undef, size(img)[1] - size(img)[1]%quixel_size,
                     size(img)[2] - size(img)[2]%quixel_size)
    for i = 1:length(out)
        out[i] = RGB(0)
    end 

    offsety = floor(Int, size(img)[1]%quixel_size/2)
    offsetx = floor(Int, size(img)[2]%quixel_size/2)

    println(size(out), '\t', size(img), '\t', offsetx, '\t', offsety)

    for i = offsety+quixel_size:quixel_size:size(img)[1]
        for j = offsetx+quixel_size:quixel_size:size(img)[2]
            #println(i, '\t', j)
            color = mode(img[1+i - quixel_size:i, 1+j-quixel_size:j])
            out[1+i-offsety-quixel_size:i-offsety,
                1+j-offsetx-quixel_size:j-offsetx] .= color
        end
    end

    return out
end
