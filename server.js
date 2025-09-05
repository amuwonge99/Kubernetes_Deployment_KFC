const http = require('http');

const server = http.createServer((req, res) => {
  res.end("Welcome to KFC! Did someone order some Kubernetes for Cloud?");
});

server.listen(80, () => {
  console.log("Server running on port 80");
});
