local BOARD_SIZE = 19
local cellSize = 0.95
local boardCenterX = 0.0
local boardCenterZ = 0.0
local stoneY = 2.28
local KOMI = 7.5

local currentLang = "RU"

local LANG_DICT = {
	RU = {
		start = "СТАРТ", pass = "ПАСС", reset = "СБРОС", lang = "RU / EN",
		msg_already_playing = "Игра уже идет!",
		msg_reg_black = "Игрок %s зарегистрирован за ЧЕРНЫХ.",
		msg_reg_white_hint = "Второй игрок, нажмите СТАРТ или сходите Белыми.",
		msg_reg_white = "Игрок %s зарегистрирован за БЕЛЫХ.",
		msg_game_start = "=== ИГРА НАЧАЛАСЬ! ХОД ЧЕРНЫХ ===",
		msg_already_reg_black = "Вы уже Черные. Ожидайте оппонента.",
		msg_hint_start = "Нажмите СТАРТ для регистрации игроков.",
		msg_not_your_turn = "Сейчас не ваш ход!",
		msg_wrong_stone = "Нельзя ходить камнем чужого цвета!",
		msg_place_taken = "Это место занято!",
		msg_made_move = "%s делает ход в %s",
		msg_ended = "Игра завершена. Нажмите СБРОС.",
		msg_already_passed = "Вы уже пасовали!",
		msg_cant_pass = "Сейчас не ваш ход! Нельзя пасовать.",
		msg_player_passed = "%s (%s) объявляет ПАСС.",
		msg_reset_done = "Игра сброшена! Удалено камней: ",
		msg_rule_ko = "Ход запрещен: Правило Ко!",
		msg_suicide = "Ход запрещен: Самоубийство!",
		msg_captured = "Захвачено камней: ",
		score_title = "=== ДВА ПАССА: АВТОПОДСЧЕТ ОЧКОВ ===",
		score_ai_removed = "Скрипт обнаружил и убрал мертвые камни: ",
		score_final_header = "=== ФИНАЛЬНЫЙ СЧЕТ ===",
		score_black_total = "ЧЕРНЫЕ (Камни + Территория): ",
		score_white_total = "БЕЛЫЕ (Камни + Территория + Коми): ",
		score_black_win = "🏆 ПОБЕДИЛИ ЧЕРНЫЕ на %s очков!",
		score_white_win = "🏆 ПОБЕДИЛИ БЕЛЫЕ на %s очков!"
	},
	EN = {
		start = "START", pass = "PASS", reset = "RESET", lang = "EN / RU",
		msg_already_playing = "Game is already in progress!",
		msg_reg_black = "Player %s is registered as BLACK.",
		msg_reg_white_hint = "Second player, press START or play White.",
		msg_reg_white = "Player %s is registered as WHITE.",
		msg_game_start = "=== GAME STARTED! BLACK'S TURN ===",
		msg_already_reg_black = "You are already Black. Waiting for opponent.",
		msg_hint_start = "Press the START button first.",
		msg_not_your_turn = "It's not your turn!",
		msg_wrong_stone = "You cannot play opponent's color!",
		msg_place_taken = "This intersection is occupied!",
		msg_made_move = "%s plays at %s",
		msg_ended = "Game over. Press RESET.",
		msg_already_passed = "You have already passed!",
		msg_cant_pass = "It's not your turn! Cannot pass.",
		msg_player_passed = "%s (%s) PASSES.",
		msg_reset_done = "Game fully reset! Stones removed: ",
		msg_rule_ko = "Move forbidden: Ko Rule!",
		msg_suicide = "Move forbidden: Suicide!",
		msg_captured = "Stones captured: ",
		score_title = "=== TWO PASSES: AUTOMATIC SCORING ===",
		score_ai_removed = "Script detected and removed dead stones: ",
		score_final_header = "=== FINAL SCORE ===",
		score_black_total = "BLACK (Stones + Territory): ",
		score_white_total = "WHITE (Stones + Territory + Komi): ",
		score_black_win = "🏆 BLACK WINS BY %s POINTS!",
		score_white_win = "🏆 WHITE WINS BY %s POINTS!"
	}
}

local boardState = {}
local boardObjects = {}
local previousBoardState = nil
local gamePhase = "SETUP"
local consecutivePasses = 0
local lastPlayerPassed = ""
local registeredBlack = nil
local registeredWhite = nil
local currentTurn = "Black"

local DIRECTIONS = {
	{x = 1, z = 0}, {x = -1, z = 0}, {x = 0, z = 1}, {x = 0, z = -1}
}
local halfBoardFactor = (BOARD_SIZE - 1) / 2
local maxPhysicalOffset = halfBoardFactor * cellSize + (cellSize / 2)

function onLoad()
	resetBoardData()
	createGameButtons()
	print("SCRIPTED-GO successfully loaded")
end

function resetBoardData()
	boardState = {}
	boardObjects = {}
	previousBoardState = nil
	gamePhase = "SETUP"
	consecutivePasses = 0
	lastPlayerPassed = ""
	currentTurn = "Black"
	registeredBlack = nil
	registeredWhite = nil
	
	for i = 1, BOARD_SIZE do
		boardState[i] = {}
		boardObjects[i] = {}
		for j = 1, BOARD_SIZE do
			boardState[i][j] = 0
			boardObjects[i][j] = nil
		end
	end
end

function createGameButtons()
	self.clearButtons()
	local t = LANG_DICT[currentLang]

	self.createButton({
		click_function = "buttonStart", function_owner = self,
		label = t.start, position = {-1.5, -0.6, 9.35}, rotation = {-66.5, 0, 0},
		width = 800, height = 400, font_size = 180,
		color = {0.1, 0.6, 0.1}, font_color = {1, 1, 1}
	})
	self.createButton({
		click_function = "buttonPass", function_owner = self,
		label = t.pass, position = {1.5, -0.6, 9.35}, rotation = {-66.5, 0, 0},
		width = 800, height = 400, font_size = 180,
		color = {0.1, 0.1, 0.1}, font_color = {1, 1, 1}
	})
	self.createButton({
		click_function = "buttonReset", function_owner = self,
		label = t.reset, position = {-4.5, -0.6, 9.35}, rotation = {-66.5, 0, 0},
		width = 800, height = 400, font_size = 180,
		color = {0.5, 0.1, 0.1}, font_color = {1, 1, 1}
	})
	self.createButton({
		click_function = "buttonToggleLanguage", function_owner = self,
		label = t.lang, position = {4.5, -0.6, 9.35}, rotation = {-66.5, 0, 0},
		width = 800, height = 400, font_size = 150,
		color = {0.2, 0.4, 0.6}, font_color = {1, 1, 1}
	})
	self.createButton({
		click_function = "buttonStart", function_owner = self,
		label = t.start, position = {1.5, -0.6, -9.35}, rotation = {66.5, 180, 0},
		width = 800, height = 400, font_size = 180,
		color = {0.1, 0.6, 0.1}, font_color = {1, 1, 1}
	})
	self.createButton({
		click_function = "buttonPass", function_owner = self,
		label = t.pass, position = {-1.5, -0.6, -9.35}, rotation = {66.5, 180, 0},
		width = 800, height = 400, font_size = 180,
		color = {0.1, 0.1, 0.1}, font_color = {1, 1, 1}
	})
	self.createButton({
		click_function = "buttonReset", function_owner = self,
		label = t.reset, position = {4.5, -0.6, -9.35}, rotation = {66.5, 180, 0},
		width = 800, height = 400, font_size = 180,
		color = {0.5, 0.1, 0.1}, font_color = {1, 1, 1}
	})
	self.createButton({
		click_function = "buttonToggleLanguage", function_owner = self,
		label = t.lang, position = {-4.5, -0.6, -9.35}, rotation = {66.5, 180, 0},
		width = 800, height = 400, font_size = 150,
		color = {0.2, 0.4, 0.6}, font_color = {1, 1, 1}
	})
end

function buttonToggleLanguage(obj, player_color)
	currentLang = (currentLang == "RU") and "EN" or "RU"
	createGameButtons()
	local msg = (currentLang == "RU") and "Язык: Русский" or "Language: English"
	broadcastToAll(msg, {0.2, 0.6, 1.0})
end

function buttonStart(obj, player_color)
	local t = LANG_DICT[currentLang]
	if gamePhase == "PLAYING" then
		broadcastToColor(t.msg_already_playing, player_color, {1, 1, 0})
		return
	end
	
	local playerNick = Player[player_color].steam_name or player_color
	
	if not registeredBlack then
		registeredBlack = player_color
		printToAll(string.format(t.msg_reg_black, playerNick), {0.5, 1, 0.5})
		printToAll(t.msg_reg_white_hint, {1, 1, 0})
	elseif not registeredWhite and registeredBlack ~= player_color then
		registeredWhite = player_color
		printToAll(string.format(t.msg_reg_white, playerNick), {0.5, 1, 0.5})
		gamePhase = "PLAYING"
		printToAll(t.msg_game_start, {0, 1, 0})
	elseif registeredBlack == player_color then
		broadcastToColor(t.msg_already_reg_black, player_color, {1, 1, 0})
	end
end

function onObjectDropped(player_color, dropped_object)
	local t = LANG_DICT[currentLang]
	local objName = dropped_object.getName()
	local isBlackStone = (objName == "Go Stone Black")
	local isWhiteStone = (objName == "Go Stone White")

	if isBlackStone or isWhiteStone then
		if gamePhase == "SETUP" and registeredBlack then
			if player_color ~= registeredBlack then
				registeredWhite = player_color
				gamePhase = "PLAYING"
				local playerNick = Player[player_color].steam_name or player_color
				printToAll(string.format(t.msg_reg_white, playerNick), {0.5, 1, 0.5})
				printToAll(t.msg_game_start, {0, 1, 0})
			end
		end

		if gamePhase ~= "PLAYING" then 
			broadcastToColor(t.msg_hint_start, player_color, {1, 0, 0})
			rejectStone(dropped_object)
			return 
		end 

		local expectedPlayer = (currentTurn == "Black") and registeredBlack or registeredWhite
		if player_color ~= expectedPlayer then
			broadcastToColor(t.msg_not_your_turn, player_color, {1, 0, 0})
			rejectStone(dropped_object)
			return
		end

		if (currentTurn == "Black" and not isBlackStone) or (currentTurn == "White" and not isWhiteStone) then
			broadcastToColor(t.msg_wrong_stone, player_color, {1, 0, 0})
			rejectStone(dropped_object)
			return
		end

		local pos = dropped_object.getPosition()
		local offsetX = pos.x - boardCenterX
		local offsetZ = pos.z - boardCenterZ
		
		if math.abs(offsetX) <= maxPhysicalOffset and math.abs(offsetZ) <= maxPhysicalOffset then
			local gridX = math.floor(offsetX / cellSize + 0.5) + math.floor(BOARD_SIZE / 2) + 1
			local gridZ = math.floor(offsetZ / cellSize + 0.5) + math.floor(BOARD_SIZE / 2) + 1

			if gridX >= 1 and gridX <= BOARD_SIZE and gridZ >= 1 and gridZ <= BOARD_SIZE then
				if boardState[gridX][gridZ] == 0 then
					local stoneColor = isBlackStone and 1 or 2
					local backupState = copyBoardState(boardState)
					
					local targetX = (gridX - 1 - math.floor(BOARD_SIZE / 2)) * cellSize + boardCenterX
					local targetZ = (gridZ - 1 - math.floor(BOARD_SIZE / 2)) * cellSize + boardCenterZ
					dropped_object.setPosition({targetX, stoneY, targetZ})
					dropped_object.setRotation({0, 0, 0})
					dropped_object.setLock(true)
					
					boardState[gridX][gridZ] = stoneColor
					boardObjects[gridX][gridZ] = dropped_object
					
					local isMoveLegal = checkRulesAndCaptures(gridX, gridZ, stoneColor, player_color, backupState)
					
					if isMoveLegal then
						consecutivePasses = 0 
						local playerNick = Player[player_color].steam_name or player_color
						local textCoordinate = getGoNotation(gridX, gridZ)
						printToAll(string.format(t.msg_made_move, playerNick, textCoordinate), {0.9, 0.9, 0.9})
						
						currentTurn = (currentTurn == "Black") and "White" or "Black"
					end
				else
					broadcastToColor(t.msg_place_taken, player_color, {1, 0, 0})
					rejectStone(dropped_object)
				end
			end
		else
			rejectStone(dropped_object)
		end
	end
end

function rejectStone(stoneObj)
	stoneObj.setLock(false)
	local pos = stoneObj.getPosition()
	stoneObj.setPosition({pos.x, pos.y + 1.5, pos.z})
end
function checkRulesAndCaptures(lastX, lastZ, playerColor, player_color, backupState)
	local t = LANG_DICT[currentLang]
	local enemyColor = (playerColor == 1) and 2 or 1
	local stonesToRemove = {}

	for _, dir in ipairs(DIRECTIONS) do
		local nx = lastX + dir.x
		local nz = lastZ + dir.z
		if isValidCoord(nx, nz) and boardState[nx][nz] == enemyColor then
			local group, liberties = getGroupAndLiberties(nx, nz, enemyColor)
			if liberties == 0 then
				for _, pos in ipairs(group) do table.insert(stonesToRemove, pos) end
			end
		end
	end

	for _, pos in ipairs(stonesToRemove) do boardState[pos.x][pos.z] = 0 end

	if previousBoardState and compareBoards(boardState, previousBoardState) then
		broadcastToColor(t.msg_rule_ko, player_color, {1, 0, 0})
		revertMove(lastX, lastZ, backupState)
		return false
	end

	if #stonesToRemove == 0 then
		local _, myLiberties = getGroupAndLiberties(lastX, lastZ, playerColor)
		if myLiberties == 0 then
			broadcastToColor(t.msg_suicide, player_color, {1, 0, 0})
			revertMove(lastX, lastZ, backupState)
			return false
		end
	else
		for _, pos in ipairs(stonesToRemove) do
			local stoneObj = boardObjects[pos.x][pos.z]
			if stoneObj and not stoneObj.isDestroyed() then stoneObj.destruct() end
			boardObjects[pos.x][pos.z] = nil
		end
		printToAll(t.msg_captured .. #stonesToRemove, {1, 0.5, 0})
	end

	previousBoardState = backupState
	return true
end

function revertMove(x, z, backupState)
	local stoneObj = boardObjects[x][z]
	if stoneObj then stoneObj.setLock(false) end
	boardState = copyBoardState(backupState)
	boardObjects[x][z] = nil
end

function buttonPass(obj, player_color)
	if gamePhase ~= "PLAYING" then return end
	local t = LANG_DICT[currentLang]
	
	local expectedPlayer = (currentTurn == "Black") and registeredBlack or registeredWhite
	if player_color ~= expectedPlayer then
		broadcastToColor(t.msg_cant_pass, player_color, {1, 0, 0})
		return
	end

	local playerNick = Player[player_color].steam_name or player_color
	consecutivePasses = consecutivePasses + 1
	printToAll(string.format(t.msg_player_passed, playerNick, currentTurn), {1, 1, 0})

	if consecutivePasses >= 2 then
		executeAutomaticScoring()
	else
		currentTurn = (currentTurn == "Black") and "White" or "Black"
	end
end

function buttonReset(obj, player_color)
	local t = LANG_DICT[currentLang]
	local count = 0
	for i = 1, BOARD_SIZE do
		for j = 1, BOARD_SIZE do
			local stoneObj = boardObjects[i][j]
			if stoneObj and not stoneObj.isDestroyed() then
				stoneObj.setLock(false)
				stoneObj.destruct()
				count = count + 1
			end
		end
	end
	resetBoardData()
	broadcastToAll(t.msg_reset_done .. count, {1, 0, 0})
end

function executeAutomaticScoring()
	gamePhase = "ENDED"
	local t = LANG_DICT[currentLang]
	printToAll(t.score_title, {0, 1, 0})
	
	local deadCount = 0
	for i = 1, BOARD_SIZE do
		for j = 1, BOARD_SIZE do
			if boardState[i][j] ~= 0 then
				local _, liberties = getGroupAndLiberties(i, j, boardState[i][j])
				if liberties <= 1 then
					local stoneObj = boardObjects[i][j]
					if stoneObj and not stoneObj.isDestroyed() then stoneObj.destruct() end
					boardState[i][j] = 0
					boardObjects[i][j] = nil
					deadCount = deadCount + 1
				end
			end
		end
	end
	if deadCount > 0 then printToAll(t.score_ai_removed .. deadCount, {1, 0.5, 0}) end

	local blackScore = 0
	local whiteScore = KOMI 
	local scoredVisited = {}
	for i = 1, BOARD_SIZE do scoredVisited[i] = {} end

	for i = 1, BOARD_SIZE do
		for j = 1, BOARD_SIZE do
			if boardState[i][j] == 1 then blackScore = blackScore + 1
			elseif boardState[i][j] == 2 then whiteScore = whiteScore + 1
			elseif boardState[i][j] == 0 and not scoredVisited[i][j] then
				local territorySize, owner = analyzeTerritory(i, j, scoredVisited)
				if owner == 1 then blackScore = blackScore + territorySize
				elseif owner == 2 then whiteScore = whiteScore + territorySize end
			end
		end
	end

	printToAll(t.score_final_header, {1, 1, 1})
	printToAll(t.score_black_total .. blackScore, {0.3, 0.3, 0.3})
	printToAll(t.score_white_total .. whiteScore, {1, 1, 1})
	
	if blackScore > whiteScore then
		printToAll(string.format(t.score_black_win, tostring(blackScore - whiteScore)), {1, 0.8, 0})
	else
		printToAll(string.format(t.score_white_win, tostring(whiteScore - blackScore)), {1, 0.8, 0})
	end
end

function analyzeTerritory(startX, startZ, scoredVisited)
	local queue = {{x = startX, z = startZ}}
	local cells = {{x = startX, z = startZ}}
	scoredVisited[startX][startZ] = true
	local head = 1
	local touchedBlack = false
	local touchedWhite = false

	while head <= #queue do
		local curr = queue[head]
		head = head + 1
		for _, dir in ipairs(DIRECTIONS) do
			local nx = curr.x + dir.x
			local nz = curr.z + dir.z
			if isValidCoord(nx, nz) then
				if boardState[nx][nz] == 1 then touchedBlack = true
				elseif boardState[nx][nz] == 2 then touchedWhite = true
				elseif boardState[nx][nz] == 0 and not scoredVisited[nx][nz] then
					scoredVisited[nx][nz] = true
					table.insert(queue, {x = nx, z = nz})
					table.insert(cells, {x = nx, z = nz})
				end
			end
		end
	end

	local owner = 0
	if touchedBlack and not touchedWhite then owner = 1
	elseif touchedWhite and not touchedBlack then owner = 2 end
	return #cells, owner
end

function getGroupAndLiberties(startX, startZ, targetColor)
	local queue = {{x = startX, z = startZ}}
	local group = {{x = startX, z = startZ}}
	local visited = {}
	for i = 1, BOARD_SIZE do visited[i] = {} end
	visited[startX][startZ] = true
	local liberties = 0
	local head = 1
	while head <= #queue do
		local curr = queue[head]
		head = head + 1
		for _, dir in ipairs(DIRECTIONS) do
			local nx = curr.x + dir.x
			local nz = curr.z + dir.z
			if isValidCoord(nx, nz) then
				if boardState[nx][nz] == 0 then
					if not visited[nx][nz] then
						visited[nx][nz] = true
						liberties = liberties + 1
					end
				elseif boardState[nx][nz] == targetColor and not visited[nx][nz] then
					visited[nx][nz] = true
					table.insert(queue, {x = nx, z = nz})
					table.insert(group, {x = nx, z = nz})
				end
			end
		end
	end
	return group, liberties
end

function copyBoardState(orig)
	local copy = {}
	for i = 1, BOARD_SIZE do
		copy[i] = {}
		for j = 1, BOARD_SIZE do copy[i][j] = orig[i][j] end
	end
	return copy
end

function compareBoards(b1, b2)
	for i = 1, BOARD_SIZE do
		for j = 1, BOARD_SIZE do
			if b1[i][j] ~= b2[i][j] then return false end
		end
	end
	return true
end

function isValidCoord(x, z)
	return x >= 1 and x <= BOARD_SIZE and z >= 1 and z <= BOARD_SIZE
end

function getGoNotation(x, z)
	local letters = {"A","B","C","D","E","F","G","H","J","K","L","M","N","O","P","Q","R","S","T"}
	local letter = letters[x] or "?"
	local number = BOARD_SIZE - z + 1
	return letter .. tostring(number)
end