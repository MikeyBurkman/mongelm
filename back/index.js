'use strict';

const Promise = global.Promise = require('bluebird'); // Bluebird everywhere
const restify = require('restify');
const R = require('ramda');
const corsMiddleware = require('restify-cors-middleware');

const port = parseInt(process.argv[2]) || 8081

const server = restify.createServer({
    name: 'mongelm-back',
    version: '1.0.0'
});

server.use(restify.plugins.acceptParser(server.acceptable));
server.use(restify.plugins.queryParser());
server.use(restify.plugins.bodyParser());

const cors = corsMiddleware({
  preflightMaxAge: 5, //Optional 
  origins: ['*'],
  allowHeaders: [],
  exposeHeaders: []
});

server.pre(cors.preflight);
server.use(cors.actual);

server.get('/collection/:id', function (req, res, next) {
    const id = req.params.id;

    const data = R.range(0, 10).map(() => ({
        _id: '' + Date.now(),
        name: 'foo'
    }));

    Promise.delay(300).then(() => {
        res.send(data);
        return next();
    });
});

server.listen(port, function () {
    console.log('%s listening at %s', server.name, server.url);
});