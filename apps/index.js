let express = require('express');
let cors = require('cors');
let app = express();

app.post('/', cors(), function (req, res, next) {
  console.log('get a request:', req);
});

app.listen(8083, function () {
  console.log('CORS-enabled web server listening on port 8083');
});
