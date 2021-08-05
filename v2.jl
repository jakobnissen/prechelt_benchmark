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

function loadDictionary(file)
    dict = sizehint!(Dict{UInt256, Union{Tuple{String}, Vector{String}}}(), 1000)
    for word in eachline(file)
        num = word_to_number(word)
        existing = get(dict, num, nothing)
        if existing === nothing
            dict[num] = (word,)
        elseif existing isa Tuple
            dict[num] = push!([existing[1]], word)
        else
            push!(existing, word)
        end
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
        print(io, num, ": ")
        for word in words
            print(io, word, ' ')
        end
        print(io, '\n')
        return nothing
    end
    foundWord = false
    n = UInt256(1)
    for i in start:ncodeunits(digits)
        n = n * 10 + nthDigit(digits, i)
        for word in get(dict, n, emptyStrings)
            foundWord = true
            push!(words, word)
            printTranslations(io, num, digits, dict, i + 1, words)
            pop!(words)
        end
    end
    if (
        !foundWord &&
        !(!isempty(words) &&
        ncodeunits(words[end]) == 1 &&
        isdigit(words[end][begin]))
    )
        words2 = push!(copy(words), string(nthDigit(digits, start)))
        printTranslations(io, num, digits, dict, start + 1, words2)
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

function validate()
    buf = IOBuffer()
    @time main(buf, "../prechelt-phone-number-encoding/dictionary.txt", "../prechelt-phone-number-encoding/input.txt")
    v = take!(buf)
    v2 = open(read, "/tmp/res.txt")
    return v == v2
end

function time()
    main(IOBuffer(), "../prechelt-phone-number-encoding/dictionary.txt", "../prechelt-phone-number-encoding/input.txt")
end

end # module