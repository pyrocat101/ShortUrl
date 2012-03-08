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
    app.set 'view options', pretty: true
    app.use express.bodyParser()
    app.use '/assets', express.static(__dirname + '/assets')
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
    getShortUrl req.body.url, req.header('Host'), (data) ->
        res.render 'index', data

# API at /1 to retrieve short URL
# GET or POST request using query string or json
# example:
# localhost:3000/1?url=www.google.com
# --> { shortcode: localhost:3000/xxx }
# localhost:3000/1?url=errorURL
# --> { error: 'Invalid URL!' }
# Beware of the Content-Type!
app.all '/1/:url?', (req, res) ->
    if req.param('url')
        # GET with query string
        getShortUrl req.param('url'), req.header('Host'), (data) ->
            res.json data
    else
        res.send 404


app.get '/:shortcode', (req, res) ->
    getUrl req.params.shortcode, (err, url) ->
        if url then res.redirect(url, 302) else res.redirect('/')

# Get short URL
# Callback parameter: (data)
getShortUrl = (url, host, cb) ->
    data = {}
    # Trim & validate URL
    url = url.trim()
    if not isURL url
        data.error = 'Invalid URL!'
        cb(data)
    else
        getShortCode url, (err, short) ->
            data.shortUrl = "#{host}/#{short}"
            cb(data)

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
