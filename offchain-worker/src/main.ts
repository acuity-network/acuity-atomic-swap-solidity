import express from 'express'
let app = express()


async function startServer() {
  app.get('/', async function (req: any, res: any) {
    res.json({
      blockNumber: 1234,
    })
  })

  app.listen(4000, function () {
    console.log('Acuity off-chain worker listening on port 4000.')
  })
}

async function start() {
  startServer()
}

start()
