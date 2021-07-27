#=
# Port of Peter Norvig's Common Lisp program from http://norvig.com/java-lisp.html.
#
# - Julia version: 1.6.2
# - Author: Renato Athaydes
# - Date: 2021-07-24
=#
const emptyStrings = String[]

function printTranslations(num, digits, ref, start=1, words=String[])
    if start > length(digits)
       return println(num, ": ", join(words, " "))
    end
    foundWord = false
    n = BigInt(1)
    for i in start:length(digits)
        n = n * 10 + nthDigit(digits, i)
        for word in get(ref[], n, emptyStrings)
            foundWord = true
            printTranslations(num, digits, ref, i + 1, [words; word])
        end
    end
    if !foundWord &&
        !(!isempty(words) && length(words[end]) == 1 && isdigit(words[end][begin]))
        printTranslations(num, digits, ref, start + 1, [words; string(nthDigit(digits, start))])
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
    UInt(digits[i]) - UInt('0')
end

function charToDigit(ch)
    ch = lowercase(ch)
    ch == 'e' && return 0
    ch in ['j', 'n', 'q'] && return 1
    ch in ['r', 'w', 'x'] && return 2
    ch in ['d', 's', 'y'] && return 3
    ch in ['f', 't'] && return 4
    ch in ['a', 'm'] && return 5
    ch in ['c', 'i', 'v'] && return 6
    ch in ['b', 'k', 'u'] && return 7
    ch in ['l', 'o', 'p'] && return 8
    ch in ['g', 'h', 'z'] && return 9
    throw(DomainError(ch, "Not a letter"))
end

function wordToNumber(word::String)::BigInt
    n = BigInt(1)
    for ch in word
        if isletter(ch) && isascii(ch)
            n = n * 10 + charToDigit(ch)
        end
    end
    n
end

function main()
    dict = open(isempty(ARGS) ? "dictionary.txt" : ARGS[begin]) do file
        loadDictionary(file)
    end

    # I do this trick to ruin type inference, in order to imitate running
    # in global scope, like the original version did.
    ref = Base.RefValue{Any}(dict)

    open(length(ARGS) < 2 ? "input.txt" : ARGS[begin+1]) do file
        for num in eachline(file)
            printTranslations(num, filter(isdigit, num), ref)
        end
    end
end

