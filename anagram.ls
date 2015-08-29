fs = require \fs

languages = require './languages.js'

{count-by, split, group-by, empty, last, filter, reject, obj-to-pairs, pairs-to-obj, unique, unique-by, sort, map, foldl1} = 
    require \prelude-ls

const alphabet = languages.alphabet |> split ''

const alpha_indices = pairs-to-obj alphabet.map (c, i) -> [c, i]

const primes = do
    i = 1
    found_primes = []
    while found_primes.length < alphabet.length
        is_prime = [ 2 to Math.sqrt(i) ] |> map (i %) |> filter (is 0) |> empty
        if is_prime => found_primes ++= i
        i++
    found_primes

const analogous =
    * char: \a, variants: \áàâ
    * char: \o, variants: \óô
    * char: \e, variants: \éèëê
    * char: \i, variants: \íïî
    * char: \u, variants: \úüûù
    * char: \n, variants: \ñ
    * char: \c, variants: \ç

for pair in analogous
    for variant in pair.variants
        primes[ alpha_indices[ variant ] ] = 
            primes[ alpha_indices[ pair.char ] ]

const filepath = (iso, wordlist, length) -> "./words/#iso/#wordlist/#length.txt"

class AnagramFinder

    get_prime_product: (word) ->
        prime_product = 1
        for char in word.toLowerCase!
            if char in alphabet 
                prime_product *= primes[ alpha_indices[char] ]
        return prime_product

    find_anagrams_among_words: (target_word, words) ->

        target_prime_product = @get_prime_product target_word
        anagrams = []
    
        for word in words
            prime_product =  @get_prime_product word
            if prime_product is target_prime_product
                anagrams.push word

        return anagrams 
            |> unique-by (.toLowerCase!) 
            |> filter (.toLowerCase! isnt target_word.toLowerCase!)

    get_anagrams: (word, wordlists, iso, callback) ->

        word .= toLowerCase!
        wordlists .= split \,
        wordlength = word |> (.split '') |> reject (not in alphabet) |> (.length)

        if wordlength < 2 then return callback []

        found_anagrams = []
        read_wordlist_files = 0

        for let wordlist in wordlists

            error, words <~ fs.readFile (filepath iso, wordlist, wordlength), encoding:\utf8

            if error
                console.log error
            else
                words .= split \\n
                anagrams = @find_anagrams_among_words word, words
                found_anagrams ++= anagrams |> map (anagram) -> language:iso, source:wordlist, word:anagram

            read_wordlist_files += 1
            if read_wordlist_files == wordlists.length then callback found_anagrams


module.exports = new AnagramFinder()