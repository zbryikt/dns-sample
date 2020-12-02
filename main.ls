require! <[dns2 os]>

get-ip = -> new Promise (res, rej) ->
  ifaces = os.networkInterfaces!
  lc = {alias: 0}
  Object.keys(ifaces).forEach (ifname) ->
    lc.alias = 0
    if lc.done => return
    ifaces[ifname].forEach (iface) ->
      if lc.done => return
      # skip over internal (i.e. 127.0.0.1) and non-ipv4 addresses
      if \IPv4 !== iface.family or iface.internal !== false => return
      if ifname == \en0 => res(iface.address); lc.done = true; return
      #if lc.alias >= 1 => console.log "#{ifname}:#alias", iface.address
      #else console.log ifname, iface.address
      lc.alias++
  if !lc.done => rej new Error("not found")

get-ip!
  .then (ip) ->
    server = dns2.createServer((req, send) ->
      console.log "incoming query: ", name = req.questions.0.name
      console.log "response to #ip"
      res = new dns2.Packet req
      res.header.qr = 1
      res.header.aa = 1
      res.answers.push do
        address: '127.0.0.1' # some ip address ...
        type: dns2.Packet.TYPE.A
        class: dns2.Packet.CLASS.IN
      send res

    ).listen 53
    console.log "DNS running on port 53 @ #{ip} ..."
