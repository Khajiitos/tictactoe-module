--[[
    Popups:
    1 - Help popup
    2 - Game over popup
    3 - Would you like to play with the teacher? popup

    Text areas:
    1 - Question mark, opens help
    2 - Currently invited player
    3 - Currently invited player close button
    4 - TTT game's background
    5 - TTT game's header
    6 - TTT game's turn
    7-15 - TTT game's fields
    16 - TTT Playing as X/O
    17 - TTT exit game button
    18-21 - TTT game lines -|-|-
]]

playerGame = {}
playerInvitedPlayer = {}

TicTacToeGame = {
    player1 = '',
    player2 = '',
    turn = 1,
    color = 0xFFFFFF,   
    board = {},
    isWithBot = false,
    gameFinished = false
}

GameFinishReason = {
    PLAYER_QUIT = 0,
    PLAYER_1_WON = 1,
    PLAYER_2_WON = 2,
    DRAW = 3,
    PLAYER_DISCONNECTED = 4
}

function isPlayerHere(playerName)
    return not not tfm.get.room.playerList[playerName]
end

function TicTacToeGame:new(player1, player2)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.board = {}
    o.player1 = player1
    o.player2 = player2
    if player2 ~= nil then
        o.color = math.random(0, 0xFFFFFF)
    else
        o.color = 0x009d9d
    end
    for i = 1, 9 do
        o.board[i] = 0
    end
    return o
end

function TicTacToeGame:start()
    playerInvitedPlayer[self.player1] = nil
    ui.removeTextArea(2, self.player1)
    ui.removeTextArea(3, self.player1)
    tfm.exec.setNameColor(self.player1, self.color)

    if not self.isWithBot then
        playerInvitedPlayer[self.player2] = nil
        tfm.exec.setNameColor(self.player2, self.color)
        ui.removeTextArea(3, self.player2)
        ui.removeTextArea(2, self.player2)
        tfm.exec.movePlayer(self.player1, 380, 200, false, 0, 0, false)
        tfm.exec.movePlayer(self.player2, 420, 200, false, 0, 0, false)
        tfm.exec.setNameColor(self.player2, self.color)
        tfm.exec.linkMice(self.player1, self.player2, true)
    end

    self:initBoard()
end

function TicTacToeGame:opponent(ofPlayer)
    if self.player1 == ofPlayer then
        return self.player2
    elseif self.player2 == ofPlayer then
        return self.player1
    else
        return nil
    end
end

function TicTacToeGame:finish(reason, causingPlayer)
    local finishGameForPlayer = function(player, game)
        for i = 4, 21 do
            ui.removeTextArea(i, player)
        end
        tfm.exec.setNameColor(player, 0xFFFFFF)
    end

    local gameOverPopup = function(playerName, text)
        ui.addPopup(2, 0, '<font size="20"><p align="center"><b>Game over</b></p></font><br><font size="13">' .. text .. "</font>", playerName, 300, 200, 200, true)
    end

    if reason == GameFinishReason.PLAYER_QUIT then
        gameOverPopup(self:opponent(causingPlayer), 'Your opponent left the TicTacToe game.')
    elseif reason == GameFinishReason.PLAYER_1_WON or reason == GameFinishReason.PLAYER_2_WON then
        gameOverPopup(causingPlayer, '<p align="center"><font color="#00FF00"><b>You won! :)</b></font></p>')
        gameOverPopup(self:opponent(causingPlayer), '<p align="center"><font color="#FF0000"><b>You lost! :(</b></font></p>')
        tfm.exec.playEmote(causingPlayer, 1)
        tfm.exec.playEmote(self:opponent(causingPlayer), 2)
    elseif reason == GameFinishReason.DRAW then
        gameOverPopup(self.player1, 'The game ended with a draw.')
        gameOverPopup(self.player2, 'The game ended with a draw.')
        tfm.exec.playEmote(self.player1, 7)
        tfm.exec.playEmote(self.player2, 7)
    elseif reason == GameFinishReason.PLAYER_DISCONNECTED then
        gameOverPopup(self:opponent(causingPlayer), 'Your opponent left the room.')
    end

    self.gameFinished = true
    
    if (isPlayerHere(self.player1)) then finishGameForPlayer(self.player1, self) end
    if (isPlayerHere(self.player2)) then finishGameForPlayer(self.player2, self) end
    playerGame[self.player1] = nil
    playerGame[self.player2] = nil
    tfm.exec.linkMice(self.player1, self.player2, false)
end

function TicTacToeGame:initBoard()
    local initBoardForPlayer = function(player, opponent)
        ui.addTextArea(4, '', player, 200, 50, 400, 300, 0x324650, 0x212F36, 0.9, true)
        ui.addTextArea(5, '<p align="center"><font size="20">Opponent: ' .. opponent .. '</font></p>', player, 200, 50, 400, 30, nil, nil, 0.0, true)
        ui.addTextArea(6, '', player, 200, 80, 400, 30, nil, nil, 0.0, true)
        for i = 0, 2 do
            for j = 0, 2 do
                local id = 7 + (i * 3) + j
                local x = 300 + (j) * 75
                local y = 120 + (i) * 75
                ui.addTextArea(id, '', player, x, y, 50, 50, 0x324650, 0x212F36, 0.95, true)
            end
        end
        ui.addTextArea(18, '', player, 362.5, 110, 1, 225, 0x627680, 0x627680, 1, true)
        ui.addTextArea(19, '', player, 437.5, 110, 1, 225, 0x627680, 0x627680, 1, true)
        ui.addTextArea(20, '', player, 290, 180, 225, 1, 0x627680, 0x627680, 1, true)
        ui.addTextArea(21, '', player, 290, 255, 225, 1, 0x627680, 0x627680, 1, true)
        ui.addTextArea(16, '<p align="center"><font size="18">Playing as: <b>' .. ((self:playerNumber(player) == 1) and 'X' or 'O') ..'</b></font></p>', player, 200, 325, 400, 30, nil, nil, 0.0, true)
        ui.addTextArea(17, '<a href="event:exitGame"><p align="center"><font size="17"><b>Exit</b></font></p></a>', player, 300, 360, 200, 24, 0x324650, 0x212F36, 0.95, true)
    end
    if self.isWithBot then
        initBoardForPlayer(self.player1, 'Teacher')
    else
        initBoardForPlayer(self.player1, self.player2)
        initBoardForPlayer(self.player2, self.player1)
    end
    self:updateBoard()
end

function TicTacToeGame:updateBoard()
    local updateBoardForPlayer = function(player, game)

        local playerNumber = self:playerNumber(player)

        if playerNumber == self.turn then
            ui.updateTextArea(6, '<p align="center"><font size="16" color="#00FF00">Your turn!</font></p>', player)
        else
            ui.updateTextArea(6, '<p align="center"><font size="16" color="#FF0000">Opponent\'s turn.</font></p>', player)
        end

        for i = 0, 2 do
            for j = 0, 2 do
                local id = 7 + (i * 3) + j
                local char = ''
                if self.board[id - 6] == 1 then
                    char = 'X'
                elseif self.board[id - 6] == 2 then
                    char = 'O'
                else
                    char = ' '
                end

                local color = "#FFFFFF"
                if playerNumber == self.board[id - 6] then
                    color = "#00FF00"
                else
                    color = "#FF0000"
                end
                local aStart = ''
                local aEnd = ''
                if self.board[id - 6] == 0 then
                    aStart = '<a href="event:field' .. (id - 6) .. '">'
                    aEnd = '</a>'
                end
                ui.updateTextArea(id, aStart .. '<p align="center"><font size="34" color="' .. color ..'"><b>' .. char .. '</b></font></p>' .. aEnd, player)
            end
        end
    end
    if self.isWithBot then
        updateBoardForPlayer(self.player1, self)
    else
        updateBoardForPlayer(self.player1, self)
        updateBoardForPlayer(self.player2, self)
    end
end

function TicTacToeGame:setField(fieldNum, fieldVal)
    self.board[fieldNum] = fieldVal

    local winnerCheck = self:winnerCheck()

    if winnerCheck ~= 0 then
        if winnerCheck == 1 then self:finish(GameFinishReason.PLAYER_1_WON, self.player1)
        elseif winnerCheck == 2 then self:finish(GameFinishReason.PLAYER_2_WON, self.player2)
        elseif winnerCheck == 3 then self:finish(GameFinishReason.DRAW, nil) 
        end
    else
        self:updateBoard()
    end
end

function TicTacToeGame:playerNumber(playerName)
    if playerName == self.player1 then
        return 1
    elseif playerName == self.player2 then
        return 2
    else
        print('Bug: Attempted to check the player number of a player in a game they\'re not in.')
        return -1
    end
end

function TicTacToeGame:playerName(playerNumber)
    if playerNumber == 1 then
        return self.player1
    elseif playerNumber == 2 then
        return self.player2
    else
        print('Bug: Attempted to check the player name of a player in a game they\'re not in.')
        return nil
    end
end

function TicTacToeGame:attemptPlaceOnField(playerNumber, fieldNum)
    if playerNumber == self.turn then
        if self.board[fieldNum] == 0 then
            if not self.isWithBot then
                if self.turn == 1 then
                    self.turn = 2
                else
                    self.turn = 1
                end
            end
            self:setField(fieldNum, playerNumber)

            if self.isWithBot and not self.gameFinished then
                self:placeSomethingAsBot()
            end
        end
    end
end

function TicTacToeGame:placeSomethingAsBot()
    emptyFields = {}

    for fieldNum, fieldVal in ipairs(self.board) do
        if fieldVal == 0 then
            emptyFields[#emptyFields + 1] = fieldNum
        end
    end

    --[[
        If the bot can win in its turn, it will
        If the opponent would win in their next turn, the bot will block them
        Else the bot will place randomly

        so many loops smh
    ]]

    for i, fieldNum in ipairs(emptyFields) do
        self.board[fieldNum] = 2
        if self:winnerCheck() == 2 then
            self:setField(fieldNum, 2)
            return
        else
            self.board[fieldNum] = 0
        end
    end

    for i, fieldNum in ipairs(emptyFields) do
        self.board[fieldNum] = 1
        if self:winnerCheck() == 1 then
            self:setField(fieldNum, 2)
            return
        else
            self.board[fieldNum] = 0
        end
    end

    self:setField(emptyFields[math.random(1, #emptyFields)], 2)
end

function TicTacToeGame:winnerCheck()
    --[[
        Returns 0 if no winner yet
        1 if player 1
        2 if player 2
        3 if draw

        TODO: Make this detect draws without it having all fields occupied
    ]]
    checkResult = 0

    local check = function(board, a, b, c)
        return (board[a] == board[b] and board[b] == board[c]) and board[a] or 0
    end

    local possibilities = {
        {1, 2, 3},
        {4, 5, 6},
        {7, 8, 9},
        {1, 4, 7},
        {2, 5, 8},
        {3, 6, 9},
        {1, 5, 9},
        {3, 5, 7}
    }

    for i, possibility in pairs(possibilities) do
        local checkResult = check(self.board, possibility[1], possibility[2], possibility[3])
        if checkResult ~= 0 then
            return checkResult
        end
    end

    for i = 1, 9 do
        if self.board[i] == 0 then
            return 0
        end
    end

    return 3
end

function openHelpPopup(playerName)
    local text = [[
<p align='center'><font size='20'>TicTacToe</font></p>
Welcome to the module!
Here you can play TicTacToe with another player in the room.

To invite a player to play with you, either click on the player or use the command <b>!invite <i>Player#XXXX</i></b>.
Or you could play with the Teacher by clicking on her.

After two players have invited themselves, or you chose to play with the teacher, a board will appear.
If it's your turn, you can either click on a field or use 1-9 keys on your keyboard to select a field.

<b>Good luck!</b>
<p align='right'><b><i>Made by Khajiitos#0000</i><b></p>]]
    ui.addPopup(1, 0, text, playerName, 200, 75, 400, true)
end

function eventChatCommand(playerName, message)

    local args = {}
    for arg in message:gmatch("%S+") do
        args[#args + 1] = arg
    end
    local command = table.remove(args, 1)

    if command == 'help' then
        openHelpPopup(playerName)
    elseif command == 'invite' then
        if not playerGame[playerName] and #args > 0 and tfm.get.room.playerList[args[1]] then
            invitePlayer(playerName, args[1])
        end
    end
end

function eventTextAreaCallback(textAreaID, playerName, callback)
    if callback == "helpQuestionMark" then
        openHelpPopup(playerName)
    elseif callback == "exitGame" then
        if playerGame[playerName] then
            playerGame[playerName]:finish(GameFinishReason.PLAYER_QUIT, playerName)
        end
    elseif callback == "uninvitePlayer" then
        playerInvitedPlayer[playerName] = nil
        ui.removeTextArea(2, playerName)
        ui.removeTextArea(3, playerName)
    end

    for match in callback:gmatch("field(%d+)") do
        if playerGame[playerName] then
            playerGame[playerName]:attemptPlaceOnField(playerGame[playerName]:playerNumber(playerName), tonumber(match))
        end
        return
    end
end

function initPlayer(playerName)
    for i = 49, 57 do -- 1-9
        system.bindKeyboard(playerName, i, true, true)
    end
    system.bindKeyboard(playerName, 72, true, true) -- H
    system.bindMouse(playerName, true)
    tfm.exec.setNameColor(playerName, 0xFFFFFF)
    ui.addTextArea(1, "<a href='event:helpQuestionMark'><p align='center'><font size='16'><b>?</b></font></p></a>", playerName, 760, 35, 25, 25, 0x111111, 0x111111, 1.0, true)
end

function eventPlayerDied(playerName)
    tfm.exec.respawnPlayer(playerName)
    if playerGame[playerName] then
        tfm.exec.setNameColor(playerName, playerGame[playerName].color)
    else
        tfm.exec.setNameColor(playerName, 0xFFFFFF)
    end
end

function eventNewPlayer(playerName)
    initPlayer(playerName)
    tfm.exec.respawnPlayer(playerName)
    spawnTeacher()
end

function eventPlayerLeft(playerName)
    if playerGame[playerName] then
        playerGame[playerName]:finish(GameFinishReason.PLAYER_DISCONNECTED, playerName)
    end
end

function eventKeyboard(playerName, keyCode, down, xPlayerPosition, yPlayerPosition)
    if keyCode == 72 then -- H
        openHelpPopup(playerName)
    elseif keyCode >= 49 and keyCode <= 57 then -- 1-9
        if playerGame[playerName] then
            playerGame[playerName]:attemptPlaceOnField(playerGame[playerName]:playerNumber(playerName), keyCode - 48)
        end
    end
end

function eventMouse(playerName, xMousePosition, yMousePosition)
    if not playerGame[playerName] then
        local lowestDistance = 50
        local targettedPlayer = nil
        for player, playerData in pairs(tfm.get.room.playerList) do
            if playerName ~= player then
                local distance = math.sqrt((xMousePosition - playerData.x) ^ 2 + (yMousePosition - playerData.y) ^ 2)
                if distance < lowestDistance then
                    lowestDistance = distance
                    targettedPlayer = player
                end
            end
        end
        if targettedPlayer ~= nil then
            invitePlayer(playerName, targettedPlayer)
        end
    end
end

function invitePlayer(inviter, invitee)
    if playerInvitedPlayer[invitee] == inviter then
        local game
        if math.random(1, 2) == 1 then
            game = TicTacToeGame:new(invitee, inviter)
        else
            game = TicTacToeGame:new(inviter, invitee)
        end
        playerGame[game.player1] = game
        playerGame[game.player2] = game
        game:start()
    else
        playerInvitedPlayer[inviter] = invitee
        ui.addTextArea(2, '<b>Invited player: </b>' .. invitee, inviter, 45, 35, 0, 25, 0x000000, 0x222222, 0.6, true)
        ui.addTextArea(3, '<a href="event:uninvitePlayer"><p align="center"><font color="#FFFFFF"><b>X</b></font></p></a>', inviter, 15, 35, 18, 18, 0xAA0000, 0x222222, 0.8, true)
    end
end

tfm.exec.disableAfkDeath(true)
tfm.exec.disableAutoNewGame(true)
tfm.exec.disableAutoScore(true)
tfm.exec.disableAutoShaman(true)
tfm.exec.disableAutoTimeLeft(true)
tfm.exec.disablePhysicalConsumables(true)
tfm.exec.newGame(7923834, false)
tfm.exec.setGameTime(0, true)
system.disableChatCommandDisplay("invite", true)
system.disableChatCommandDisplay("help", true)
ui.setMapName("TicTacToe");

function spawnTeacher()
    tfm.exec.addNPC('Teacher', {
        title = 327,
        lookLeft = false,
        interactive = true,
        female = true,
        look = '28;0,8,0,72,0,101,0,0,0',
        x = 25,
        y = 338
    })
end

function eventTalkToNPC(playerName, npcName)
    if npcName == 'Teacher' then
        if not playerGame[playerName] then
            ui.addPopup(3, 1, "<p align='center'><font size='18'><b>Teacher</b></font></p><p align='center'>Would you like to play with the teacher?</p>", playerName, 250, 175, 300, true)
        end
    end
end

function eventPopupAnswer(popupID, playerName, answer)
    if popupID == 3 then
        if answer == 'yes' then
            if not playerGame[playerName] then
                local game = TicTacToeGame:new(playerName, nil)
                game.isWithBot = true
                playerGame[game.player1] = game
                game:start()
            end
        end
    end
end

for playerName in pairs(tfm.get.room.playerList) do
    initPlayer(playerName)
end

spawnTeacher()