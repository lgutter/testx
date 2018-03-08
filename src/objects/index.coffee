_ = require 'lodash'
parse = require 'csv-parse/lib/sync'
fs = require 'fs'
{defunc} = require '../utils'
defaultBehaviour = require './default-behaviour'

objects = {}

module.exports =
  add: (objs) ->
    objs = defunc objs
    if typeof objs == "object"
      _.assign(objects, objs)
    else # if the argument is not an object we assume it is a CSV file path
      for row in parse fs.readFileSync objs, {delimiter: ','}
        objects[row[0]] = locator: row[1], value: row[2]

  get: -> objects
  element: (key) -> _element() key
  elements: (key) ->
    el = _element(element.all) key
    el.wait = (timeout, expCondition = protractor.ExpectedConditions.visibilityOf) ->
      # waiting seems not to be supported when using `element.all`, wait on a single element
      browser.wait expCondition.call(protractor.ExpectedConditions, _element()(key)), timeout
    el

_element = (findFunc = element) -> (key) ->
  findElement = (object) ->
    behaviour = _.merge {}, defaultBehaviour(), (object.behaviour or object.behavior)
    value = if Array.isArray(object.value) then object.value else [object.value]
    _.extend findFunc(protractor.By[object.locator].apply @, value), behaviour

  match = /^([^\(]+)\((.*)\)$/.exec key.trim()
  if match
    [full, func, args] = match
    obj = objects[func]
    if typeof obj == 'function'
      parsed = eval "[#{args}]"
      findElement obj.apply(@, parsed)
    else
      throw new Error "Object '#{func}' is not a function."
  else if obj = objects[key]
    findElement defunc obj
  else
    throw new Error "Could not find a locator for object '#{key}'! Is this object defined?"
