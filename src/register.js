/**
 * create a new account for a given wallet, for this demo only one process per jwk.
 * 
 * register -w ./wallet.json
 * 
 */

import minimist from 'minimist'
import { of, Resolved, Rejected, fromPromise } from 'hyper-async'
import * as utils from './hyper-utils.js'

const AOS_MODULE = process.env.AOS_MODULE || 'qUY9MrMx5tjlOr5BNMWllMwmrwclJc2mI8IZ4LxiOKU'

export function register(jwk, services) {
  const getAddress = ctx => services.address(ctx.jwk).map(address => ({ address, ...ctx }))
  const findProcess = ({ jwk, address, name }) => {
    return services.gql(queryForAOS(name), { owners: [address] })
      .map(utils.path(['data', 'transactions', 'edges']))
      .bichain(
        _ => Rejected({ jwk, address, name }),
        results => results.length > 0 ? Resolved(results) : Rejected({ jwk, address, name })
      )
  }

  const createProcess = ({ jwk, address, name }) => {

    let tags = [
      { name: 'App-Name', value: 'aos' },
      { name: 'Name', value: name }
    ]
    const argv = minimist(process.argv.slice(2))
    if (argv.cron) {
      if (/^\d+\-(second|seconds|minute|minutes|hour|hours|day|days|month|months|year|years|block|blocks)$/.test(argv.cron)) {
        tags = [...tags,
        { name: 'Cron-Interval', value: argv.cron },
        { name: 'Cron-Tag-Action', value: 'Cron' }
        ]
      } else {
        throw Error('Invalid cron flag!')
      }
    }

    return services.spawnProcess({
      wallet: jwk,
      src: AOS_MODULE,
      tags
    })
  }

  const alreadyRegistered = results => Resolved(results[0].node.id)
  const argv = minimist(process.argv.slice(2))
  const name = argv._[0] || 'default'

  return of({ jwk, name })
    .chain(getAddress)
    .chain(findProcess)

    .bichain(createProcess, alreadyRegistered)
}

function queryForAOS(name) {
  return `query ($owners: [String!]!) {
    transactions(
      first: 1,
      owners: $owners,
      tags: [
        { name: "Data-Protocol", values: ["ao"] },
        { name: "Type", values: ["Process"]},
        { name: "Module", values: ["${AOS_MODULE}"]},
        { name: "Name", values: ["${name}"]}
      ]
    ) {
      edges {
        node {
          id
        }
      }
    }
  }`
}
