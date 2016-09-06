var fs = require('fs');
var path = require('path');
var http = require('http');
var textBody = require("body");
var google = require('googleapis');
var googleKey = require('./lookerdata-a86c2ee1f4ac.json');

//Lets define a port we want to listen to
const PORT=2016;

function send(response, statusCode, contentType, body) {
  response.statusCode = statusCode;
  response.setHeader('Content-Type', contentType);
  response.end(body, 'UTF-8');
}

//We need a function which handles requests and send response
function handleRequest(request, response){

  if (request.method == 'GET')
  {
    var filename = request.url;
    if (filename == '/')
        filename = '/index.html';
    var contentType = null;
    switch (filename) {
      case '/index.html':
        contentType = 'text/html';
        break;
      case '/script.coffee':
        contentType = 'text/coffeescript';
        break;
      case '/style.css':
        contentType = 'text/css';
        break;
    }
    if (contentType) {
      filename = path.basename(filename);
      fs.readFile(filename, 'UTF-8', function (err,data) {
        if (err)
          send(response, 500, 'text/plain','Error');
        else
          send(response, 200, contentType, data);
      });
    } else {
      send(response, 404, 'text/plain', 'Not Found');
    }
  }
  else if (request.method == 'POST')
  {
    textBody(request, function(err, body) {

      var lines = body.trim().split('\n');
      var now = new Date();

      try
      {
        var jsonData = lines.map(function (line) {
          var fields = line.split(',');
          if (fields.length < 5)
            throw Error("missing fields")
          var row = {
            json: {
              bowler: fields[0],
              game_number: parseInt(fields[1]),
              frame_number: parseInt(fields[2]),
              ball_number: parseInt(fields[3]),
              pins: fields[4],
              ts: now.getTime()
            }
          };
          return row;
        });
      }
      catch (e)
      {
        response.statusCode = 422;
        response.setHeader("Content-Type", "text/plain");
        response.end("Error parsing data");
      }

      var jwtClient = new google.auth.JWT(googleKey.client_email, null, googleKey.private_key,
          [
            "https://www.googleapis.com/auth/bigquery",
            "https://www.googleapis.com/auth/bigquery.insertdata"
          ], null);

      jwtClient.authorize(function(err, tokens) {
        if (err) {
          console.log(err);
          response.statusCode = 500;
          response.end();
        }

        var bq = google.bigquery({version: 'v2', auth: jwtClient});

        var req = {
          projectId: "lookerdata",
          datasetId: "bowling",
          tableId: "game_balls2",
          auth: jwtClient,
          resource: {"kind": "bigquery#tableDataInsertAllRequest", "rows" : jsonData}
        };
        bq.tabledata.insertAll(req, function(err, result) {
          if (err) {
            console.log(err);
            send(response, 500, 'application/json', JSON.stringify(err));
          }
          else
          {
            send(response, 200, 'application/json', JSON.stringify(jsonData));
            console.log('%d rows uploaded', jsonData.length);
          }
        });
      });
    })
  }
}

//Create a server
var server = http.createServer(handleRequest);

//Lets start our server
server.listen(PORT, function(){
  //Callback triggered when server is successfully listening. Hurray!
  console.log("Server listening on: http://localhost:%s", PORT);
});
