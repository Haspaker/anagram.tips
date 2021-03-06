import require 'prelude-ls'

const ignored_chars = '§!#€%&/()=?`´^¨*"-_.,;:[]{}<>/' + "'" + " " + "\t"
const field_width = 350px

class APIConnection

    api_url: '/api'

    get_suggestions: (word, wordlists, iso, callback) ->
        request_url = @api_url + "/anagrams/#iso/#wordlists/#word"
        $.ajax(request_url).done callback
        $.ajax(request_url).error -> 
            callback [language:\en, wordlist:\dict, word:'ERROR: COULD NOT CONNECT']

    get_languages: (callback) ->
        request_url = @api_url + "/languages"
        $.ajax(request_url).done callback

class Settings extends Backbone.Model

    connection: null

    default_language: \english

    defaults:
        page: 'finder' # Structure: 'validator' or 'finder'
        alphabet: '' # Structure: 'abcdefgh...åäöü'
        languages: []   # Structure: [{name, capitalized, iso}, {name, capitalized, iso} ...]
        current_language: {} # Structure: {name, capitalized, iso}
        current_wordlists: <[dict]>

    initialize: ->
        @connection = new APIConnection()
        @connection.get_languages (language_data) ~> 
            @set \alphabet, language_data.alphabet
            @set \languages, language_data.languages
            @set \current_language, 
                @language_from_name @default_language

    language_from_iso: (iso) -> 
        @get \languages |> find (.iso is iso)

    language_from_name: (name) ->
        @get \languages |> find (.name is name)



class Navbar extends Backbone.View

    el: \body

    events:
        'click .navigation.find' : -> @set_page \finder
        'click .navigation.validate' : -> @set_page \validator

    settings: null

    initialize: ->
        @settings = window.settings
        @listenTo @settings, \change:page, @change_page

    set_page: (new_page) -> @settings.set \page new_page

    change_page: ->
        time = 500ms
        switch (@settings.get \page)
            | \finder =>
                moveLeft = '100%'
                [toPage, fromPage] = [$(\#finder), $(\#validator)]
                $(\body).addClass \finder
            | \validator =>
                moveLeft = '-100%'
                [toPage, fromPage] = [$(\#validator), $(\#finder)]
                $(\body).removeClass \finder

        toPage.animate 'left':0, time
        fromPage.animate 'left':moveLeft, time
        toPage.height \auto
        fromPage.height toPage.height!
        $(\#wrapper).height toPage.height!

class Wordlists extends Backbone.View

    el: \#wordlists

    settings: null

    events:
        'click .dict': -> @select_wordlists <[dict]>
        'click .wiki': -> @select_wordlists <[wiki]>
        'click .all': -> @select_wordlists do
            @settings.get(\current_language).wordlists |> map (.id)

    initialize: ->
        @settings = window.settings
        @add_listeners!

    add_listeners: ->
        @listenTo @settings, \change:current_language, ->
            @select_default_wordlist!
            @render!
        @listenTo @settings, \change:current_wordlists, @render

    select_default_wordlist: ->
        @select_wordlists [ @settings.get(\current_language).wordlists |> first |> (.id) ]

    select_wordlists: (wordlists) -> @settings.set \current_wordlists wordlists

    render: ->
        @$el.empty!
        @$el.append '<span><b>Use:</b></span>'
        with @settings.get(\current_language).wordlists
            for wordlist in ..
                $(\<span>)
                    .text(wordlist.capitalized)
                    .addClass(wordlist.id)
                    .appendTo @$el
            if ..length > 1
                title = if ..length is 2 then 'Both' else 'All'
                $(\<span>)
                    .text(title)
                    .addClass(\all)
                    .appendTo @$el
        with @settings.get(\current_wordlists)
            if ..length > 1
                @$(\.all).addClass \selected
            else @$(".#{..}").addClass \selected




class Languages extends Backbone.View

    el: \#languages

    settings: null

    events:
        'click .flag' : (e) -> 
            @set_current_language $(e.currentTarget).data \iso

    initialize: ->
        @settings = window.settings
        @add_listeners!
        @render!

    add_listeners: ->
        @listenTo @settings, \change:languages, @render
        @listenTo @settings, \change:current_language, @select_flag

    render: ->

        @$el.empty!

        create_flag = ({iso, capitalized}) ->
            """<span class="flag" title="#capitalized" data-iso="#iso">
                    <img src="/img/gflags/png/#iso.png"/>
               </span>"""

        for language in @settings.get \languages
            @$el.append create_flag language

    select_flag: ->
        current_iso = @settings.get \current_language .iso
        @$el.addClass(\nohover)
        setTimeout (~> @$el.removeClass \nohover), 
            1500
        @$("[data-iso=#current_iso]").detach().prependTo @$el

    set_current_language: (iso) ->
        @settings.set \current_language,
            @settings.language_from_iso iso

class Anagram extends Backbone.Model

    connection: null
    settings: null

    defaults: 
        valid: false
        text: ''
        conflicting_letter_indices: [] # Structure: [index, index, index ... ]
        suggestions: []

    initialize: ->

        @settings = window.settings
        @connection = new APIConnection()
        @get_suggestions = _.throttle @get_suggestions, 125

        @get_suggestions!
        @add_listeners!

    add_listeners: ->
        @on 'change:text change:conflicting_letter_indices', @get_suggestions
        @listenTo @settings, 'change:current_language change:current_wordlists', @get_suggestions

    get_suggestions: ->
        word = if @collection then @conflicting_letters! else @get \text
        iso = @settings.get \current_language .iso
        wordlists = @settings.get \current_wordlists
        @connection.get_suggestions word, wordlists, iso, (suggestions_data) ~> 
            @set \suggestions, 
                suggestions_data |> map (data) -> new Suggestion data

    conflicting_letters: ->
        text = @get \text
        return @get \conflicting_letter_indices |> map (text.)

    toString: -> @get \text .toLowerCase!

    chars: -> @toString().split ''

class AnagramView extends Backbone.View

    tagName: \div
    className: \anagram-field
    attributes:
        contentEditable: true

    events: 
        \input : -> @update!

    initialize: -> 
        @render!
        @add_listeners!

    add_listeners: ->
        @listenTo @model, \change:conflicting_letter_indices, 
            @color_conflicting_letters

    render: -> 
        @$el.text @model.get \text
        @update!

    update: -> 
        @model.set \text, @$el.text()
        @spanwrap!
        @color_conflicting_letters!

    color_conflicting_letters: -> 

        # Reset the color of all letters
        @$(\span).removeClass \mismatch

        # Color the conflicting ones red
        @model.get \conflicting_letter_indices .forEach (letter_index) ~>
                    letter_index += 1 # char indices starts at 1, not 0
                    @$(".char#letter_index").addClass \mismatch

    spanwrap: ->
        """ Wraps all individual text characters in a <span> tag via lettering.js
            This allows us to set the CSS of all letters individually.
            E.g: 'ab' -> '<span class="char1">a</span><span class="char2">b</span>'
            Caret position is conserved. """

        if window.getSelection().rangeCount is 0 => return

        range = window.getSelection().getRangeAt(0).cloneRange()

        # The element that is being edited (or more precisely: selected)
        # The parent element is chosen because we want the DOM element, not the text node
        focus_node = range.startContainer.parentElement

        # The position of the caret within the edited element, (e.g. 4 chars from the beginning)
        focus_offset = range.startOffset

        if @el `$.contains` focus_node
            character_position = $(focus_node).prevAll().length + focus_offset
            if $(focus_node).html() is /\s<br>/ #FIX FIREFOX BUG 3
                character_position += 1 #FIX FIREFOX BUG 3
                $(focus_node).html $(focus_node).html().replace(' <br>', '&nbsp;') #FIX FIREFOX BUG 3
            if focus_node.childNodes.length is 2 => # FIX FIREFOX BUG 2
                if focus_node.childNodes.1.nodeType is 3 # FIX FIREFOX BUG 2
                    character_position += 1 # FIX FIREFOX BUG 2
        else if @el is focus_node
            if $(range.startContainer).text() isnt ''
                character_position = focus_offset
            else 
                character_position = Math.max 1, @el.childNodes.length - 1 # FIX FIREFOX BUG 1
        else 
            @$el.lettering()
            return

        @$el.lettering()
        
        range
            ..setStart @el.childNodes[character_position - 1], 1
            ..collapse true
    
        window.getSelection()
            ..removeAllRanges()
            ..addRange range

class Suggestion extends Backbone.Model

    defaults:
        word: null
        language: null
        source: null

class SuggestionView extends Backbone.View

    tagName: \a
    className: \suggestion
    attributes: 
        href: null
        target: '_blank' #open in new tab

    initialize: ~>
        @$el.text @model.get \word

        switch @model.get \source
        | \dict => 
            @$el.prepend "<img src='/img/linkicon.png'/>"
            switch @model.get \language
            | \en => 
                @$el.prop \href "http://www.merriam-webster.com/dictionary/#{ @model.get \word }"
                #@$el.prop \href "http://www.google.com/translate?hl=&sl=es&tl=en&u=http%3A%2F%2Fwww.merriam-webster.com%2Fdictionary%2F#{ @model.get \word }&anno=2&sandbox=0"
                #@$el.prop \href "https://www.google.se/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0CCUQFjAA&url=http%3A%2F%2Fwww.merriam-webster.com%2Fdictionary%2F#{ @model.get \word }&ei=SYb-U4TwA5LWaLmIgagN&usg=AFQjCNFRVjdDjYv02LIlg5bFJvsSb--yuA&bvm=bv.74035653,d.d2s"
            | otherwise  => @$el.prop \href "http://#{ @model.get \language }.wiktionary.com/wiki/#{ @model.get \word }"
        | \wiki => 
            @$el.prepend "<img src='/img/wikilogo.png'/>"
            @$el.prop \href "http://#{ @model.get \language }.wikipedia.com/wiki/#{ @model.get \word }"


class AnagramValidator extends Backbone.Collection

    settings: null

    model: Anagram

    initialize: -> 
        @settings = window.settings
        @add [new Anagram!, new Anagram!]
        @add_listeners!

    add_listeners: ->
        @on 'add remove change:text', ~> 
            @update_conflicting_letters!
            @check_if_all_anagrams_are_valid!

    reject_ignored_chars: (char_array) -> 
        alphabet = @settings.get \alphabet
        char_array |> reject (not in alphabet)

    check_if_all_anagrams_are_valid: ->
        validity = @pluck \conflicting_letter_indices |> flatten |> empty
        @invoke \set, valid: validity

    update_conflicting_letters: ->
        @forEach (anagram) ~> 
            other_anagrams = @filter (isnt anagram)
            conflicts = other_anagrams 
                |> map (other) ~> @get_conflicting_letters anagram, other
                |> flatten
                |> unique
            anagram.set \conflicting_letter_indices, conflicts

    get_conflicting_letters:  (target_anagram, other_anagram) ->
        target_letters = target_anagram.chars()
        other_letters = other_anagram.chars()

        conflicting_letters = target_letters.filter (letter) ->
            index = other_letters.indexOf letter
            if index > -1 then
                other_letters[index] = \matched
                return false
            else return true

        conflicting_letters = @reject_ignored_chars conflicting_letters

        conflicting_indices = conflicting_letters.map (letter) ->
            index = target_letters.lastIndexOf letter
            target_letters[index] = \matched
            return index

        return conflicting_indices

class AnagramValidatorView extends Backbone.View

    el: \#validator

    views: []

    events:
        'click .add-field:not(.disabled)' : -> @collection.push new Anagram!
        'click .remove-field:not(.disabled)' : -> @collection.pop!

    initialize: -> 
        @render!
        @update_guide_text!
        @disable_or_enable_buttons!
        @add_listeners!

    add_listeners: ->
        @listenTo @collection, 'add', @add_new_field
        @listenTo @collection, 'remove', @remove_last_field
        @listenTo @collection, 'change:suggestions add remove', @update_suggestions
        @listenTo @collection, 'change:valid', @update_validity
        @listenTo @collection, 'add remove', ->
            @update_guide_text!
            @disable_or_enable_buttons!

    render: -> 
        @collection.forEach (anagram) ~>
            view = new AnagramView model:anagram
            @views.push view
            @$('.fields').append view.$el

    update_suggestions: ->
        unless @collection.at(0).get \valid
            @$('.suggestions').empty!
            anagram_texts = @collection.map (.conflicting_letters!)
            anagram_suggestions = @collection.pluck \suggestions
            zipped = zip anagram_texts, anagram_suggestions
            zipped = zipped |> reject (.1 |> empty)
            for [text, suggestions] in zipped
                @$('.suggestions').append "<div>Suggested anagrams of missing letters <span class='original'>#{text * ''}</span></div>"
                suggestions_container = $ "<div class='suggestion-list'></div>"
                for suggestion in suggestions
                    suggestion_view = new SuggestionView model:suggestion
                    suggestions_container.append suggestion_view.el
                @$('.suggestions').append suggestions_container
        $(\#wrapper).height @$el.height!


    update_guide_text: -> 
        @$('.guide .plurality').text ['' 's'][Number @collection.length > 2]
        @$('.guide .amount').text <[zero one two three four five]>[@collection.length]

    disable_or_enable_buttons: ->
        @$('.add-field, .remove-field').removeClass \disabled
        if @collection.length is 2 => @$('.remove-field').addClass \disabled
        if @collection.length is 4 => @$('.add-field').addClass \disabled

    add_new_field: ->
        newest_anagram = @collection.last!
        view = new AnagramView model:newest_anagram
        @views.push view
        @$('.fields').append view.$el
        view.$el.css width:0px
        view.$el.animate width:200px, 500ms

    remove_last_field: ->
        view = @views.pop()
        view.$el.animate width:0, 'margin-left':0, 'margin-right':0, 500ms, -> $(this).remove!

    update_validity: -> 
        valid = @collection.at(0).get \valid
        not_all_empty = @collection.pluck(\text).join('') isnt ''
        if valid and not_all_empty
            $(\body).addClass \success
        else
            $(\body).removeClass \success


class AnagramFinder extends Backbone.Model

    defaults:
        anagram: null

    initialize: -> 
        @settings = window.settings
        @set \anagram, new Anagram!
        @add_listeners!

    add_listeners: ->

class AnagramFinderView extends Backbone.View

    el: \#finder

    initialize: -> 
        @settings = window.settings
        @render!
        @add_listeners!

    add_listeners: ->
        @listenTo @settings, 'change:current_language', @update_guide_text
        @listenTo @model.get(\anagram), 'change:text change:suggestions', @update_suggestions

    render: -> 
        anagram = @model.get \anagram
        view = new AnagramView model:anagram
        view.$el.width field_width * 1.25
        @$('.fields').append view.$el

    update_suggestions: ->

        @$('.suggestions').empty!
        text = @model.get \anagram .get \text
        suggestions = @model.get \anagram .get \suggestions
        
        suggestions_container = $ "<div class='suggestion-list'></div>"
        if empty suggestions and text isnt ''
            suggestions_container.append "<div class='suggestion'>No anagrams found</div>"
        else
            for suggestion in suggestions
                suggestion_view = new SuggestionView model:suggestion
                suggestions_container.append suggestion_view.el
        @$('.suggestions').append suggestions_container
        $(\#wrapper).height @$el.height!


    update_guide_text: ->  @$('.language').text @settings.get(\current_language).name



$ ->

    window.settings = new Settings!

    languages = new Languages!
    wordlists = new Wordlists!
    navbar = new Navbar!

    anagram_validator = new AnagramValidator!
    anagram_validator_view = new AnagramValidatorView collection: anagram_validator

    anagram_finder = new AnagramFinder!
    anagram_finder_view = new AnagramFinderView model: anagram_finder



