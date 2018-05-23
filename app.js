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
    initCollection(data, 'leaderboard', { unique: ['uuid'] })
})

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
    res.render('leaderboard', {
    })
})

// app.post('/drawing', (req, res, next) => {
//     var drawing = data.drawings.findOne({uuid: req.body.uuid})
//     if (!drawing) {
//         drawing = Drawing({uuid: req.body.uuid})
//         data.drawings.insert(drawing)
//     }
//     // update model
//     drawing.json = req.body.json
//     drawing.empty = ((drawing.json || {}).objects || []).length == 0
//     drawing.dimensions = req.body.dimensions
//     if (drawing.status == STATUS.UPDATED || drawing.status == STATUS.APPROVED) {
//         drawing.status = STATUS.UPDATED
//     }
//     var autoapprove = drawing.status != STATUS.IGNORED && (GLOBAL.autoapprove || drawing.autoapprove)
//     if (autoapprove) {
//         drawing.status = STATUS.APPROVED
//     }
//     data.drawings.update(drawing)
//     // save to png using minimally cropped dimensions provided by client
//     canvas.setDimensions({ width: drawing.dimensions.width, height: drawing.dimensions.height })
//     canvas.loadFromJSON(drawing.json, () => {
//         // render objects
//         canvas.renderAll()
//         // save file
//         var destStream = fs.createWriteStream(drawingDirNew + drawing.uuid + '.png')
//         canvas.createPNGStream().on('data', chunk => destStream.write(chunk))
//         // autoapprove copy file
//         if (autoapprove) {
//             var destStream2 = fs.createWriteStream(drawingDirApproved + drawing.uuid + '.png')
//             canvas.createPNGStream().on('data', chunk => destStream2.write(chunk))
//         }
//     })
//     // return
//     res.sendStatus(200)
// })

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