var express = require('express');
var app = express();
var path = require('path');
var formidable = require('formidable');
var fs = require('fs');

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', function(req, res) {
    res.sendFile(path.join(__dirname, 'views/index.html'));
});

app.post('/upload/:service', function(req, res) {
    var form = new formidable.IncomingForm();
    form.multiples = true;
    var service = req.params.service;
    form.uploadDir = path.join(__dirname, `/uploads/${service}`);
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

var server = app.listen(3000, function(){
    console.log('Server listening on port 3000');
});