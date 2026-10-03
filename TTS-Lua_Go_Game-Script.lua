-- =========================================================================
-- БЛОК 1: ГЛОБАЛЬНЫЕ НАСТРОЙКИ, ЛОКАЛИЗАЦИЯ И СОСТОЯНИЕ ИГРЫ
-- =========================================================================

-- Настройки геометрии доски и правил Го
local BOARD_SIZE = 19
local cellSize = 0.95
local boardCenterX = -0.05
local boardCenterZ = -0.02
local stoneY = 0.16
local KOMI = 7.5

-- Настройки локализации
local currentLang = "RU"

local LANG_DICT = {
    RU = {
        start = "СТАРТ", pass = "ПАСС", reset = "СБРОС", lang = "RU / EN",
        confirm_reset = "УВЕРЕН?", mode_novice = "НОВИЧКИ", mode_master = "МАСТЕРА",
        btn_confirm_dead = "ПОДТВЕРДИТЬ",
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
        msg_reset_need_reg = "Только зарегистрированные игроки могут сбросить игру!",
        msg_reset_press_again = "Нажмите СБРОС еще раз для подтверждения!",
        msg_reset_done = "Игра сброшена! Удалено камней: ",
        msg_rule_ko = "Ход запрещен: Правило Ко!",
        msg_suicide = "Ход запрещен: Самоубийство!",
        msg_captured = "Захвачено камней: ",
        score_title = "=== ДВА ПАССА: ВЫБЕРИТЕ РЕЖИМ ПОДСЧЕТА ===",
        score_novice_activated = "Включен режим добивания. Доиграйте спорные позиции и считайте по факту.",
        score_master_activated = "Включен режим разметки. Кликайте по мертвым камням, затем нажмите ПОДТВЕРДИТЬ.",
        score_final_header = "=== ФИНАЛЬНЫЙ СЧЕТ ===",
        score_black_total = "ЧЕРНЫЕ (Камни + Территория): ",
        score_white_total = "БЕЛЫЕ (Камни + Территория + Коми): ",
        score_black_win = "🏆 ПОБЕДИЛИ ЧЕРНЫЕ на %s очков!",
        score_white_win = "🏆 ПОБЕДИЛИ БЕЛЫЕ на %s очков!"
    },
    EN = {
        start = "START", pass = "PASS", reset = "RESET", lang = "EN / RU",
        confirm_reset = "SURE?", mode_novice = "NOVICE", mode_master = "MASTER",
        btn_confirm_dead = "CONFIRM",
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
        msg_reset_need_reg = "Only registered players can reset the game!",
        msg_reset_press_again = "Press RESET again to confirm!",
        msg_reset_done = "Game fully reset! Stones removed: ",
        msg_rule_ko = "Move forbidden: Ko Rule!",
        msg_suicide = "Move forbidden: Suicide!",
        msg_captured = "Stones captured: ",
        score_title = "=== TWO PASSES: CHOOSE SCORING MODE ===",
        score_novice_activated = "Novice mode activated. Capture remaining stones on field, then score.",
        score_master_activated = "Master mode activated. Click dead stones to mark them, then press CONFIRM.",
        score_final_header = "=== FINAL SCORE ===",
        score_black_total = "BLACK (Stones + Territory): ",
        score_white_total = "WHITE (Stones + Territory + Komi): ",
        score_black_win = "🏆 BLACK WINS BY %s POINTS!",
        score_white_win = "🏆 WHITE WINS BY %s POINTS!"
    }
}

-- Динамические структуры данных игрового поля
local boardState = {}         -- Матрица: 0 = пусто, 1 = черный, 2 = белый
local boardObjects = {}       -- Матрица ссылок на физические 3D-объекты камней
local deadMarked = {}         -- Матрица флагов для разметки мертвых камней (true/false)
local previousBoardState = nil -- Копия состояния для детекции правила Ко

-- Переменные управления сессией
local gamePhase = "SETUP"       -- Направления: SETUP, PLAYING, SCORING_CHOICE, SCORING_NOVICE, SCORING_MASTER, ENDED
local consecutivePasses = 0
local currentTurn = "Black"     -- "Black" или "White"
local resetConfirmation = false -- Защита от случайного сброса

-- Кэширование Steam ID игроков (вместо стандартных цветов стола TTS)
local registeredBlack = nil     -- SteamID (строка) игрока за Черных
local registeredWhite = nil     -- SteamID (строка) игрока за Белых

-- Массив сдвигов для обхода соседей (4 направления)
local DIRECTIONS = {
    {x = 1, z = 0}, {x = -1, z = 0}, {x = 0, z = 1}, {x = 0, z = -1}
}
local halfBoardFactor = (BOARD_SIZE - 1) / 2
local maxPhysicalOffset = halfBoardFactor * cellSize + (cellSize / 2)

-- =========================================================================
-- БАЗОВЫЕ ИНИЦИАЛИЗАТОРЫ TTS
-- =========================================================================

function onLoad()
    resetBoardData()
    createGameButtons()
    print("SCRIPTED-GO Board successfully loaded.")
end

function resetBoardData()
    boardState = {}
    boardObjects = {}
    deadMarked = {}
    previousBoardState = nil
    gamePhase = "SETUP"
    consecutivePasses = 0
    currentTurn = "Black"
    registeredBlack = nil
    registeredWhite = nil
    resetConfirmation = false
    
    for i = 1, BOARD_SIZE do
        boardState[i] = {}
        boardObjects[i] = {}
        deadMarked[i] = {}
        for j = 1, BOARD_SIZE do
            boardState[i][j] = 0
            boardObjects[i][j] = nil
            deadMarked[i][j] = false
        end
    end
end
-- =========================================================================
-- БЛОК 2: ГЕНЕРАЦИЯ ДИНАМИЧЕСКИХ КНОПОК УПРАВЛЕНИЯ
-- =========================================================================

function createGameButtons()
    self.clearButtons()
    local t = LANG_DICT[currentLang]

    -- Если фаза выбора режима подсчета очков (после двух пасов)
    if gamePhase == "SCORING_CHOICE" then
        -- Сторона А (Z = 9.35)
        self.createButton({
            click_function = "setScoringNovice", function_owner = self,
            label = t.mode_novice, position = {-2.0, -0.6, 9.35}, rotation = {-66.5, 0, 0},
            width = 1200, height = 400, font_size = 160, color = {0.2, 0.6, 0.8}, font_color = {1, 1, 1}
        })
        self.createButton({
            click_function = "setScoringMaster", function_owner = self,
            label = t.mode_master, position = {2.0, -0.6, 9.35}, rotation = {-66.5, 0, 0},
            width = 1200, height = 400, font_size = 160, color = {0.6, 0.3, 0.8}, font_color = {1, 1, 1}
        })
        -- Сторона Б (Z = -9.35)
        self.createButton({
            click_function = "setScoringNovice", function_owner = self,
            label = t.mode_novice, position = {2.0, -0.6, -9.35}, rotation = {66.5, 180, 0},
            width = 1200, height = 400, font_size = 160, color = {0.2, 0.6, 0.8}, font_color = {1, 1, 1}
        })
        self.createButton({
            click_function = "setScoringMaster", function_owner = self,
            label = t.mode_master, position = {-2.0, -0.6, -9.35}, rotation = {66.5, 180, 0},
            width = 1200, height = 400, font_size = 160, color = {0.6, 0.3, 0.8}, font_color = {1, 1, 1}
        })
        return
    end

    -- Если фаза интерактивной разметки мертвых камней мастерами
    if gamePhase == "SCORING_MASTER" then
        self.createButton({
            click_function = "confirmMasterScoring", function_owner = self,
            label = t.btn_confirm_dead, position = {0.0, -0.6, 9.35}, rotation = {-66.5, 0, 0},
            width = 1600, height = 400, font_size = 180, color = {0.1, 0.7, 0.1}, font_color = {1, 1, 1}
        })
        self.createButton({
            click_function = "confirmMasterScoring", function_owner = self,
            label = t.btn_confirm_dead, position = {0.0, -0.6, -9.35}, rotation = {66.5, 180, 0},
            width = 1600, height = 400, font_size = 180, color = {0.1, 0.7, 0.1}, font_color = {1, 1, 1}
        })
        return
    end

    -- Стандартная игровая панель (SETUP, PLAYING, SCORING_NOVICE, ENDED)
    local resetLabel = resetConfirmation and t.confirm_reset or t.reset
    local resetColor = resetConfirmation and {0.9, 0.1, 0.1} or {0.5, 0.1, 0.1}

    -- Игровая панель: Сторона А
    self.createButton({
        click_function = "buttonStart", function_owner = self,
        label = t.start, position = {-1.5, -0.6, 9.35}, rotation = {-66.5, 0, 0},
        width = 800, height = 400, font_size = 180, color = {0.1, 0.6, 0.1}, font_color = {1, 1, 1}
    })
    self.createButton({
        click_function = "buttonPass", function_owner = self,
        label = t.pass, position = {1.5, -0.6, 9.35}, rotation = {-66.5, 0, 0},
        width = 800, height = 400, font_size = 180, color = {0.1, 0.1, 0.1}, font_color = {1, 1, 1}
    })
    self.createButton({
        click_function = "buttonReset", function_owner = self,
        label = resetLabel, position = {-4.5, -0.6, 9.35}, rotation = {-66.5, 0, 0},
        width = 800, height = 400, font_size = 180, color = resetColor, font_color = {1, 1, 1}
    })
    self.createButton({
        click_function = "buttonToggleLanguage", function_owner = self,
        label = t.lang, position = {4.5, -0.6, 9.35}, rotation = {-66.5, 0, 0},
        width = 800, height = 400, font_size = 150, color = {0.2, 0.4, 0.6}, font_color = {1, 1, 1}
    })

    -- Игровая панель: Сторона Б
    self.createButton({
        click_function = "buttonStart", function_owner = self,
        label = t.start, position = {1.5, -0.6, -9.35}, rotation = {66.5, 180, 0},
        width = 800, height = 400, font_size = 180, color = {0.1, 0.6, 0.1}, font_color = {1, 1, 1}
    })
    self.createButton({
        click_function = "buttonPass", function_owner = self,
        label = t.pass, position = {-1.5, -0.6, -9.35}, rotation = {66.5, 180, 0},
        width = 800, height = 400, font_size = 180, color = {0.1, 0.1, 0.1}, font_color = {1, 1, 1}
    })
    self.createButton({
        click_function = "buttonReset", function_owner = self,
        label = resetLabel, position = {4.5, -0.6, -9.35}, rotation = {66.5, 180, 0},
        width = 800, height = 400, font_size = 180, color = resetColor, font_color = {1, 1, 1}
    })
    self.createButton({
        click_function = "buttonToggleLanguage", function_owner = self,
        label = t.lang, position = {-4.5, -0.6, -9.35}, rotation = {66.5, 180, 0},
        width = 800, height = 400, font_size = 150, color = {0.2, 0.4, 0.6}, font_color = {1, 1, 1}
    })
end

function buttonToggleLanguage(obj, player_color)
    currentLang = (currentLang == "RU") and "EN" or "RU"
    createGameButtons()
    local msg = (currentLang == "RU") and "Язык интерфейса: Русский" or "Interface Language: English"
    broadcastToAll(msg, {0.2, 0.6, 1.0})
end
-- =========================================================================
-- БЛОК 3: УПРАВЛЕНИЕ СЕССИЕЙ, РЕГИСТРАЦИЯ И АВТООТКАТ СБРОСА (ИСПРАВЛЕНО)
-- =========================================================================

-- Переменная для хранения числового ID запущенного таймера TTS
local resetTimerId = nil

function buttonStart(obj, player_color, alt_click)
    local t = LANG_DICT[currentLang]

    if gamePhase ~= "SETUP" then
        broadcastToColor(t.msg_already_playing, player_color, {0.9, 0.2, 0.2})
        return
    end

    local playerNick = Player[player_color].steam_name or player_color

    if not registeredBlack then
        registeredBlack = player_color
        printToAll(string.format(t.msg_reg_black, playerNick), {0.1, 0.6, 0.1})
        printToAll(t.msg_reg_white_hint, {0.2, 0.6, 0.9})
    elseif not registeredWhite and registeredBlack ~= player_color then
        registeredWhite = player_color
        printToAll(string.format(t.msg_reg_white, playerNick), {0.1, 0.6, 0.1})
        
        gamePhase = "PLAYING"
        printToAll(t.msg_game_start, {0.2, 0.9, 0.2})
    elseif registeredBlack == player_color then
        broadcastToColor(t.msg_already_reg_black, player_color, {0.9, 0.6, 0.2})
    end
    createGameButtons()
end

function buttonPass(obj, player_color, alt_click)
    local t = LANG_DICT[currentLang]

    if gamePhase ~= "PLAYING" and gamePhase ~= "SCORING_NOVICE" then
        broadcastToColor(t.msg_cant_pass, player_color, {0.9, 0.2, 0.2})
        return
    end

    if currentTurn == "Black" and player_color ~= registeredBlack then
        broadcastToColor(t.msg_not_your_turn, player_color, {0.9, 0.2, 0.2})
        return
    elseif currentTurn == "White" and player_color ~= registeredWhite then
        broadcastToColor(t.msg_not_your_turn, player_color, {0.9, 0.2, 0.2})
        return
    end

    previousBoardState = nil
    consecutivePasses = consecutivePasses + 1
    
    local cName = (currentTurn == "Black") and "Black" or "White"
    local playerNick = Player[player_color].steam_name or player_color
    printToAll(string.format(t.msg_player_passed, playerNick, cName), {0.9, 0.7, 0.1})

    currentTurn = (currentTurn == "Black") and "White" or "Black"

    if consecutivePasses >= 2 then
        if gamePhase == "SCORING_NOVICE" then
            executeAutomaticScoring()
        else
            gamePhase = "SCORING_CHOICE"
            printToAll(t.score_title, {0.1, 0.7, 0.9})
            createGameButtons()
        end
    end
end

function buttonReset(obj, player_color, alt_click)
    local t = LANG_DICT[currentLang]

    if registeredBlack or registeredWhite then
        if player_color ~= registeredBlack and player_color ~= registeredWhite then
            broadcastToColor(t.msg_reset_need_reg, player_color, {0.9, 0.2, 0.2})
            return
        end
    end

    -- ПЕРВОЕ НАЖАТИЕ: Включаем режим ожидания и сохраняем числовой ID таймера
    if not resetConfirmation then
        resetConfirmation = true
        broadcastToAll(t.msg_reset_press_again, {0.9, 0.6, 0.1})
        createGameButtons()

        -- ИСПРАВЛЕНИЕ: Wait.time возвращает числовой ID (System.Uint32), сохраняем его
        resetTimerId = Wait.time(function()
            if resetConfirmation then
                resetConfirmation = false
                resetTimerId = nil
                createGameButtons()
            end
        end, 5.0, 1)
        return
    end

    -- ВТОРЕЕ НАЖАТИЕ: Останавливаем таймер по сохраненному числовому ID
    if resetTimerId then
        Wait.stop(resetTimerId)
        resetTimerId = nil
    end

    local deletedStonesCount = 0
    for x = 1, BOARD_SIZE do
        for z = 1, BOARD_SIZE do
            local stone = boardObjects[x][z]
            if stone and not stone.isDestroyed() then
                stone.setLock(false)
                stone.destruct()
                deletedStonesCount = deletedStonesCount + 1
            end
        end
    end

    resetBoardData()
    createGameButtons()
    broadcastToAll(t.msg_reset_done .. tostring(deletedStonesCount), {0.2, 0.9, 0.2})
end
-- =========================================================================
-- БЛОК 4: ФИЗИЧЕСКИЙ ТРИГГЕР КАМНЕЙ И ВЫРАВНИВАНИЕ НА СЕТКЕ (ИСПРАВЛЕНО)
-- =========================================================================

function onObjectDropped(player_color, dropped_object)
    if not dropped_object then return end
    local objName = dropped_object.getName()
    local isBlack = (objName == "Go Stone Black")
    local isWhite = (objName == "Go Stone White")

    if not isBlack and not isWhite then return end

    local t = LANG_DICT[currentLang]

    -- КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Если игра в режиме SETUP, ходить вообще нельзя!
    if gamePhase == "SETUP" then
        broadcastToColor(t.msg_hint_start, player_color, {0.9, 0.2, 0.2})
        dropped_object.destruct() -- Безжалостно удаляем камень
        return
    end

    -- Если идет подсчет Мастеров или игра завершена, новые камни ставить нельзя
    if gamePhase == "SCORING_MASTER" or gamePhase == "ENDED" then
        dropped_object.destruct()
        return
    end

    -- Проверка очереди хода строго по сохраненным цветам registeredBlack/White
    if gamePhase == "PLAYING" or gamePhase == "SCORING_NOVICE" then
        if currentTurn == "Black" and player_color ~= registeredBlack then
            broadcastToColor(t.msg_not_your_turn, player_color, {0.9, 0.2, 0.2})
            dropped_object.destruct()
            return
        elseif currentTurn == "White" and player_color ~= registeredWhite then
            broadcastToColor(t.msg_not_your_turn, player_color, {0.9, 0.2, 0.2})
            dropped_object.destruct()
            return
        end

        -- Проверка соответствия цвета камня текущему ходу
        if (currentTurn == "Black" and not isBlack) or (currentTurn == "White" and not isWhite) then
            broadcastToColor(t.msg_wrong_stone, player_color, {0.9, 0.2, 0.2})
            dropped_object.destruct()
            return
        end
    end

    -- Расчет пересечений локальной сетки доски
    local localPos = self.positionToLocal(dropped_object.getPosition())
    
    if math.abs(localPos.x) > maxPhysicalOffset or math.abs(localPos.z) > maxPhysicalOffset then
        dropped_object.destruct()
        return
    end

    local gridX = math.floor(((localPos.x - boardCenterX) / cellSize) + halfBoardFactor + 1.5)
    local gridZ = math.floor(((localPos.z - boardCenterZ) / cellSize) + halfBoardFactor + 1.5)

    if gridX < 1 or gridX > BOARD_SIZE or gridZ < 1 or gridZ > BOARD_SIZE then
        dropped_object.destruct()
        return
    end

    -- Проверка на занятость точки
    if boardState[gridX][gridZ] ~= 0 then
        broadcastToColor(t.msg_place_taken, player_color, {0.9, 0.2, 0.2})
        dropped_object.destruct()
        return
    end

    -- Жесткое физическое выравнивание камня
    local snapLocalX = (gridX - 1 - halfBoardFactor) * cellSize + boardCenterX
    local snapLocalZ = (gridZ - 1 - halfBoardFactor) * cellSize + boardCenterZ
    local worldPos = self.positionToWorld({x = snapLocalX, y = stoneY, z = snapLocalZ})

    dropped_object.setPosition(worldPos)
    dropped_object.setRotation(self.getRotation())
    dropped_object.setLock(true)

    -- Передача в логику правил Го
    local stoneColorCode = isBlack and 1 or 2
    processMoveRules(gridX, gridZ, stoneColorCode, dropped_object, player_color)
end
-- =========================================================================
-- БЛОК 5: ЛОГИКА ПРАВИЛ ГО, КУ КO, СУИЦИДЫ И ХЭШ-КАРТЫ
-- =========================================================================

function processMoveRules(x, z, colorCode, stoneObj, player_color)
    local t = LANG_DICT[currentLang]
    local opponentColorCode = (colorCode == 1) and 2 or 1
    
    -- Сохраняем бэкап состояния для отката
    local backupState = copyBoardState(boardState)
    
    -- Предварительно размещаем камень в виртуальной матрице
    boardState[x][z] = colorCode
    boardObjects[x][z] = stoneObj

    -- Хэш-карта для уникальной фильтрации захваченных камней (Решение проблемы дублирования)
    local stonesToRemove = {}
    local capturedMap = {}

    -- Сканируем 4 направления вокруг поставленного камня на наличие вражеских групп с 0 свобод
    for _, dir in ipairs(DIRECTIONS) do
        local nx, nz = x + dir.x, z + dir.z
        if nx >= 1 and nx <= BOARD_SIZE and nz >= 1 and nz <= BOARD_SIZE then
            if boardState[nx][nz] == opponentColorCode then
                local group, liberties = getGroupDetails(nx, nz, opponentColorCode)
                if liberties == 0 then
                    for _, pos in ipairs(group) do
                        local key = pos.x .. ":" .. pos.z
                        if not capturedMap[key] then
                            capturedMap[key] = true
                            table.insert(stonesToRemove, pos)
                        end
                    end
                end
            end
        end
    end

    -- Флаг захвата вражеских камней
    local captureHappened = (#stonesToRemove > 0)

    if captureHappened then
        -- Физическое удаление съеденных вражеских камней
        for _, pos in ipairs(stonesToRemove) do
            local capturedObj = boardObjects[pos.x][pos.z]
            if capturedObj and not capturedObj.isDestroyed() then
                capturedObj.setLock(false)
                capturedObj.destruct()
            end
            boardState[pos.x][pos.z] = 0
            boardObjects[pos.x][pos.z] = nil
        end
        broadcastToAll(t.msg_captured .. tostring(#stonesToRemove), {0.2, 0.9, 0.2})
    else
        -- Если захвата не было, проверяем собственную группу на суицид
        local _, ownLiberties = getGroupDetails(x, z, colorCode)
        if ownLiberties == 0 then
            broadcastToColor(t.msg_suicide, player_color, {0.9, 0.2, 0.2})
            revertMove(x, z, backupState)
            return
        end
    end

    -- Проверка правила Ко (сравнение с предыдущим ходом)
    if previousBoardState and compareBoardStates(boardState, previousBoardState) then
        broadcastToColor(t.rule_ko, player_color, {0.9, 0.2, 0.2})
        revertMove(x, z, backupState)
        return
    end

    -- Ход полностью легален: сохраняем историю для следующего Ко и сбрасываем пасы
    previousBoardState = backupState
    consecutivePasses = 0

    -- Логирование хода в чат
    local colName = (colorCode == 1) and "Black" or "White"
    local coordString = string.format("[%d, %d]", x, z)
    local pName = Player[player_color].steam_name
    broadcastToAll(string.format(t.msg_made_move, pName, coordString), {0.8, 0.8, 0.8})

    -- Передаем право хода
    currentTurn = (colorCode == 1) and "White" or "Black"
    createGameButtons()
end

-- Полное уничтожение фантомного камня при нелегальном ходе (Решение проблемы №4)
function revertMove(x, z, backupState)
    local stoneObj = boardObjects[x][z]
    if stoneObj and not stoneObj.isDestroyed() then 
        stoneObj.setLock(false)
        stoneObj.destruct() 
    end
    boardState = copyBoardState(backupState)
    boardObjects[x][z] = nil
end
-- =========================================================================
-- БЛОК 6: ВСПОМОГАТЕЛЬНЫЕ АЛГОРИТМЫ ПОИСКА ГРУПП И КОПИРОВАНИЯ
-- =========================================================================

function getGroupDetails(startX, startZ, targetColor)
    local queue = {{x = startX, z = startZ}}
    local visited = {}
    visited[startX .. ":" .. startZ] = true
    
    local group = {{x = startX, z = startZ}}
    local libertiesMap = {}
    local libertiesCount = 0

    local head = 1
    while head <= #queue do
        local curr = queue[head]
        head = head + 1

        for _, dir in ipairs(DIRECTIONS) do
            local nx, nz = curr.x + dir.x, curr.z + dir.z
            if nx >= 1 and nx <= BOARD_SIZE and nz >= 1 and nz <= BOARD_SIZE then
                local cell = boardState[nx][nz]
                if cell == 0 then
                    local libKey = nx .. ":" .. nz
                    if not libertiesMap[libKey] then
                        libertiesMap[libKey] = true
                        libertiesCount = libertiesCount + 1
                    end
                elseif cell == targetColor then
                    local visitKey = nx .. ":" .. nz
                    if not visited[visitKey] then
                        visited[visitKey] = true
                        table.insert(queue, {x = nx, z = nz})
                        table.insert(group, {x = nx, z = nz})
                    end
                end
            end
        end
    end

    return group, libertiesCount
end

function copyBoardState(source)
    local dest = {}
    for i = 1, BOARD_SIZE do
        dest[i] = {}
        for j = 1, BOARD_SIZE do
            dest[i][j] = source[i][j]
        end
    end
    return dest
end

function compareBoardStates(stateA, stateB)
    for i = 1, BOARD_SIZE do
        for j = 1, BOARD_SIZE do
            if stateA[i][j] ~= stateB[i][j] then
                return false
            end
        end
    end
    return true
end
-- =========================================================================
-- БЛОК 7: НЕВИДИМЫЕ КЛИК-ЗОНЫ ДЛЯ РАЗМЕТКИ МЕРТВЫХ КАМНЕЙ
-- =========================================================================

function setScoringNovice(obj, player_color)
    local t = LANG_DICT[currentLang]
    gamePhase = "SCORING_NOVICE"
    consecutivePasses = 0
    broadcastToAll(t.score_novice_activated, {0.2, 0.7, 0.9})
    createGameButtons()
end

-- Включение режима Мастеров и создание невидимых клик-зон на камнях
function setScoringMaster(obj, player_color)
    local t = LANG_DICT[currentLang]
    gamePhase = "SCORING_MASTER"
    broadcastToAll(t.score_master_activated, {0.6, 0.3, 0.8})
    createGameButtons()
    
    -- Генерируем невидимые триггеры на каждом камне, который сейчас есть на поле
    refreshStoneClickButtons()
end

-- Функция создает полностью невидимые кнопки прямо поверх 3D-моделей камней
function refreshStoneClickButtons()
    for x = 1, BOARD_SIZE do
        for z = 1, BOARD_SIZE do
            local stone = boardObjects[x][z]
            if stone and not stone.isDestroyed() then
                stone.clearButtons() -- Удаляем старые кнопки перед перерисовкой
                
                -- Создаем абсолютно прозрачную кнопку-пустышку для отлова клика
                stone.createButton({
                    click_function = "toggleStoneDeathStatus",
                    function_owner = self,
                    label = "",          -- Текст полностью убран за ненадобностью
                    position = {0, 0.2, 0},
                    rotation = {0, 0, 0},
                    width = 350,         -- Чуть увеличили область клика для удобства
                    height = 350,
                    font_size = 1,
                    color = {0, 0, 0, 0.0}, -- 100% прозрачность подложки
                    font_color = {0, 0, 0, 0.0} -- 100% прозрачность шрифта
                })
            end
        end
    end
end

-- Глобальный обработчик клика по прозрачной кнопке камня
function toggleStoneDeathStatus(clickedStone, player_color)
    if gamePhase ~= "SCORING_MASTER" then return end

    -- Ищем, по какому именно камню в нашей матрице кликнули
    for x = 1, BOARD_SIZE do
        for z = 1, BOARD_SIZE do
            if boardObjects[x][z] == clickedStone then
                local colorCode = boardState[x][z]
                -- Захватываем всю группу камней целиком
                local group, _ = getGroupDetails(x, z, colorCode)
                local isCurrentlyMarked = deadMarked[x][z]

                -- Меняем статус живой/мертвый для всей группы сразу
                for _, pos in ipairs(group) do
                    deadMarked[pos.x][pos.z] = not isCurrentlyMarked
                    local stone = boardObjects[pos.x][pos.z]
                    
                    if stone and not stone.isDestroyed() then
                        -- Считываем оригинальный цвет камня (черный или белый)
                        local originalColor = stone.getColorTint() 
                        
                        if deadMarked[pos.x][pos.z] then
                            -- Меняем ТОЛЬКО альфа-канал на 0.25 (камень блекнет)
                            stone.setColorTint({
                                r = originalColor.r, 
                                g = originalColor.g, 
                                b = originalColor.b, 
                                a = 0.25
                            })
                        else
                            -- Возвращаем альфа-канал на 1.0 (оригинальный цвет без изменений)
                            stone.setColorTint({
                                r = originalColor.r, 
                                g = originalColor.g, 
                                b = originalColor.b, 
                                a = 1.0
                            })
                        end
                    end
                end
                
                -- Перерисовывать кнопки больше не нужно, так как текста на них нет
                return
            end
        end
    end
end

function confirmMasterScoring(obj, player_color)
    local t = LANG_DICT[currentLang]

    if player_color ~= registeredBlack and player_color ~= registeredWhite then
        broadcastToColor(t.msg_reset_need_reg, player_color, {0.9, 0.2, 0.2})
        return
    end

    -- Навсегда физически удаляем все размеченные мастерами мертвые структуры
    for x = 1, BOARD_SIZE do
        for z = 1, BOARD_SIZE do
            if deadMarked[x][z] then
                local deadObj = boardObjects[x][z]
                if deadObj and not deadObj.isDestroyed() then
                    deadObj.setLock(false)
                    deadObj.destruct()
                end
                boardState[x][z] = 0
                boardObjects[x][z] = nil
            end
        end
    end

    -- Запускаем финальный математический китайский подсчет площади площади (Area Scoring)
    executeAutomaticScoring()
end
-- =========================================================================
-- БЛОК 8: КИТАЙСКИЙ ПОДСЧЕТ ОЧКОВ (AREA SCORING) И ОПРЕДЕЛЕНИЕ ТЕРРИТОРИИ
-- =========================================================================

function executeAutomaticScoring()
    local t = LANG_DICT[currentLang]
    
    local blackScore = 0
    local whiteScore = KOMI -- Белым сразу добавляется Коми

    -- Карта посещения для поиска изолированных пустых территорий
    local visitedTerritory = {}
    for i = 1, BOARD_SIZE do
        visitedTerritory[i] = {}
        for j = 1, BOARD_SIZE do
            visitedTerritory[i][j] = false
        end
    end

    -- Шаг 1: Считаем живые камни на доске (Базовое правило Area Scoring)
    for x = 1, BOARD_SIZE do
        for z = 1, BOARD_SIZE do
            if boardState[x][z] == 1 then
                blackScore = blackScore + 1
            elseif boardState[x][z] == 2 then
                whiteScore = whiteScore + 1
            end
        end
    end

    -- Шаг 2: Сканирование пустых областей и определение их принадлежности
    for x = 1, BOARD_SIZE do
        for z = 1, BOARD_SIZE do
            if boardState[x][z] == 0 and not visitedTerritory[x][z] then
                local territoryPoints, owner = analyzeTerritoryArea(x, z, visitedTerritory)
                if owner == 1 then
                    blackScore = blackScore + territoryPoints
                elseif owner == 2 then
                    whiteScore = whiteScore + territoryPoints
                end
            end
        end
    end

    -- Шаг 3: Вывод турнирных результатов в чат
    gamePhase = "ENDED"
    createGameButtons()

    broadcastToAll(t.score_final_header, {0.2, 0.9, 0.2})
    broadcastToAll(t.score_black_total .. tostring(blackScore), {0.5, 0.5, 0.5})
    broadcastToAll(t.score_white_total .. tostring(whiteScore), {0.9, 0.9, 0.9})

    if blackScore > whiteScore then
        local diff = blackScore - whiteScore
        broadcastToAll(string.format(t.score_black_win, tostring(diff)), {0.1, 0.8, 0.1})
    else
        local diff = whiteScore - blackScore
        broadcastToAll(string.format(t.score_white_win, tostring(diff)), {0.1, 0.8, 0.1})
    end
end

-- Алгоритм заливки для определения владельца замкнутого пустого пространства
function analyzeTerritoryArea(startX, startZ, visitedGlobal)
    local queue = {{x = startX, z = startZ}}
    visitedGlobal[startX][startZ] = true
    
    local areaPoints = 1
    local adjacentColors = {}

    local head = 1
    while head <= #queue do
        local curr = queue[head]
        head = head + 1

        for _, dir in ipairs(DIRECTIONS) do
            local nx, nz = curr.x + dir.x, curr.z + dir.z
            if nx >= 1 and nx <= BOARD_SIZE and nz >= 1 and nz <= BOARD_SIZE then
                local cell = boardState[nx][nz]
                if cell == 0 then
                    if not visitedGlobal[nx][nz] then
                        visitedGlobal[nx][nz] = true
                        areaPoints = areaPoints + 1
                        table.insert(queue, {x = nx, z = nz})
                    end
                else
                    adjacentColors[cell] = true
                end
            end
        end
    end

    -- ОШИБКА ИСПРАВЛЕНА: корректное чтение булевых флагов из таблицы ключей
    local touchesBlack = adjacentColors[1] or false
    local touchesWhite = adjacentColors[2] or false

    if touchesBlack and not touchesWhite then
        return areaPoints, 1 -- Чистая территория Черных
    elseif touchesWhite and not touchesBlack then
        return areaPoints, 2 -- Чистая территория Белых
    else
        return areaPoints, 0 -- Нейтральные пункты (Дамэ) или спорная зона
    end
end