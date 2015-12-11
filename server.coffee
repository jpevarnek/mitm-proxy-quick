port = 8081

Proxy = require('http-mitm-proxy')
proxy = Proxy()

ourLog = console.log
console.log = () -> null
console.error = () -> null

proxy.onError (ctx, err) ->
  console.error('proxy error:', err)

process.on 'uncaughtException', (err) ->
  console.log('Caught exception: ' + err)


proxy.use(Proxy.gunzip)

proxy.onRequest (ctx, next) ->
  chunks = []

  if ctx.clientToProxyRequest.url == '/'
    ourLog('Visit detected to ' + ctx.clientToProxyRequest.headers.host)

  if ctx.clientToProxyRequest.headers.host == 'www.nytimes.com'
    ourLog('Blocking access to the New York Times')
    ctx.proxyToClientResponse.write('<h1>This website has been blocked</h1>')
    return

  if ctx.clientToProxyRequest.headers.host != 'www.cfr.org' || ctx.clientToProxyRequest.url != '/'
    return next()


  ourLog('Visit to cfr.org detected, injecting fake story')

  ctx.onResponseData (ctx, chunk, next) ->
    chunks.push(chunk)
    return next(null, '')

  ctx.onResponseEnd (ctx, next) ->
    body = Buffer.concat(chunks)
    if ctx.serverToProxyResponse.headers['content-type'] && ctx.serverToProxyResponse.headers['content-type'].indexOf('text/html') == 0
      body = body.toString()
        .replace(/North Korean/g, 'Qumari')
        .replace(/North Korea/g, 'Qumar')
        .replace('Weighing U.S. Options Toward Qumar', 'U.S. Begins Military Campaign Against Qumar')
        .replace('To stop the Qumari nuclear threat, the United States should increase pressure on Pyongyang, pursue five-party talks, and encourage China and Russia to press the regime on denuclearization', 'To stop the Qumari nuclear threat, the United States will increase pressure on Pyongyang with the deployment of three carrier strike groups and 150,000 soldiers')
        .replace('http://i.cfr.org/content/publications/images/North_Korea_Snyder.jpg', 'http://www.theblaze.com/wp-content/uploads/2011/12/fleet-of-ships.jpg')

    ctx.proxyToClientResponse.write(body)
    return next()

  next()

proxy.listen({ port })

console.log('listening on ' + port)
