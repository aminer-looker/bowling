# Computation ##############################################################################################

computeBallScore = (position)->
  return 0 unless position?

  scoreText = getScoreText position
  score = getBasePoints position

  if scoreText is 'X'
    score += getBasePoints getNextBall position
    score += getBasePoints getNextBall position, 2
  else if scoreText is '/'
    score += getBasePoints getNextBall position
  else if scoreText is ' '
    return 0

  return score

computeFrameScore = (position)->
  return 0 unless position?

  score = 0
  score += computeBallScore game:position.game, frame:position.frame, ball:1
  if not (position.frame is 10 and getScoreText(game:position.game, frame:10, ball:2) is "X")
    score += computeBallScore game:position.game, frame:position.frame, ball:2

  if hasPlayedFrame(position) and position.frame > 1
    score += computeFrameScore game:position.game, frame:position.frame - 1

  return score

computeGameScore = (position)->
  return 0 unless position?

  score = 0
  for frame in [1..10]
    score = Math.max score, computeFrameScore game:position.game, frame:frame

  return score

refreshScores = ->
  for game in [1..getGameCount()]
    setGameScore game:game, computeGameScore game:game

    for frame in [1..10]
      position = game:game, frame:frame
      setFrameScore position, computeFrameScore position

# Data Extraction ##########################################################################################

gatherData = ->
  player = getPlayerName()

  rows = []
  for game in [1..getGameCount()]
    for frame in [1..10]
      for ball in [1..3]
        scoreText = getScoreText game:game, frame:frame, ball:ball
        continue if scoreText is ' '

        rows.push "#{player}, #{game}, #{frame}, #{ball}, #{scoreText}"
  data = rows.join "\n"
  return data

getBasePoints = (position)->
  scoreText = getScoreText position

  score = 0
  switch scoreText
    when ' ' then score = 0
    when '0' then score = 0
    when '1' then score = 1
    when '2' then score = 2
    when '3' then score = 3
    when '4' then score = 4
    when '5' then score = 5
    when '6' then score = 6
    when '7' then score = 7
    when '8' then score = 8
    when '9' then score = 9
    when '/' then score = 10
    when 'X' then score = 10

  if scoreText is '/'
    score -= getBasePoints game:position.game, frame:position.frame, ball:position.ball - 1

  return score

getGameCount = ->
  $(".game").length

getGameNumber = ->
  $(".game-number").val()

getScoreText = (position)->
  return ' ' unless position
  scoreText = $("select.g#{position.game}f#{position.frame}b#{position.ball}").val()
  return ' ' unless scoreText
  return scoreText

getNextBall = (position, count=1)->
  nextPosition = game:position.game, frame:position.frame, ball:position.ball
  while count > 0
    nextPosition.ball += 1
    if nextPosition.frame isnt 10 and nextPosition.ball > 2
      nextPosition.ball = 1
      nextPosition.frame += 1

    if getScoreText(nextPosition) isnt ' '
      count -= 1

    return null if nextPosition.frame > 10 or nextPosition.ball > 3

  return nextPosition

getPlayerName = ->
  return $("input.player").val()

hasPlayedFrame = (position)->
  for ball in [1..3]
    scoreText = getScoreText game:position.game, frame:position.frame, ball:ball
    return true if scoreText isnt ' '
  return false

setEnabled = (position, enabled) ->
  $el = $("select.g#{position.game}f#{position.frame}b#{position.ball}")
  if enabled
    $el.removeAttr 'disabled'
  else
    $el.attr 'disabled', 'disabled'

setFrameScore = (position, value)->
  value = if value is 0 then "" else value

  $("td.g#{position.game}f#{position.frame}").text(value)

setGameScore = (position, value)->
  $("table.game-#{position.game} .score").text(value)

setBallScore = (position, text)->
  return unless position
  $("select.g#{position.game}f#{position.frame}b#{position.ball}").val text

setStatusMessage = (status, message)->
  $message = $(".status-message")
  $message.removeClass()
  $message.addClass 'status-message'
  $message.addClass status
  $message.text message

updateSendScoresButton = ->
  player = getPlayerName()
  data = gatherData()
  game = getGameNumber()

  $button = $('.send-scores')
  $button.prop 'disabled', not (player and game and data)

# DOM Manipulation #########################################################################################

addNewGame = ->
  gameNumber = getGameCount() + 1
  $game = $("<table class='game game-#{gameNumber}' cellspacing='0' cellpadding='0'></table>")
  $(".game-list").append $game

  $game.append $("""
    <caption>Game #{gameNumber}</caption>
    <tr class="header">
      <td colspan="2">1</td>
      <td colspan="2">2</td>
      <td colspan="2">3</td>
      <td colspan="2">4</td>
      <td colspan="2">5</td>
      <td colspan="2">6</td>
      <td colspan="2">7</td>
      <td colspan="2">8</td>
      <td colspan="2">9</td>
      <td colspan="3">10</td>
      <td>Score</td>
    </tr>
  """)

  $ballRow = $("<tr></tr>")
  $game.append $ballRow

  for frameIndex in [1..10]
    ballList = if frameIndex is 10 then [1..3] else [1..2]
    for ballIndex in ballList
      $ballRow.append $("""
        <td class='ball'>
          <select class='g#{gameNumber}f#{frameIndex}b#{ballIndex}'></select>
        </td>
      """)

  $ballRow.append $("<td class='score' rowspan='2'></td>")

  $frameRow = $("<tr></tr>")
  $game.append $frameRow

  for frameIndex in [1..10]
    colspan = if frameIndex is 10 then 3 else 2
    $frameRow.append("""
      <td class='g#{gameNumber}f#{frameIndex}' colspan='#{colspan}'>&nbsp;</td>
    """)

  addScoreSelect gameNumber

addScoreSelect = (game)->
  for frame in [1..10]
    ballList = if frame is 10 then [1..3] else [1..2]
    for ball in ballList
      options = []
      options.push(' ')
      options.push('0')
      options.push('1')
      options.push('2')
      options.push('3')
      options.push('4')
      options.push('5')
      options.push('6')
      options.push('7')
      options.push('8')
      options.push('9')
      options.push('X') if ball is 2
      options.push('/') if ball is 2

      $select = $("select.g#{game}f#{frame}b#{ball}")
      $select.on 'change', onScoreChanged

      for option in options
        $select.append $("<option value='#{option}'>#{option}</option>")

refreshSelectors = ->
  for game in [1..getGameCount()]
    for frame in [1..10]
      for ball in [1..3]
        setEnabled {game:game, frame:frame, ball:ball}, true

      priorFrame = frame - 1
      if priorFrame > 0 and getScoreText(game:game, frame:priorFrame, ball:2) is ' '
        for ball in [1..3]
          setEnabled {game:game, frame:frame, ball:ball}, false

      if frame isnt 10 and getScoreText(game:game, frame:frame, ball:2) is 'X'
        setBallScore {game:game, frame:frame, ball:1}, ' '
        setEnabled {game:game, frame:frame, ball:1}, false

uploadScores = ->
  data = gatherData()
  console.log "attempting to send data:\n#{data}"

  # setTimeout onUploadComplete, 500

  $.ajax(
    contentType: 'text/plain'
    data: data
    error: onUploadError
    method: 'POST'
    success: onUploadComplete
    timeout: 5000
    url: '/'
  )

# Events ###################################################################################################

onGameNumberChanged = ->
  updateSendScoresButton()
  return true

onPlayerChanged = ->
  updateSendScoresButton()
  return true

onScoreChanged = ->
  refreshSelectors()
  refreshScores()
  updateSendScoresButton()
  return true

onSendScores = ->
  uploadScores()

onUploadComplete = ->
  setStatusMessage 'success', 'Upload complete!'

onUploadError = (xhr, status, error)->
  setStatusMessage 'error', error

# Initialization ###########################################################################################

$ ->
  addNewGame()
  refreshSelectors()
  updateSendScoresButton()

  $("input.player").focus()
  $("input.player").on "change", onPlayerChanged
  $(".game-number").on "change", onGameNumberChanged
  $("button.send-scores").on "click", onSendScores
