var express = require('express');
var bodyParser = require('body-parser')
var app = express();
var path = require('path');
var formidable = require('formidable');
var fs = require('fs');
var exec = require('child_process').exec;

app.use(express.static(path.join(__dirname, 'public')));
app.use(bodyParser.json());

app.get('/', function(req, res) {
    res.sendFile(path.join(__dirname, 'views/index.html'));
});

app.get('/status', function(req, res) {
    function prepareString(line) {
        lineArr = line.split(" ");
        line = "";
        lineArr.forEach(function(element) {
            element = element.trim();
            if (element !== "") {
                line += element;
                line += " ";
            }
        }, this);
        return line;
    }
    function puts(error, stdout, stderr) {
        var statArr = stdout.split("\n");
        statArr = statArr.map(prepareString);
        res.json({ content: statArr });
    }
    exec("supervisorctl status", puts);
});

app.post('/upload/:service', function(req, res) {
    var form = new formidable.IncomingForm();
    form.multiples = true;
    var service = req.params.service;
    //form.uploadDir = path.join(__dirname, `/uploads/${service}`);
    form.uploadDir = "/CAE/etc";
    form.on('file', function(field, file) {
        fs.rename(file.path, path.join(form.uploadDir, file.name));
    });
    form.on('error', function(err) {
        console.log('An error has occured: \n' + err);
    });
    form.on('end', function() {
        res.end('success');
    });

    form.parse(req);

});

app.post('/upload/:service/detailed', function(req, res) {
    var service = req.params.service;
    console.log(req.body);
    res.sendStatus(200);
});

app.get('/restart/:service', function(req, res){
    var service = req.params.service;

    function puts(error, stdout, stderr) {

    }

    exec(`supervisorctl restart ${service}`, puts);
});

app.get('/stop/:service', function(req, res) {
    var service = req.params.service;

    function puts(error, stdout, stderr) {

    }

    exec(`supervisorctl stop ${service}`, puts);
});

var server = app.listen(3000, function(){
    console.log('Server listening on port 3000');
});