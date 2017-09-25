var express = require('express');
var bodyParser = require('body-parser');
var app = express();
var path = require('path');
var formidable = require('formidable');
var fs = require('fs');
var exec = require('child_process').exec;
var roleApi = require('./roleApiJS.js');

var token;

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

app.get('/generateSpaces/:auth', function(req, res) {
    var auth = req.params.auth;
    var api = new roleApi("http://127.0.0.1:8073/",auth)

    //CAEMicroservice
    console.log("Creating microservice space")
    api.createSpace("CAEMicroservice").then((res)=> {
        api.addWidgetToSpace("CAEMicroservice","","http://localhost:8081/widget.xml")
        api.addWidgetToSpace("CAEMicroservice","","http://localhost:8081/attribute.xml")
        api.addWidgetToSpace("CAEMicroservice","","http://localhost:8081/activity.xml")
        api.addWidgetToSpace("CAEMicroservice","","http://localhost:8081/palette.xml")
        api.addWidgetToSpace("CAEMicroservice","","http://localhost:8001/microservicePersistenceWidget/widget.xml")
        api.addWidgetToSpace("CAEMicroservice","","http://localhost:8001/liveCodeEditorWidget/MicroserviceEditorWidget.xml")
    })
    .catch((err) => {
        res.sendStatus(500);
    });
    
    //CAEFrontend
    console.log("Creating frontend space")
    api.createSpace("CAEFrontend").then((res) => {
        api.addWidgetToSpace("CAEFrontend","","http://localhost:8081/widget.xml")
        api.addWidgetToSpace("CAEFrontend","","http://localhost:8081/attribute.xml")
        api.addWidgetToSpace("CAEFrontend","","http://localhost:8081/activity.xml")
        api.addWidgetToSpace("CAEFrontend","","http://localhost:8081/palette.xml")
        api.addWidgetToSpace("CAEFrontend","","http://localhost:8001/frontendComponentPersistenceWidget/widget.xml")
        api.addWidgetToSpace("CAEFrontend","","http://localhost:8001/liveCodeEditorWidget/FrontendEditorWidget.xml")
        api.addWidgetToSpace("CAEFrontend","","http://localhost:8001/liveCodeEditorWidget/LivePreviewWidget.xml")
    })
    .catch((err) => {
        res.sendStatus(500);
    });;


    //CAEApplication
    console.log("Creating application space")
    api.createSpace("CAEApplication").then((res) => {
        api.addWidgetToSpace("CAEApplication","","http://localhost:8081/widget.xml")
        api.addWidgetToSpace("CAEApplication","","http://localhost:8001/frontendComponentSelectWidget/widget.xml")
        api.addWidgetToSpace("CAEApplication","","http://localhost:8001/microserviceSelectWidget/widget.xml")
        api.addWidgetToSpace("CAEApplication","","http://localhost:8001/applicationPersistenceWidget/widget.xml")
    })
    .catch((err) => {
        res.sendStatus(500);
    });;

    console.log(auth);
    res.sendStatus(200);
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
    var path = "";
    if (service === "model") {
        path = '/CAE/etc/i5.las2peer.services.modelPersistenceService.ModelPersistenceService.properties'
    }   else if (service === "code") {
        path = '/CAE/etc/i5.las2peer.services.codeGenerationService.CodeGenerationService.properties';
    }   else if (service === "web") {
        path = '/CAE/etc/i5.las2peer.webConnector.WebConnector.properties';
    }

    fs.truncate(path, 0, function() {
            var content = "";
            req.body.forEach(function(element) {
                content += (element["name"] + "=" + element["value"] + "\r\n");              
            }, this);
            fs.writeFile(path, content, function() {
                    res.sendStatus(200);
            });
        });
});

app.get('/upload/:service/detailed', function(req, res) {
    var service = req.params.service;
    
    var readContent = function(err, data){
        if (err) {
            console.log(err);
            return null;
        }
        data = data.trim().split("\n");
        var propertyDict = {};
        data.forEach(function(element) {
            var innerArr = element.split("=");
            //console.log(innerArr);
            var key = innerArr[0].replace(/[\n\r]/g, '').trim();
            var value = innerArr[1].replace(/[\n\r]/g, '').trim();
            propertyDict[key] = value;
        }, this);
        //console.log(propertyDict);
        return propertyDict;
    };

    var path = "";
    if (service === "model") {
        path = '/CAE/etc/i5.las2peer.services.modelPersistenceService.ModelPersistenceService.properties'
    }   else if (service === "code") {
        path = '/CAE/etc/i5.las2peer.services.codeGenerationService.CodeGenerationService.properties';
    }   else if (service === "web") {
        path = '/CAE/etc/i5.las2peer.webConnector.WebConnector.properties';
    }
    fs.readFile(path, 'utf-8' ,(err, data) => {
        var result = readContent(err, data);
        res.setHeader('Content-Type', 'application/json');
        res.send(JSON.stringify(result));
    });   
})

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

app.get('/savetoken/:auth', function(req, res){
    token = req.params.auth;
    res.sendStatus(200);
});

app.get('/gettoken', function(req, res){
    if(token) {
        res.send(token);
    }
});

var server = app.listen(3000, function(){
    console.log('Server listening on port 3000');
});