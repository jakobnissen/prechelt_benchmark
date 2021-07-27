#=
# Port of Peter Norvig's Common Lisp program from http://norvig.com/java-lisp.html.
#
# - Julia version: 1.6.2
# - Author: Renato Athaydes
# - Mofified by: Jakob Nissen
# - Date: 2021-07-24
=#
const emptyStrings = String[]

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

function loadDictionary(file)::Dict{BigInt, Vector{String}}
    local dict = Dict{BigInt, Vector{String}}()
    for word in eachline(file)
        push!(get!(dict, wordToNumber(word)) do; String[] end, word)
    end
    dict
end

function nthDigit(digits::String, i::Int64)::UInt
    codeunit(digits, i) - UInt8('0')
end

function charToDigit(ch)
    ch = lowercase(ch)
    ch == 'e' && return 0
    ch in ('j', 'n', 'q') && return 1
    ch in ('r', 'w', 'x') && return 2
    ch in ('d', 's', 'y') && return 3
    ch in ('f', 't') && return 4
    ch in ('a', 'm') && return 5
    ch in ('c', 'i', 'v') && return 6
    ch in ('b', 'k', 'u') && return 7
    ch in ('l', 'o', 'p') && return 8
    ch in ('g', 'h', 'z') && return 9
    throw(DomainError(ch, "Not a letter"))
end

function wordToNumber(word::String)::BigInt
    buf = IOBuffer()
    print(buf, '1')
    for ch in word
        if isascii(ch) && isletter(ch)
            print(buf, Char(charToDigit(ch)) + Int('0'))
        end
    end
    parse(BigInt, String(take!(buf)))
end

function main(io::IO)
    dict = open(isempty(ARGS) ? "dictionary.txt" : ARGS[begin]) do file
        loadDictionary(file)
    end

    open(length(ARGS) < 2 ? "input.txt" : ARGS[begin+1]) do file
        d = dict
        for num in eachline(file)
            printTranslations(io, num, filter(isdigit, num), d)
        end
    end
end
