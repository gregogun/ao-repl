const AoLoader = require('@permaweb/ao-loader')
const fs = require('fs')
const wasm = fs.readFileSync('./process.wasm')


async function test() {
  const handle = await AoLoader(wasm)
  // add handler
  let response = await handle(null, {
    Target: "PROCESS",
    Tags: [
      { name: 'Action', value: 'Eval' }
    ],
    Data: `
    Handlers.add(
      "info",
      Handlers.utils.hasMatchingTag("Action", "Info"),
      function (msg)
        Handlers.utils.reply("pong")(msg)
      end
    )`
  }, { Process: { Id: 'FOO', Tags: [] } })

  // send message
  let response2 = await handle(response.Memory, {
    Target: 'PROCESS',
    From: 'FOO',
    Tags: [
      { name: 'Action', value: 'Info' }
    ]
  }, { Process: { Id: 'FOO', Tags: [] } })

  console.log(response2.Output)
  // confirm response
  console.log(response2.Output)
  console.log(JSON.stringify(response2.Messages))
  let response3 = await handle(response2.Memory, {
    Target: 'PROCESS',
    From: 'FOO',
    Tags: [
      { name: 'Action', value: 'Info' }
    ]
  }, { Process: { Id: 'FOO', Tags: [] } })
  // confirm response
  console.log(response3.Output)
  console.log(response3.Messages)
  console.log(JSON.stringify(response3.Messages))

}

test()