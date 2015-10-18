express = require \express
http = require \http
finder = require './anagram.js'
languages = require './languages.js'

const static_dir = './public'
const homepage = static_dir + '/html/index.html'

app = express()

app.use express.static(static_dir)

app.get '/' (req, res) -> res.sendfile homepage

app.get '/api/anagrams/:iso/:wordlists/:word' (req, res) -> 
	iso = req.param \iso 
	word = req.param \word
	wordlists = req.param \wordlists
	finder.get_anagrams word, wordlists, iso, (anagrams) -> res.send anagrams

app.get '/api/anagrams/:language/:wordlists' (req, res) -> res.send []

app.get '/api/languages' (req, res) -> res.send languages

app.listen process.env.PORT || 8000
