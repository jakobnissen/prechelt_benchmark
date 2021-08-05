#=
# Port of Peter Norvig's Common Lisp program from http://norvig.com/java-lisp.html.
#
# - Julia version: 1.6.2
# - Author: Renato Athaydes
# - Mofified by: Jakob Nissen
# - Date: 2021-07-24
=#
module t

using BitIntegers

const emptyStrings = String[]

const DIGIT_LUT = let
    arr = fill(0xff, 128)
    for (n, letters) in enumerate([
        ('e',),
        ('j', 'n', 'q'),
        ('r', 'w', 'x'),
        ('d', 's', 'y'),
        ('f', 't'),
        ('a', 'm'),
        ('c', 'i', 'v'),
        ('b', 'k', 'u'),
        ('l', 'o', 'p'),
        ('g', 'h', 'z'),
    ]), letter in letters
        arr[UInt8(letter) + 0x01] = n - 1
        arr[UInt8(uppercase(letter)) + 0x01] = n - 1
    end
    Tuple(arr)
end

function loadDictionary(file)::Dict{UInt256, Vector{String}}
    dict = sizehint!(Dict{UInt256, Vector{String}}(), 1000)
    for word in eachline(file)
        push!(get!(dict, word_to_number(word)) do; String[] end, word)
    end
    dict
end

function word_to_number(word::Union{String, SubString{String}})
    result = UInt256(1)
    for b in codeunits(word)
        if (b < 0x80) & ((b in UInt8('A'):UInt8('Z')) | (b in UInt8('a'):UInt8('z')))
            result = result * 10 + byte_to_digit(b)
        end
    end
    return result
end

function byte_to_digit(b::UInt8)
    n = @inbounds DIGIT_LUT[b + 0x01]
    n == 0xff && error("Not a letter")
    return n
end

function printTranslations(io, num, digits, dict, start=1, words=String[])
    if start > ncodeunits(digits)
       return println(io, num, ": ", join(words, " "))
    end
    foundWord = false
    n = BigInt(1)
    for i in start:ncodeunits(digits)
        n = n * 10 + nthDigit(digits, i)
        for word in get(dict, n, emptyStrings)
            foundWord = true
            printTranslations(io, num, digits, dict, i + 1, [words; word])
        end
    end
    if !foundWord &&
        !(!isempty(words) && ncodeunits(words[end]) == 1 && isdigit(words[end][begin]))
        printTranslations(io, num, digits, dict, start + 1, [words; string(nthDigit(digits, start))])
    end
end

function nthDigit(digits::String, i::Int64)::UInt
    codeunit(digits, i) - UInt8('0')
end

function main(io::IO, p1, p2)
    dict = open(p1) do file
        loadDictionary(file)
    end

    open(p2) do file
        d = dict
        for num in eachline(file)
            printTranslations(io, num, filter(isdigit, num), d)
        end
    end
end

end # module