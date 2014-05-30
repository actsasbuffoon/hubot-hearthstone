# Description:
#   Returns a Hearthstone cards's stats
#
# Dependencies:
#   None
#
# Commands:
#   hearthstone me <Hearthstone card> - Return <Hearthstone card>'s stats: name - mana - race - type - attack/hlth - descr
#   hearthstone me moar <Hearthstone card> - Return more of the <Hearthstone card>'s stats
#
# Author:
#   sylturner
#

fs = require 'fs'
path = require 'path'
lunr = require 'lunr'

module.exports = (robot) ->

  robot.getByName = (json, name) ->
    json.filter (card) ->
      card.name.toLowerCase() is name.toLowerCase()

  robot.hear /^hearthstone me (moar )*(.+)/, (msg) ->
    more = msg.match[1]
    name = msg.match[2]
    additional = more != undefined
    robot.fetchCard msg, name, (card) ->
      robot.sendCard(card, msg, additional)

  robot.cardIndex = lunr ->
    @field 'name', boost: 10
    @field 'descr', boost: 2
    @field 'flavor'
    @field 'id'

  fs.readFile path.join(__dirname, "cards.json"), (err, data)->
    robot.cards = JSON.parse(data)
    robot.cards.forEach (card, idx)->
      robot.cardIndex.add
        id: idx,
        name: card.name,
        descr: card.descr,
        flavor: card.flavorText

  robot.fetchCard = (msg, name, callback) ->
    card = robot.getByName(robot.cards, name)
    if card.length > 0
      callback(card)
    else
      results = robot.cardIndex.search(name)
      if results.length > 0
        results.forEach (result)->
          callback([robot.cards[result.ref]])
      else
        callback([])

  robot.sendCard = (card, msg, additional) ->
    if card.length > 0
      body = "#{card[0].name} - Mana: #{card[0].mana} - Race: #{card[0].race} - Type: #{card[0].type} - Attack/Health: #{card[0].attack}/#{card[0].health} - Descr: #{card[0].descr}"
      if additional
        body += "\nFlavor: #{card[0].flavorText} Rarity: #{card[0].rarity}"
        body += "\nhttp://hearthstonecards.herokuapp.com/cards/medium/#{card[0].image}.png"
      msg.send body
    else
      msg.send "I can't find that card"
