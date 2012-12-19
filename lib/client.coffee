# TODO: get the url dynamically
socket = io.connect('http://localhost:3005');
socket.on 'data', (data)->
  console.log data
