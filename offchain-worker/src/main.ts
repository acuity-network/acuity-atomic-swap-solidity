import express from 'express'
let app = express()
import { ApiPromise, WsProvider } from '@polkadot/api'
import BN from 'bn.js'

let api: any


async function startServer() {
  app.get('/', async function (req: any, res: any) {
    res.json({
      totalIssuance: (await api.query.balances?.totalIssuance()).div(new BN('1000000000000000000')).toString(),
    })
  })

  app.listen(4000, function () {
    console.log('Acuity off-chain worker listening on port 4000.')
  })
}

async function start() {

  let wsProvider = new WsProvider('wss://acuity.social:9961')
  ApiPromise.create({ provider: wsProvider }).then(async newApi => {
    api = newApi
    await api.isReady

    // Retrieve the chain & node information information via rpc calls
      const [chain, nodeName, nodeVersion] = await Promise.all([
        api.rpc.system.chain(),
        api.rpc.system.name(),
        api.rpc.system.version()
      ]);

      console.log(`You are connected to chain ${chain} using ${nodeName} v${nodeVersion}`);
  })

  startServer()
}

start()
