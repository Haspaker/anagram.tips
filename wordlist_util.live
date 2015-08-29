fs = require \fs
{count-by, group-by, filter, obj-to-pairs, pairs-to-obj, unique, sort, map, foldl1} = require \prelude-ls
alphabet = require './languages.js' .alphabet

[action, wordfile, target] = process.argv[2 til] 

words = fs.readFileSync wordfile, encoding:\utf8

if action is 'lengthsort'

    words .= split \\n
    
    words-by-length = words |> group-by (.length) |> obj-to-pairs
    
    for [length, words] in words-by-length
        filepath = target + "#length.txt"
        console.log "(#length characters) Writing #{words.length} words to #filepath"
        fs.writeFile filepath, words * \\n

if action is 'cleansort'

    is-clean = (word) ->
        for char in word.toLowerCase!
            if char not in alphabet then return false
        return true

    words .= split \\n
    
    words-by-length = words |> filter is-clean |> group-by (.length) |> obj-to-pairs
    
    for [length, words] in words-by-length
        filepath = target + "#length.txt"
        console.log "(#length characters) Writing #{words.length} words to #filepath"
        fs.writeFile filepath, words * \\n

else if action is 'alphabet'
    words .= toLowerCase!
    alphabet = words.split('') |> unique
    console.log alphabet * ' '

else if action is 'specialchars'
    words .= toLowerCase!
    alphabet = words.split('') |> unique |> filter (not in [\A to \z])
    console.log alphabet * ' '

else if action is 'containing'
    words .= split \\n
    words .= filter (target in)
    console.log words * \\n