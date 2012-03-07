express = require 'express'
redis = require 'redis'
crypto = require 'crypto'
urlparser = require 'url'
base62 = require './base62'


app = express.createServer()
db = redis.createClient()

# Config
app.configure ->
    app.set 'view engine', 'jade'
    app.use express.bodyParser()
    app.use express.static(__dirname + '/public')
    app.use express.favicon(__dirname + '/public/favicon.ico')
    app.use app.router # inferior to static so that static file resolution works

app.configure 'development', ->
    app.use express.errorHandler { dumpException: true, showStack: true }

app.configure 'production', ->
    app.use express.errorHandler()

db.on 'error', (err) ->
    console.log "ERROR: #{err}"

# URL validate
isURL = (x) ->
    re = /^(?:(?:ht|f)tp(?:s?)\:\/\/|~\/|\/)?(?:\w+:\w+@)?((?:(?:[-\w\d{1-3}]+\.)+(?:com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|edu|co\.uk|ac\.uk|it|fr|tv|museum|asia|local|travel|[a-z]{2}))|((\b25[0-5]\b|\b[2][0-4][0-9]\b|\b[0-1]?[0-9]?[0-9]\b)(\.(\b25[0-5]\b|\b[2][0-4][0-9]\b|\b[0-1]?[0-9]?[0-9]\b)){3}))(?::[\d]{1,5})?(?:(?:(?:\/(?:[-\w~!$+|.,=]|%[a-f\d]{2})+)+|\/)+|\?|#)?(?:(?:\?(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)(?:&(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)*)*(?:#(?:[-\w~!$ |\/.,*:;=]|%[a-f\d]{2})*)?$/i
    re.test(x)

# Routes
app.get '/', (req, res) ->
    res.render 'index'

app.post '/', (req, res) ->
    data = {}
    # Trim & validate URL
    url = req.body.url.trim()
    if not isURL url
        data.error = 'Invalid URL!' if not isURL url
        res.render 'index', data
    else
        getShortCode url, (err, short) ->
            data.shortcode = short
            res.render 'index', data

app.get '/:shortcode', (req, res) ->
    getUrl req.params.shortcode, (err, url) ->
        if url then res.redirect(url, 302) else res.redirect('/')

# Get short code
getShortCode = (url, cb) ->
    if not urlparser.parse(url).protocol
        # Prepend 'http://'
        url = 'http://' + url
    hash = 'shortlink:' + crypto.createHash('md5').update(url).digest('hex')
    db.get hash, (err, res) ->
        # if URL has exists in database
        if res
            cb(err, res)
        else
            db.incr 'shortlink:total', (err, res) ->
                short = base62.encode res + 10000
                db.set hash, short
                db.set "shortlink:url:#{short}", url
                cb(err, short)

# Get URL
getUrl = (short, cb) ->
   hash = "shortlink:url:#{short}"
   db.get hash, (err, res) ->
       if res then cb(err, res) else cb(res, null)

app.listen 3000
console.log "Express server listening on port #{app.address().port} in #{app.settings.env}"
