
module.exports = (master, source, options={}) ->

  {failure, alert, success, info, debug}  = master.logger
  SimSpark             = require 'simspark'
  {repeat,wait}        = require 'ragtime'
  {mutable, clone}     = require 'evolve'
  substrate            = require 'substrate'
  {P, copy, pretty}    = substrate.common
 
  round2 = (x) -> Math.round(x*100)/100

  EFFECTORS = [
    #      No.   Description          Hinge Joint Perceptor name  Effector name
    'he1'  # 1   Neck Yaw             [0][0]      hj1             he1
    'h2'   # 2   Neck Pitch           [0][1]      hj2             he2
    'lae1' # 3   Left Shoulder Pitch  [1][0]      laj1            lae1
    'lae2' # 4   Left Shoulder Yaw    [1][1]      laj2            lae2
    'lae3' # 5   Left Arm Roll        [1][2]      laj3            lae3
    'lae4' # 6   Left Arm Yaw         [1][3]      laj4            lae4
    'lle1' # 7   Left Hip YawPitch    [2][0]      llj1            lle1
    'lle2' # 8   Left Hip Roll        [2][1]      llj2            lle2
    'lle3' # 9   Left Hip Pitch       [2][2]      llj3            lle3
    'lle4' # 10  Left Knee Pitch      [2][3]      llj4            lle4
    'lle5' # 11  Left Foot Pitch      [2][4]      llj5            lle5
    'lle6' # 12  Left Foot Roll       [2][5]      llj6            lle6
    'rle1' # 13  Right Hip YawPitch   [3][0]      rlj1            rle1
    'rle2' # 14  Right Hip Roll       [3][1]      rlj2            rle2
    'rle3' # 15  Right Hip Pitch      [3][2]      rlj3            rle3
    'rle4' # 16  Right Knee Pitch     [3][3]      rlj4            rle4
    'rle5' # 17  Right Foot Pitch     [3][4]      rlj5            rle5
    'rle6' # 18  Right Foot Roll      [3][5]      rlj6            rle6
    'rae1' # 19  Right Shoulder Pitch [4][0]      raj1            rae1
    'rae2' # 20  Right Shoulder Yaw   [4][1]      raj2            rae2
    'rae3' # 21  Right Arm Roll       [4][2]      raj3            rae3
    'rae4' # 22  Right Arm Yaw        [4][3]      raj4            rae4
  ]



  config =
    server:
      host  : options.server?.host ? "localhost"
      port  : options.port?.port   ? 3100
    game:
      scene : options.game.scene
      team  : options.game?.team   ? "DEFAULT"
      number: options.game?.number ? 0
    engine:
      updateInterval: options.engine?.updateInterval ? 1000
      journalSize   : options.engine?.journalSize    ? 50
      journal       : options.engine?.journal        ? []

  # Errors have a cost
  health = 10000
  ERR = substrate.errors (value, msg) -> health -= value ; msg

  journal = config.engine.journal

  simspark = new SimSpark config.server.host, config.server.port

  simspark.on 'connect', ->
    success "connected! sending messages.."

    t = 0.0

    # SEND INITIALIZATION DATA TO SIMULATION
    simspark.send [
      [ "scene", config.game.scene ]
      [ "init", [ "unum", config.game.number ], [ "teamname", config.game.team ] ]
    ]

      # beam effector, to position a player
      #sim.send ['beam', 10.0, -10.0, 0.0 ]

    simspark.on 'data', (events) ->

      console.log "events: #{pretty events }"

      debug "received new events.. (t: 0)" if P 0.10
      #if P 0.05
      #  debug "received " + pretty events
      # we intercept special/important events, to know when to stop
      #for p in events
      #  if p[0] in ['GS','AgentState']
      #    for kv in p[1..]
      #      state[kv[0]] = kv[1]

      # ADD TO THE GAME EVENTS JOURNAL
      journal.unshift events
      journal.pop() if journal.length > config.engine.journalSize

    run = yes
    simspark.on 'end', -> 
      alert "disconnected from server"
      run = no

    simspark.send [
      ['say', "hello world"]
      ['syn'] # sync agent mode - ignored if server is in RT mode
    ]

    S = for i in [0...22]
      0.0

    do main = ->
      messages = []
      ##############
      # CLEAN EXIT #
      ##############
      unless run
        alert "exiting"
        simspark.destroy()
        journal = []
        # TODO: send message to host?
        master.send die: 0
        wait(500) -> process.exit 0
        return

      #############
      # MAIN CODE #
      #############

      if P mutable 0.20
        alert "reproducing"
        clone 
          src       : source
          ratio     : 0.01
          iterations:  2
          onComplete: (src) ->
            debug "sending fork event"
            master.send fork: src

      messages = []

      #out.push ['lae3', 5.3]

      # hello world
      U = for i in [0...22]
        S[i]

      U[4] += Math.random() * 2 - 1

      U[5] += Math.random() * 2 - 1

      U[10] += Math.random() * 2 - 1


      # check if some effectors changed, only send changes over the network
      for i in [0...U.length]
        U[i] = round2 U[i] # round the value to 2 decimals
        # if value changed, we updated SPEEDS and sned an update message
        if S[i] isnt U[i]
          S[i] = U[i]
          messages.push [ EFFECTORS[i], S[i] ]

      debug "messages: " + pretty messages
      #simspark.send messages

      wait(config.engine.updateInterval) main

  {}
