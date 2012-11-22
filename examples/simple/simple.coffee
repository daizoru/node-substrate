#!/usr/bin/env coffee
{inspect,log} = require 'util'
{puts} = require 'sys'

substrate = require 'substrate'

# extract only the tools we need from substrate
{Stats, Simple} = substrate
{trivial, minor, major} = substrate.errors
{P, copy} = substrate.common
{mutate,mutable}  = substrate.evolve
system = new System

  # what connect the agent to the external world
  connector: require './interfaces/simulation'

  # stats: utility to extract some stats for each agent
  stats: 
    balance: (agent) -> agent.balance

  # agent factory: generate a list of agents
  factory: do -> 

    # making of 10 agents
    for i in [0...10]

      # internal, private state
      id: i
      data: {}

      # update function which does nothing for the moment the update function,
      # should always be the same, while the connector can change
      # this way, you develop your system once (eg. in a simulation env).
      # and just have to replace the connector to connect to the production env.
      update: ({}) ->
        x = mutable 100
        {}

system.start()
