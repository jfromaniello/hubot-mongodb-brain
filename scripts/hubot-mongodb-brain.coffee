# Description:
#   hubot-mongodb-brain
#   support MongoLab and MongoHQ on heroku.
#
# Dependencies:
#   "mongodb": "*"
#   "lodash" : "*"
#
# Configuration:
#   MONGODB_URL or MONGOLAB_URI or MONGOHQ_URL or 'mongodb://localhost/hubot-brain'
#
# Author:
#   Sho Hashimoto <hashimoto@shokai.org>

'use strict'

_           = require 'lodash'
MongoClient = require('mongodb').MongoClient

deepClone = (obj) -> JSON.parse JSON.stringify obj

module.exports = (robot) ->
  mongoUrl = process.env.MONGODB_URL or
             process.env.MONGOLAB_URI or
             process.env.MONGOHQ_URL or
             process.env.MONGODB_URI or
             'mongodb://localhost/hubot-brain'

  MongoClient.connect mongoUrl, (err, client) ->
    throw err if err
    db = client.db()

    robot.brain.on 'close', ->
      client.close()

    robot.logger.info "MongoDB connected"
    robot.brain.setAutoSave false

    cache = {}

    ## restore data from mongodb
    db.createCollection 'brain', (err, collection) ->
      collection.find({}).toArray (err, docs) ->
        return robot.logger.error err if err
        data = {}
        for doc in docs
          data[doc._id] = JSON.parse(doc.content)
        cache = deepClone data
        robot.brain.mergeData data
        robot.brain.resetSaveInterval 10
        robot.brain.setAutoSave true

    ## save data into mongodb
    robot.brain.on 'save', (data) ->
      db.collection 'brain', (err, collection) ->
        for k,v of data
          do (k,v) ->
            return if _.isEqual cache[k], v  # skip not modified key
            robot.logger.debug "save \"#{k}\" into mongodb-brain"
            cache[k] = deepClone v
            collection.update
              _id:  k
            ,
              $set:
                content: JSON.stringify(v)
            ,
              upsert: true
            , (err, res) ->
              robot.logger.error err if err
            return

