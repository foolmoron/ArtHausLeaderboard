const express = require('express')
const http = require('http')
const https = require('https')
const cors = require('cors')
const path = require('path')
const fs = require('fs')
const favicon = require('serve-favicon')
const logger = require('morgan')
const cookieParser = require('cookie-parser')
const bodyParser = require('body-parser')
const session = require('express-session')
const loki = require('lokijs')
const uuid = require('uuid/v4')

const config = require('./config.js')

const app = express()

// view engine setup
app.set('views', path.join(__dirname, 'views'))
app.set('view engine', 'ejs')

app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')))
app.use(logger('dev'))
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: false }))
app.use(cookieParser())
app.use(express.static(path.join(__dirname, 'public')))
app.use(cors())
app.use(session({
    secret: config.SECRET,
    resave: true,
    saveUninitialized: true,
}))

// database
if (!fs.existsSync('db')) {
    fs.mkdirSync('db')
}
const db = new loki('db/db.json', { autosave: true, serializationMethod: 'pretty' })
const data = {}
function initCollection(container, name, opts) {
    var collection = db.getCollection(name)
    if (!collection) {
        collection = db.addCollection(name, opts)
    }
    container[name] = collection
}

db.loadDatabase({}, () => {
    initCollection(data, 'players', { unique: ['uuid'] })
})

// start backup loop
var pad2 = s => (s.toString().length == 1 ? '0' : '') + s
var backupInterval = setInterval(function() {
    var date = new Date()
    var filename = `db/db_${pad2(date.getFullYear())}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}_${pad2(date.getHours())}-${pad2(date.getMinutes())}-${pad2(date.getSeconds())}.json`
    fs.createReadStream('db/db.json').pipe(fs.createWriteStream(filename))
    console.log('BACKUP ' + filename)
}, 1000*60*5)

// globals

const GLOBAL = {
}

// auth
var adminAuth = (req, res, next) => {
    if (req.session && req.session.isAdmin) {
        next()
    } else {
        res.redirect('/login')
    }
}

app.get('/login', (req, res, next) => {
    if (req.session) {
        req.session.destroy()
    }
    res.render('login', { })
})
app.post('/login', (req, res, next) => {
    if (req.body.password.trim() === config.PASSWORD) {
        req.session.isAdmin = true
        res.redirect('/leaderboard')
    } else {
        res.render('login', { 
            previousInput: req.body.password, 
            error: `Those are the incorrect words... are you sure you're in the right place?`,
        })
    }
})

// routes
app.get('/', adminAuth, (req, res, next) => {
    res.render('index', { })
})
app.get('/leaderboard', adminAuth, (req, res, next) => {
    res.render('leaderboard', { })
})

const Player = (init) => Object.assign({
    uuid: uuid(),
    hue: Math.floor(Math.random() * 360),
    name: '',
    points: 0,
}, init)

function checkPlayer(req, res, next) {
    var player = data.players.findOne({uuid: req.params.uuid})
    if (!player) {
        return res.status(400).json({error : 'invalid player uuid'})
    }
    req.player = player
    next()
}

app.get('/player/:name', (req, res, next) => {
    var name = req.params.name
    var num = 1
    while (data.players.findOne({name})) {
        num++
        name = req.params.name + ' #' + num
    }

    var newPlayer = Player({name})
    data.players.insert(newPlayer)

    var player = data.players.findOne({uuid: newPlayer.uuid})
    data.players.update(player)
    res.json(player)
})

app.get('/player/:uuid/points/:pointsToAdd', checkPlayer, (req, res, next) => {
    var player = req.player
    player.points += parseInt(req.params.pointsToAdd) || 0
    player.points = Math.max(0, player.points)
    data.players.update(player)
    res.json(player)
})

app.get('/player/:uuid', checkPlayer, (req, res, next) => {
    var player = req.player
    res.json(player)
})
app.get('/playerupdates/:sinceTime', (req, res, next) => {
    var sinceTime = parseInt(req.params.sinceTime) || 0
    var players = data.players.where(player => player.meta.updated >= sinceTime)
    res.json({time: new Date().getTime(), players})
})

// catch 404 and forward to error handler
app.use((req, res, next) => {
    var err = new Error('Not Found')
    err.status = 404
    next(err)
})

// error handler
app.use((err, req, res, next) => {
    // set locals, only providing error in development
    res.locals.message = err.message
    res.locals.error = req.app.get('env') === 'development' ? err : {}

    // render the error page
    res.status(err.status || 500)
    res.render('error')
})

// start listening on http and https
http.createServer(app).listen(config.HTTP_PORT, function () {
    console.log(`
************************************
** Started listening on port ${config.HTTP_PORT} **
************************************`)
})
var certs = null
try { certs = { key: fs.readFileSync(config.KEY_PATH), cert: fs.readFileSync(config.CERT_PATH) } } catch (e) {}
if (certs) {
    https.createServer(certs, app).listen(config.HTTPS_PORT, function () {
        console.log(`
++++++++++++++++++++++++++++++++++++
++ Started listening on port ${config.HTTPS_PORT} ++
++++++++++++++++++++++++++++++++++++`)
    })
}

module.exports = app