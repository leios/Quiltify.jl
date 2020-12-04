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

    left_indices = Vector{CartesianIndex{2}}(undef, index_num)
    right_indices = Vector{CartesianIndex{2}}(undef, index_num)
    top_indices = Vector{CartesianIndex{2}}(undef, index_num)
    bottom_indices = Vector{CartesianIndex{2}}(undef, index_num)

    border_indices = Vector{CartesianIndex{2}}(undef, 2*array_length)

    left_count = 1
    right_count = 1
    top_count = 1
    bottom_count = 1
    border_count = 1

    for i = 1:size(a)[1]
        for j = 1:size(a)[2]

            # negative diagonal
            if j == i
                border_indices[border_count] = CartesianIndex(j,i)
                border_count += 1
            end

            # positive diagonal
            if j == array_length - i + 1
                border_indices[border_count] = CartesianIndex(j,i)
                border_count += 1
            end

            # top element
            if j >= i && j >= array_length - i + 1
                top_indices[top_count] = CartesianIndex(j,i)
                top_count += 1
            end
            
            # bottom element
            if j <= i && j <= array_length - i + 1
                bottom_indices[bottom_count] = CartesianIndex(j,i)
                bottom_count += 1
            end
            
            # left element
            if j >= i && j <= array_length - i + 1
                left_indices[left_count] = CartesianIndex(j,i)
                left_count += 1
            end
            
            # right element
            if j <= i && j >= array_length - i + 1
                right_indices[right_count] = CartesianIndex(j,i)
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

    for i = 1:size(quixels)[2]
        for j = 1:size(quixels)[1]
            indices = quixel_indices(out[1+(j-1)*quixel_length:j*quixel_length,
                                         1+(i-1)*quixel_length:i*quixel_length])

            for k = 1:5
                for l = 1:length(indices[k])
                    indices[k][l] += CartesianIndex((j-1)*quixel_length,
                                                    (i-1)*quixel_length)
                end

                out[indices[k]] .= quixels[j,i].color[k]
            end

            # Draw black border around quixels
            out[1+(j-1)*quixel_length : j*quixel_length,
                1+(i-1)*quixel_length] .= RGB(0)
            out[1+(j-1)*quixel_length,
                1+(i-1)*quixel_length : i*quixel_length] .= RGB(0)
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

    for i = 1:size(quixels)[2]
        for j = 1:size(quixels)[1]

            starty = offsety+1+(j-1)*quixel_length
            endy = offsety+j*quixel_length

            startx = offsetx+1+(i-1)*quixel_length
            endx = offsetx+i*quixel_length

            indices = quixel_indices(img[starty:endy, startx:endx])

            for k = 1:4
                for l = 1:length(indices[k])
                    indices[k][l] += CartesianIndex((j-1)*quixel_length,
                                                    (i-1)*quixel_length)
                end

                colors[k] = mode(img[indices[k]])
            end

            # Border color is black
            colors[5] = RGB(0)

            quixels[j,i] = Quixel(copy(colors), quixel_length)
        end
    end

    return quixel_to_img(quixels)
end
