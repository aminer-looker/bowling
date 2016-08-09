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
  if not (position.frame is 10 and getScoreText(game:position.game, frame:10, ball:1) is "X")
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
    scoreText = getScoreText game:position.game, frame:position.frame, ball:1
    return true if scoreText isnt " "
  return false

setFrameScore = (position, value)->
  value = if value is 0 then "" else value

  $("td.g#{position.game}f#{position.frame}").text(value)

setGameScore = (position, value)->
  $("table.game-#{position.game} .score").text(value)

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
      options.push('X') if ball is 1
      options.push('/') if ball is 2

      $select = $("select.g#{game}f#{frame}b#{ball}")
      $select.on 'change', onScoreChanged

      for option in options
        $select.append $("<option value='#{option}'>#{option}</option>")

updateSendScoresLink = ->
  player = getPlayerName()
  date = moment().format "YYYY-MM-DD"

  rows = []
  for game in [1..getGameCount()]
    for frame in [1..10]
      for ball in [1..3]
        scoreText = getScoreText game:game, frame:frame, ball:ball
        continue if scoreText is ' '

        rows.push "#{player}, #{date}, #{game}, #{frame}, #{ball}, #{scoreText}"

  subject = encodeURIComponent "Bowling Scores for #{player}"
  href = "mailto:lloyd@looker.com?subject=#{subject}&body=" + encodeURIComponent rows.join "\n"
  $div = $('div.send-scores')
  $link = $('div.send-scores a')

  if player and rows.length
    $link.attr 'href', href
    $div.removeClass 'disabled'
  else
    $div.addClass 'disabled'
    $link.attr 'href', ''

# Events ###################################################################################################

onPlayerChanged = ->
  updateSendScoresLink()
  return true

onScoreChanged = ->
  refreshScores()
  updateSendScoresLink()
  return true

# Initialization ###########################################################################################

$ ->
  addNewGame()
  updateSendScoresLink()

  $("input.player").focus()
  $("input.player").on "change", onPlayerChanged
  $("button.add-game").on "click", addNewGame
