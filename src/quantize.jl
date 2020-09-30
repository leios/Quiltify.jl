# TODO: quantization may fail if no colors for a box
# TODO: take N most populated boxes
# TODO: HSV colorspace?
using DataStructures

mutable struct ColorBox
    clr::Union{RGB, Nothing}
    children::Vector{ColorBox}
    n::Int
    extents
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

# Small improvements could be made bu only iterating through elements of the
# parent node
function naive_bin!(img, box::ColorBox)
    box.n = 0

    for pixel in img
        if in_box(pixel, box)
            if box.clr == nothing
                box.clr = RGB(0.0)
            end
            box.n += 1
            box.clr += pixel
        end
    end

    if box.clr != nothing
        box.clr /= box.n
    end
end

function divide_octree!(img, box::ColorBox, level::Int, max_level::Int)
    println(level)
    if level >= max_level || box.n <= 1
        return
    end

    # Initializing all child boxes as parent box
    children = [ColorBox(nothing,[],0,0) for i=1:8]
    box.children = children

    # Creating new extents and mean for each child box
    for i = 1:2, j = 1:2, k = 1:2
        index = k + 2*(j-1) + 4*(i-1)
        children[index].extents = (find_extents(box.extents[1],i),
                                   find_extents(box.extents[2],j),
                                   find_extents(box.extents[3],k))
        naive_bin!(img, children[index])
        println(children[index].clr)
        divide_octree!(img, children[index], level+1, max_level)
    end

    return box
end

function make_octree(img, max_level)

    # Creation of the initial octree box
    box = ColorBox(sum(img)/(length(img)), [], length(img),
                   ((0.0, 1.0),(0.0, 1.0),(0.0, 1.0)))

    divide_octree!(img, box, 1, max_level)

end

function find_color_set!(colorset, box, color_num)
    q = PriorityQueue(Base.Order.Reverse)
    println(typeof(box))
    enqueue!(q, box, box.n)

    index = 1

    while length(q) > 0 && index <= color_num
        temp = dequeue!(q)
        if temp.clr != nothing
            colorset[index] = temp.clr
            index += 1
        end
        for child in temp.children
            enqueue!(q, child, child.n)
        end
    end
end

function color_distance(color1, color2)
    return sqrt((color1.r - color2.r)^2 +
                (color1.g - color2.g)^2 +
                (color1.b - color2.b)^2)
end

function quantize(img, colornum)
    img_out = copy(img)
    max_level = ceil(Int, log2(colornum - 1)/log2(8))+1
    println(max_level)
    box = make_octree(img, max_level)

    colorset = [RGB(0.0, 0.0, 0.0) for i = 1:colornum]
    find_color_set!(colorset, box, colornum)

    for i in 1:length(img_out)
        distances = color_distance.(colorset, img_out[i])
        _, min_element = findmin(distances)
        img_out[i] = colorset[min_element]
    end

    return img_out
end
