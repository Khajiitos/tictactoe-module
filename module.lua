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
    7 - Game type picker background
    8 - Game type picker header
    9 - Game type picker button 3x3
    10 - Game type picker button 5x5 (3)
    11 - Game type picker button 5x5 (4)
    12 - Game type picker button 7x7 (3)
    13 - Game type picker button 7x7 (4)
    16 - TTT Playing as X/O
    17 - TTT exit game button
    100-149 - TTT game's fields
]]

playerGame = {}
playerInvitedPlayer = {}

enum = {
    gameFinishReason = {
        PLAYER_QUIT = 0,
        PLAYER_1_WON = 1,
        PLAYER_2_WON = 2,
        DRAW = 3,
        PLAYER_DISCONNECTED = 4
    },
    turn = {
        PLAYER1 = 1,
        PLAYER2 = 2
    },
    gameType = {
        THREE = 1,
        FIVE_3 = 2,
        FIVE_4 = 3,
        SEVEN_3 = 4,
        SEVEN_4 = 5
    },
    winnerCheckResult = {
        NO_WINNER = 0,
        PLAYER1 = 1,
        PLAYER2 = 2,
        DRAW = 3
    },
    gamePhase = {
        PICKING_TYPE = 1,
        PLAYING = 2,
        FINISHED = 3
    },
    field = {
        EMPTY = 0,
        PLAYER1 = 1,
        PLAYER2 = 2,
    }
}

winPossibilities = {}
winPossibilities[enum.gameType.THREE] = {
    {1, 2, 3},
    {4, 5, 6},
    {7, 8, 9},
    {1, 4, 7},
    {2, 5, 8},
    {3, 6, 9},
    {1, 5, 9},
    {3, 5, 7}
}
winPossibilities[enum.gameType.FIVE_3] = {
    {1, 2, 3},
    {2, 3, 4},
    {3, 4, 5},
    {6, 7, 8},
    {7, 8, 9},
    {8, 9, 10},
    {11, 12, 13},
    {12, 13, 14},
    {13, 14, 15},
    {16, 17, 18},
    {17, 18, 19},
    {18, 19, 20},
    {21, 22, 23},
    {22, 23, 24},
    {23, 24, 25},

    {1, 6, 11},
    {6, 11, 16},
    {11, 16, 21},
    {2, 7, 12},
    {7, 12, 17},
    {12, 17, 22},
    {3, 8, 13},
    {8, 13, 18},
    {13, 18, 23},
    {4, 9, 14},
    {9, 14, 19},
    {14, 19, 24},
    {5, 10, 15},
    {10, 15, 20},
    {15, 20, 25},

    {1, 7, 13},
    {2, 8, 14},
    {3, 9, 15},
    {6, 12, 18},
    {7, 13, 19},
    {8, 14, 20},
    {11, 17, 23},
    {12, 18, 24},
    {13, 19, 25},

    {3, 7, 11},
    {4, 8, 12},
    {5, 9, 13},
    {8, 12, 16},
    {9, 13, 17},
    {10, 14, 18},
    {13, 17, 21},
    {14, 18, 22},
    {15, 19, 23},
}
winPossibilities[enum.gameType.FIVE_4] = {
    {1, 2, 3}
}
winPossibilities[enum.gameType.SEVEN_3] = {
    {1, 2, 3}
}
winPossibilities[enum.gameType.SEVEN_4] = {
    {1, 2, 3}
}

textAreasDefs = {
    len3 = {
        length = 50,
        between = 75,
        textSize = 34
    },
    len5 = {
        length = 30,
        between = 45,
        textSize = 22
    },
    len7 = {
        length = 20,
        between = 30,
        textSize = 14
    }
}

TicTacToeGame = {
    player1 = nil,
    player2 = nil,
    turn = enum.turn.PLAYER1,
    color = 0xFFFFFF,   
    board = {},
    isWithBot = false,
    gamePhase = enum.gamePhase.PICKING_TYPE,
    gameType = enum.gameType.THREE,
    winningCombo = nil
}

eventLoopTicks = 0
scheduledFunctionCalls = {}

function doLater(callback, ticksLater)
    scheduledFunctionCalls[#scheduledFunctionCalls + 1] = {
        func = callback,
        tick = eventLoopTicks + ticksLater,
    }
end

function isPlayerHere(playerName)
    return not not tfm.get.room.playerList[playerName]
end

function getBoardLength(gameType)
    if gameType == enum.gameType.THREE then
        return 3
    elseif gameType == enum.gameType.FIVE_3 or gameType == enum.gameType.FIVE_4 then
        return 5
    elseif gameType == enum.gameType.SEVEN_3 or gameType == enum.gameType.SEVEN_4 then
        return 7
    end
    return 0
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
    return o
end

function TicTacToeGame:start()
    playerInvitedPlayer[self.player1] = nil
    ui.removeTextArea(2, self.player1)
    ui.removeTextArea(3, self.player1)

    if self.player2 then
        playerInvitedPlayer[self.player2] = nil
        tfm.exec.setNameColor(self.player2, self.color)
        ui.removeTextArea(2, self.player2)
        ui.removeTextArea(3, self.player2)
        tfm.exec.movePlayer(self.player1, 380, 200, false, 0, 0, false)
        tfm.exec.movePlayer(self.player2, 420, 200, false, 0, 0, false)
        tfm.exec.linkMice(self.player1, self.player2, true)
        tfm.exec.setNameColor(self.player1, self.color)
        tfm.exec.setNameColor(self.player2, self.color)
    else
        tfm.exec.setNameColor(self.player1, self.color)
    end

    self:initGameTypePicker()
end

function TicTacToeGame:initGameTypePicker()
    local initGameTypePickerForPlayer = function(player)
        ui.addTextArea(7, '', player, 200, 50, 400, 300, 0x324650, 0x212F36, 0.9, true)
        ui.addTextArea(8, '<p align="center"><font size="20">Choose the game type</font></p>', player, 200, 50, 400, 30, nil, nil, 0.0, true)

        ui.addTextArea(9, '<a href="event:gameType_3"><p align="center"><font size="20">3x3</font></p></a>', player, 250, 100, 300, 30, 0x324650, 0x212F36, 1.0, true)
        ui.addTextArea(10, '<a href="event:gameType_5_3"><p align="center"><font size="18">5x5 (3 to win)</font></p></a>', player, 250, 150, 145, 30, 0x324650, 0x212F36, 1.0, true)
        ui.addTextArea(11, '<a href="event:gameType_5_4"><p align="center"><font size="18">5x5 (4 to win)</font></p></a>', player, 405, 150, 150, 30, 0x324650, 0x212F36, 1.0, true)
        ui.addTextArea(12, '<a href="event:gameType_7_3"><p align="center"><font size="18">7x7 (3 to win)</font></p></a>', player, 250, 200, 145, 30, 0x324650, 0x212F36, 1.0, true)
        ui.addTextArea(13, '<a href="event:gameType_7_4"><p align="center"><font size="18">7x7 (4 to win)</font></p></a>', player, 405, 200, 150, 30, 0x324650, 0x212F36, 1.0, true)

        ui.addTextArea(17, '<a href="event:exitGame"><p align="center"><font size="17"><b>Exit</b></font></p></a>', player, 300, 360, 200, 24, 0x324650, 0x212F36, 0.95, true)
    end
    initGameTypePickerForPlayer(self.player1)
    if self.player2 then
        initGameTypePickerForPlayer(self.player2)
    end
end

function TicTacToeGame:removeGameTypePicker()
    local removeGameTypePickerForPlayer = function(player)
        for i = 7, 13 do
            ui.removeTextArea(i, player)
        end
        ui.removeTextArea(17, player)
    end
    removeGameTypePickerForPlayer(self.player1)
    if self.player2 then
        removeGameTypePickerForPlayer(self.player2)
    end
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
        for i = 4, 17 do
            ui.removeTextArea(i, player)
        end
        for i = 100, 100 + getBoardLength(self.gameType) ^ 2 do
            ui.removeTextArea(i, player)
        end
        tfm.exec.setNameColor(player, 0xFFFFFF)
    end

    local gameOverPopup = function(playerName, text)
        ui.addPopup(2, 0, '<font size="20"><p align="center"><b>Game over</b></p></font><br><font size="13">' .. text .. "</font>", playerName, 300, 200, 200, true)
    end

    if reason == enum.gameFinishReason.PLAYER_QUIT then
        if self.player2 then
            gameOverPopup(self:opponent(causingPlayer), 'Your opponent left the TicTacToe game.')
        end
    elseif reason == enum.gameFinishReason.PLAYER_1_WON or reason == enum.gameFinishReason.PLAYER_2_WON then
        if causingPlayer then
            gameOverPopup(causingPlayer, '<p align="center"><font color="#00FF00"><b>You won! :)</b></font></p>')
            tfm.exec.playEmote(causingPlayer, 1)
            if self.player2 then
                gameOverPopup(self:opponent(causingPlayer), '<p align="center"><font color="#FF0000"><b>You lost! :(</b></font></p>')
                tfm.exec.playEmote(self:opponent(causingPlayer), 2)
            end
        else 
            gameOverPopup(self.player1, '<p align="center"><font color="#FF0000"><b>You lost! :(</b></font></p>')
            tfm.exec.playEmote(self.player1, 2)
        end
    elseif reason == enum.gameFinishReason.DRAW then
        gameOverPopup(self.player1, 'The game ended with a draw.')
        tfm.exec.playEmote(self.player1, 7)
        if self.player2 then
            gameOverPopup(self.player2, 'The game ended with a draw.')
            tfm.exec.playEmote(self.player2, 7)
        end
    elseif reason == enum.gameFinishReason.PLAYER_DISCONNECTED then
        gameOverPopup(self:opponent(causingPlayer), 'Your opponent left the room.')
    end

    self.gamePhase = enum.gamePhase.FINISHED
    
    if (isPlayerHere(self.player1)) then finishGameForPlayer(self.player1, self) end
    playerGame[self.player1] = nil
    if self.player2 then
        if (isPlayerHere(self.player2)) then
            finishGameForPlayer(self.player2, self) 
        end
        playerGame[self.player2] = nil
        tfm.exec.linkMice(self.player1, self.player2, false)
    end
end

function TicTacToeGame:initBoard()
    local initBoardForPlayer = function(player, opponent)
        ui.addTextArea(4, '', player, 200, 50, 400, 300, 0x324650, 0x212F36, 0.9, true)
        ui.addTextArea(5, '<p align="center"><font size="20">Opponent: ' .. opponent .. '</font></p>', player, 200, 50, 400, 30, nil, nil, 0.0, true)
        ui.addTextArea(6, '', player, 200, 80, 400, 30, nil, nil, 0.0, true)

        local boardLen = getBoardLength(self.gameType)

        local length = textAreasDefs['len' .. boardLen].length
        local between = textAreasDefs['len' .. boardLen].between

        for i = 0, boardLen - 1 do
            for j = 0, boardLen - 1 do
                local id = 100 + (i * boardLen) + j
                local x = 300 + j * between
                local y = 120 + i * between
                ui.addTextArea(id, '', player, x, y, length, length, 0x324650, 0x212F36, 0.95, true)
            end
        end
        ui.addTextArea(16, '<p align="center"><font size="18">Playing as: <b>' .. ((self:playerNumber(player) == 1) and 'X' or 'O') ..'</b></font></p>', player, 200, 325, 400, 30, nil, nil, 0.0, true)
        ui.addTextArea(17, '<a href="event:exitGame"><p align="center"><font size="17"><b>Exit</b></font></p></a>', player, 300, 360, 200, 24, 0x324650, 0x212F36, 0.95, true)
    end
    if not self.player2 then
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

        if self.gamePhase == enum.gamePhase.FINISHED then
            ui.updateTextArea(6, '<p align="center"><font size="16" color="#00FFFF">Game over!</font></p>', player)
        else
            if playerNumber == self.turn then
                ui.updateTextArea(6, '<p align="center"><font size="16" color="#00FF00">Your turn!</font></p>', player)
            else
                ui.updateTextArea(6, '<p align="center"><font size="16" color="#FF0000">Opponent\'s turn.</font></p>', player)
            end
        end
        local boardLen = getBoardLength(self.gameType)

        local idPartOfWinningCombo = function(winningCombo, id)
            if not winningCombo then
                return false
            end
            for i, field in ipairs(winningCombo) do
                if field == id then
                    return true
                end
            end
            return false
        end

        for i = 0, boardLen - 1 do
            for j = 0, boardLen - 1 do
                local id = 100 + (i * boardLen) + j
                local char = ''
                if self.board[id - 99] == enum.field.PLAYER1 then
                    char = 'X'
                elseif self.board[id - 99] == enum.field.PLAYER2 then
                    char = 'O'
                else
                    char = ' '
                end

                local color = "#FFFFFF"
                if playerNumber == self.board[id - 99] then
                    color = "#00FF00"
                else
                    color = "#FF0000"
                end
                local aStart = ''
                local aEnd = ''
                if self.gamePhase == enum.gamePhase.FINISHED then
                    if idPartOfWinningCombo(self.winningCombo, id - 99) then
                        aStart = '<u>'
                        aEnd = '</u>'
                    end
                elseif self.board[id - 99] == 0 then
                    aStart = '<a href="event:field' .. (id - 99) .. '">'
                    aEnd = '</a>'
                end
                
                ui.updateTextArea(id, aStart .. '<p align="center"><font size="' .. textAreasDefs['len' .. boardLen].textSize .. '" color="' .. color ..'"><b>' .. char .. '</b></font></p>' .. aEnd, player)
            end
        end
    end
    if not self.player2 then
        updateBoardForPlayer(self.player1, self)
    else
        updateBoardForPlayer(self.player1, self)
        updateBoardForPlayer(self.player2, self)
    end
end

function TicTacToeGame:startPlaying()
    self.gamePhase = enum.gamePhase.PLAYING
    for i = 1, getBoardLength(self.gameType) ^ 2 do
        self.board[i] = enum.field.EMPTY
    end
    self:removeGameTypePicker()
    self:initBoard()
end

function TicTacToeGame:setField(fieldNum, fieldVal)
    self.board[fieldNum] = fieldVal

    local winnerCheck, winningCombo = self:winnerCheck()

    if winnerCheck ~= enum.winnerCheckResult.NO_WINNER then
        self.gamePhase = enum.gamePhase.FINISHED
        self.winningCombo = winningCombo
        if winnerCheck == enum.winnerCheckResult.PLAYER1 then
            doLater(function()
                self:finish(enum.gameFinishReason.PLAYER_1_WON, self.player1)
            end, 6)
        elseif winnerCheck == enum.winnerCheckResult.PLAYER2 then
            doLater(function()
                self:finish(enum.gameFinishReason.PLAYER_2_WON, self.player2)
            end, 6)
        elseif winnerCheck == enum.winnerCheckResult.DRAW then
            doLater(function()
                self:finish(enum.gameFinishReason.DRAW, nil) 
            end, 3)
        end
    end
    self:updateBoard()
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
    if self.gamePhase ~= enum.gamePhase.PLAYING then
        return
    end
    if playerNumber == self.turn then
        if self.board[fieldNum] == enum.field.EMPTY then
            if self.player2 then
                if self.turn == enum.turn.PLAYER1 then
                    self.turn = enum.turn.PLAYER2
                else
                    self.turn = enum.turn.PLAYER1
                end
            end
            self:setField(fieldNum, playerNumber)

            if not self.player2 and self.gamePhase ~= enum.gamePhase.FINISHED then
                self:placeSomethingAsBot()
            end
        end
    end
end

function TicTacToeGame:placeSomethingAsBot()
    emptyFields = {}

    for fieldNum, fieldVal in ipairs(self.board) do
        if fieldVal == enum.field.EMPTY then
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
        self.board[fieldNum] = enum.field.PLAYER2
        if self:winnerCheck() == enum.winnerCheckResult.PLAYER2 then
            self:setField(fieldNum, enum.field.PLAYER2)
            return
        else
            self.board[fieldNum] = enum.field.EMPTY
        end
    end

    for i, fieldNum in ipairs(emptyFields) do
        self.board[fieldNum] = enum.field.PLAYER1
        if self:winnerCheck() == enum.winnerCheckResult.PLAYER1 then
            self:setField(fieldNum, enum.field.PLAYER2)
            return
        else
            self.board[fieldNum] = enum.field.EMPTY
        end
    end

    self:setField(emptyFields[math.random(1, #emptyFields)], enum.field.PLAYER2)
end

function TicTacToeGame:winnerCheck()
    --[[
        Returns 0 if no winner yet
        1 if player 1
        2 if player 2
        3 if draw

        TODO: Make this detect draws without it having all fields occupied
    ]]
    local check = function(board, fieldsTable)
        local firstFieldVal = nil
        for i, field in ipairs(fieldsTable) do
            if firstFieldVal == nil then
                firstFieldVal = board[field]
            else
                if firstFieldVal ~= board[field] then
                    return 0
                end
            end
        end
        return firstFieldVal
    end

    for i, possibility in pairs(winPossibilities[self.gameType]) do
        local checkResult = check(self.board, possibility)
        if checkResult ~= 0 then
            return checkResult, possibility
        end
    end

    for i = 1, getBoardLength(self.gameType) ^ 2 do
        if self.board[i] == enum.field.EMPTY then
            return enum.winnerCheckResult.NO_WINNER, nil
        end
    end

    return enum.winnerCheckResult.DRAW, nil
end

function openHelpPopup(playerName)
    local text = [[
<p align='center'><font size='20' color='#BABD2F'><b>TicTacToe</b></font></p>
<b>Welcome to the module!</b>
Here you can play <font color='#BABD2F'>TicTacToe</font> with another player in the room.

To invite a player to play with you, either click on the player or use the command <font color='#6C77C1'><b>!invite</b> Player#XXXX</font>.

Or you could play with the <font color='#009D9D'>Teacher</font> by clicking on her.

After two players have invited themselves, or you chose to play with the <font color='#009D9D'>teacher</font>, a board will appear.

If it's your turn, you can either click on a field or use <font color='#C53DFF'><b>1-9</b></font> keys on your keyboard to select a field.

<font color='#2ECF73' size='13'><b>Good luck!</b></font>
<p align='right'><font color='#606090' size='10'><b><i>Made by Khajiitos#0000</i><b></font></p>]]
    ui.addPopup(1, 0, text, playerName, 200, 50, 400, true)
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
            playerGame[playerName]:finish(enum.gameFinishReason.PLAYER_QUIT, playerName)
        end
    elseif callback == "uninvitePlayer" then
        playerInvitedPlayer[playerName] = nil
        ui.removeTextArea(2, playerName)
        ui.removeTextArea(3, playerName)
    elseif callback:find('gameType') then
        if not playerGame[playerName] then
            return
        end
        local gameTypeStr = callback:sub(#"gameType_" + 1, #callback)
        if gameTypeStr == "3" then
            playerGame[playerName].gameType = enum.gameType.THREE
        elseif gameTypeStr == "5_3" then
            playerGame[playerName].gameType = enum.gameType.FIVE_3
        elseif gameTypeStr == "5_4" then
            playerGame[playerName].gameType = enum.gameType.FIVE_4
        elseif gameTypeStr == "7_3" then
            playerGame[playerName].gameType = enum.gameType.SEVEN_3
        elseif gameTypeStr == "7_4" then
            playerGame[playerName].gameType = enum.gameType.SEVEN_4
        end
        playerGame[playerName]:startPlaying()
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
        playerGame[playerName]:finish(enum.gameFinishReason.PLAYER_DISCONNECTED, playerName)
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

function eventLoop(currentTime, timeRemaining)
    for i, scheduledFunctionCall in ipairs(scheduledFunctionCalls) do
        if eventLoopTicks >= scheduledFunctionCall.tick then
            scheduledFunctionCall.func()
            table.remove(scheduledFunctionCalls, i)
        end
    end

    eventLoopTicks = eventLoopTicks + 1
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
        x = 725,
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