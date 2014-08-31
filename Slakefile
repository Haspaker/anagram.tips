fs = require \fs
{flatten, filter} = require \prelude-ls
{exec} = require \child_process
util = require \util

const sass_dir = './static/css'
watching_sass = no

task 'watch', 'Recursively watches the whole directory', ->

	unless watching_sass => 
		watching_sass := yes
		exec "sass --watch #sass_dir/*.sass", (err, stdout, stderr) ->
  
	grab-all-files-recursively = (dir) ->
		files = fs.readdirSync(dir)
		files = files.map (file) ->
			file = "#dir/#file"
			stat = fs.statSync(file)
			if stat.isDirectory() then return grab-all-files-recursively(file)
			else return file
		return flatten files

	grab-all-directories-recursively = (dir) ->
		files = fs.readdirSync(dir)
		files = files.map (file) ->
			file = "#dir/#file"
			stat = fs.statSync(file)
			if stat.isDirectory() then return [file, grab-all-directories-recursively(file)]
			else return null
		return files |> flatten |> filter (isnt /\.[^\/]/) |> filter (?)


	all-directories = grab-all-directories-recursively \.
	all-directories ++= \.

	for directory in all-directories then let directory = directory
		fs.watchFile directory, ->
			util.log "Saw changes in #directory"
			invoke \watch

	all-files = grab-all-files-recursively \.
	livescript-files = all-files.filter (is /\.(ls|live)$/)

	util.log "Watching files #{livescript-files*' '} ..."

	for file in livescript-files then let file = file
		fs.watchFile file, ->
			util.log "Saw changes in #file"
			exec "livescript -c #file", (err, stdout, stderr) ->
				util.log "Successfully compiled #file" unless err
				util.log err if err; util.log stdout if stdout; util.log stderr if stderr



