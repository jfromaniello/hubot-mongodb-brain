# import mongobrain from STDIN
# drop collection and overwrite

async       = require 'async'
MongoClient = require('mongodb').MongoClient

mongoUrl = process.env.MONGODB_URL or
           process.env.MONGOLAB_URI or
           process.env.MONGOHQ_URL or
           'mongodb://localhost/hubot-brain'

MongoClient.connect mongoUrl, { useNewUrlParser: true }, (err, client) ->
  throw err if err

  db = client.db()
  console.log "MongoDB connected", mongoUrl

  process.stdin.setEncoding 'utf8'

  data = ""
  process.stdin.on 'readable', ->
    chunk = process.stdin.read()
    data += chunk if chunk?

  process.stdin.on 'end', ->
    data = JSON.parse data
    docs = []
    for k,v of data
      docs.push
        _id: k
        content: JSON.stringify(v)

    collection = db.collection('brain')

    collection.deleteMany {}, (err) ->
      throw err if err
      async.eachSeries docs, (doc, done) ->
        console.log "insert #{doc._id}"
        collection.insertOne doc, done
      , (errs, ress) ->
        if errs
          console.error errs
          process.exit 1
        process.exit 0

