{typ3: type} = require './utils.coffee'
{TreeMap, NodeMap, transverse, root, transversePrimitive, integer} = require './main.coffee'

class Suggestion

class SimpleSuggestion extends Suggestion
  constructor: (@suggestions) ->
    @isScalar = false

class OpenSuggestion extends Suggestion
  constructor: (@suggestions, @open, @metadata) ->
    @isScalar = false

class SuggestItem then constructor: (@open, @value, @metadata) -> @isScalar = false

class SuggestionNode then constructor: (@name, @isScalar=true) ->

class StringWildcard extends SuggestionNode then constructor: -> @isScalar = true

stringWilcard = new StringWildcard

class IntegerWildcard extends SuggestionNode then constructor: -> @isScalar = true

integerWildcard = new IntegerWildcard

class InvalidState
  constructor: (@suggestions={}) ->
  open: -> @

invalidState = new InvalidState

class SuggestionNodeMap extends NodeMap
  name = (node) -> new SuggestionNode(node.constructor.name)
  @markdown: name
  @include: name
  @jsonSchema: name
  @regex: name
  @integer: () -> integerWildcard
  @boolean: name
  @xmlSchema: name
  @stringNode: () -> stringWilcard
  @listNode: () -> stringWilcard
  @constantString: (root) -> new SuggestionNode(root.value)

functionize = (value) -> if type(value) == 'function' then value else () -> value

class TreeMapToSuggestionTree extends TreeMap
  @alternatives: (root, alternatives) ->
    d = {}
    for alternative in alternatives
      switch alternative.constructor
        when SimpleSuggestion
          {suggestions} = alternative
          ((d[key] = value) for key, value of suggestions)
        when OpenSuggestion
          {suggestions} = alternative
          ((d[key] = value) for key, value of suggestions)
          {open, metadata} = alternative
        when SuggestionNode
          # TODO Nothing interesting to do here
          undefined
        when StringWildcard
          # TODO Nothing interesting to do here
          undefined
        when IntegerWildcard
          # TODO Nothing interesting to do here
          undefined
        else
          throw new Error("Invalid type: #{alternative} of type #{alternative.constructor}")
    if open?
      new OpenSuggestion(d, ( -> open()), metadata)
    else 
      new SimpleSuggestion(d)

  @multiple: (root, element) -> 
    element

  @tuple: (root, key, value) -> 
    {metadata} = root
    
    switch key.constructor
      when StringWildcard
        new OpenSuggestion({}, functionize(value), metadata)
      when IntegerWildcard
        new OpenSuggestion({}, functionize(value), metadata)
      else
        d = {}
        d[key.name] = new SuggestItem(functionize(value), key, metadata)
        new SimpleSuggestion(d)

  @postponedExecution: (root, execution) ->
    execution.f

  @node: (root) ->
    transversePrimitive(SuggestionNodeMap, root)


suggestionTree = transverse(TreeMapToSuggestionTree, root)

suggest = (root, index, path) ->
  key = path[index]

  if not key?
    return root

  {suggestions} = root
  if suggestions
    currentSuggestion = suggestions[key]
  else
    currentSuggestion = undefined
  
  val = if currentSuggestion
    switch currentSuggestion.constructor
      when OpenSuggestion
        currentSuggestion
      when SuggestItem
        currentSuggestion
      else
        switch root.constructor
          when OpenSuggestion
            root
          when SuggestItem
            root
          else
            invalidState
  else
    switch root.constructor
      when OpenSuggestion
        root
      when SuggestItem
        root
      else
        invalidState

  val = val.open()

  suggest(val, index + 1, path)

suggestRAML = (path) ->
  suggest suggestionTree, 0, path

@suggestRAML = suggestRAML

window.suggestRAML = suggestRAML if typeof window != 'undefined'
