# TODO: quantization may fail if no colors for a box
# TODO: Some boxes return negative mean colors
# TODO: All colors are the same in the color set

mutable struct ColorBox
    clr::Union{RGB, Nothing}
    children::Vector{ColorBox}
    extents
end

function bin_pixels(img, box::ColorBox)
end

function find_extents(prev_extents, i::Int)
    if i == 1
        return (prev_extents[1], sum(prev_extents)/2)
    elseif i == 2
        return (sum(prev_extents)/2, prev_extents[2])
    else
        error("Index ", i, " not found for box creation!")
    end
end

function in_box(pixel, box)
    if pixel.r > box.extents[1][1] && pixel.r < box.extents[1][2] &&
       pixel.g > box.extents[2][1] && pixel.g < box.extents[2][2] &&
       pixel.b > box.extents[3][1] && pixel.b < box.extents[3][2]
        return true
    else
        return false
    end
end

# Inefficient function to determine quantizeable colors
function naive_bin!(img, box)
    count = 0.0

    for pixel in img
        if in_box(pixel, box)
            if box.clr == nothing
                box.clr = RGB(0.0)
            end
            count += 1
            box.clr += pixel
        end
    end

    if box.clr != nothing
        box.clr /= count
    end
end

function divide_octree!(img, box::ColorBox, level::Int, max_level::Int)
    if level >= max_level
        return
    end

    # Initializing all child boxes as parent box
    children = [ColorBox(nothing,[],0) for i=1:8]
    box.children = children

    # Creating new extents and mean for each child box
    for i = 1:2, j = 1:2, k = 1:2
        index = k + 2*(j-1) + 4*(i-1)
        children[index].extents = (find_extents(box.extents[1],i),
                                   find_extents(box.extents[2],j),
                                   find_extents(box.extents[3],k))
        naive_bin!(img, children[index])
    end

    return box
end

function make_octree(img)

    # Creation of the initial octree box
    box = ColorBox(sum(img)/(length(img)), [],
                   ((0.0, 1.0),(0.0, 1.0),(0.0, 1.0)))

    divide_octree!(img, box, 1, 3)

end

# TODO: to be BFS instead of DFS
function find_color_set(colorset, box, index, color_num)

    if index[1] >= color_num
        return
    end

    if box.clr != nothing
        colorset[index[1]] = box.clr
        index[1] += 1
    end
    for child in box.children
        find_color_set(colorset, box, index, color_num)
    end
end

function color_distance(color1, color2)
    return sqrt((color1.r - color2.r)^2 +
                (color1.g - color2.g)^2 +
                (color1.b - color2.b)^2)
end

function quantize(img, colornum)
    img_out = copy(img)
    box = make_octree(img)

    colorset = [RGB(0.0, 0.0, 0.0) for i = 1:colornum]
    find_color_set(colorset, box, [1], colornum)
    println(colorset)

    for i in 1:length(img_out)
        distances = color_distance.(colorset, img_out[i])
        _, min_element = findmin(distances)
        #println(i, '\t', min_element, '\t', sum(distances))
        img_out[i] = colorset[min_element]
    end

    return img_out
end
