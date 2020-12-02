# Function to convert image pixels into quilt quarter squares, called
# quilt-pixel or quixels

# Note: left = 1, right = 2, top = 3, bottom = 4, border = 5

using StatsBase

# TODO: enable half and quarter squares
struct Quixel
    color
    length::Int64
end

function quixel_indices(a::Array{T, 2}) where T

    if size(a)[1] != size(a)[2] 
        error("Array must be square to find quixel indices!")
    end

    array_length = size(a)[1]
    offset = 0
    if isodd(array_length)
        offset += 1
    end
    index_num = sum(offset:2:array_length)

    left_indices = zeros(Int, index_num)
    right_indices = zeros(Int, index_num)
    top_indices = zeros(Int, index_num)
    bottom_indices = zeros(Int, index_num)

    border_indices = zeros(Int, 2*array_length)

    left_count = 1
    right_count = 1
    top_count = 1
    bottom_count = 1
    border_count = 1

    for i = 1:size(a)[1]
        for j = 1:size(a)[2]

            # negative diagonal
            if j == i
                border_indices[border_count] = j + array_length*(i-1)
                border_count += 1
            end

            # positive diagonal
            if j == array_length - i + 1
                border_indices[border_count] = j + array_length*(i-1)
                border_count += 1
            end

            # top element
            if j >= i && j >= array_length - i + 1
                top_indices[top_count] = j + array_length*(i-1)
                top_count += 1
            end
            
            # bottom element
            if j <= i && j <= array_length - i + 1
                bottom_indices[bottom_count] = j + array_length*(i-1)
                bottom_count += 1
            end
            
            # left element
            if j >= i && j <= array_length - i + 1
                left_indices[left_count] = j + array_length*(i-1)
                left_count += 1
            end
            
            # right element
            if j <= i && j >= array_length - i + 1
                right_indices[right_count] = j + array_length*(i-1)
                right_count += 1
            end
            
        end
    end

    return left_indices, right_indices, top_indices,
           bottom_indices, border_indices
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
            indices = quixel_indices(out[1+(i-1)*quixel_length:i*quixel_length,
                                         1+(j-1)*quixel_length:j*quixel_length])

            for k = 1:5
                indices[k][:] .+= 1+(j-1)*quixel_length+
                                  ((i-1)*quixel_length)*size(out)[1]

                out[indices[k]] .= quixels[i,j].color[k]
            end

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

    colors = [RGB(0,0,0) for i = 1:5]

    for i = 1:size(quixels)[1]
        for j = 1:size(quixels)[2]
            indices = quixel_indices(img[1+(i-1)*quixel_length:i*quixel_length,
                                         1+(j-1)*quixel_length:j*quixel_length])
            colors[1] = mode(img[indices[1]])
            colors[2] = mode(img[indices[2]])
            colors[3] = mode(img[indices[3]])
            colors[4] = mode(img[indices[4]])

            # Border color is black
            colors[5] = RGB(0)

            quixels[i,j] = Quixel(colors, quixel_length)
        end
    end

    return quixel_to_img(quixels)
end
