local isTimerMode = 1
local isPaused = 1
local currentSeconds = 60
local totalTarget = 60

local savedTimerSeconds = 60
local savedStopwatchSeconds = 0

local function SyncStateVariables()
    SKIN:Bang('!SetVariable', 'IsTitleViewHidden', 0)
    SKIN:Bang('!SetVariable', 'IsTitleEditHidden', 1)

    SKIN:Bang('!SetVariable', 'IsTimeDisplayHidden', 0)
    SKIN:Bang('!SetVariable', 'IsTimeEditHidden', 1)

    if isPaused == 1 then
        SKIN:Bang('!SetVariable', 'IsPlayHidden', 0)
        SKIN:Bang('!SetVariable', 'IsPauseHidden', 1)
    else
        SKIN:Bang('!SetVariable', 'IsPlayHidden', 1)
        SKIN:Bang('!SetVariable', 'IsPauseHidden', 0)
    end

    if isTimerMode == 1 then
        SKIN:Bang('!SetVariable', 'IsEditPenHidden', 0)
        SKIN:Bang('!SetVariable', 'IsTimerHidden', 0)
        SKIN:Bang('!SetVariable', 'IsStopwatchHidden', 1)
        
    else
        SKIN:Bang('!SetVariable', 'IsEditPenHidden', 1)
        SKIN:Bang('!SetVariable', 'IsTimerHidden', 1)
        SKIN:Bang('!SetVariable', 'IsStopwatchHidden', 0)
        
    end
end

function Initialize()
    isTimerMode = tonumber(SKIN:GetVariable('IsTimerMode', 1))
    isPaused = tonumber(SKIN:GetVariable('IsPaused', 1))
    currentSeconds = tonumber(SKIN:GetVariable('PresetTime', 60))
    totalTarget = currentSeconds
    savedTimerSeconds = currentSeconds
    SyncStateVariables()
end

function Update()
    if isPaused == 1 then return end

    if isTimerMode == 1 then
        currentSeconds = currentSeconds - 1
        if currentSeconds <= 0 then
            currentSeconds = 0
            isPaused = 1
            SyncStateVariables()
            SKIN:Bang('!SetVariable', 'IsPaused', 1)
            SKIN:Bang('!UpdateMeter', '*')
            SKIN:Bang('!Redraw')
        end
    else
        currentSeconds = currentSeconds + 1
        if currentSeconds >= 86400 then
            currentSeconds = 0
        end
    end

    SKIN:Bang('!SetVariable', 'CurrentSeconds', currentSeconds)
    return
end

function TogglePause()
    isPaused = (isPaused == 1) and 0 or 1
    SKIN:Bang('!SetVariable', 'IsPaused', isPaused)
    SyncStateVariables()
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

function ToggleMode()
    if isTimerMode == 1 then
        savedTimerSeconds = currentSeconds
    else
        savedStopwatchSeconds = currentSeconds
    end

    isTimerMode = (isTimerMode == 1) and 0 or 1
    isPaused = 1
    
    if isTimerMode == 1 then
        currentSeconds = savedTimerSeconds
        totalTarget = tonumber(SKIN:GetVariable('PresetTime', 60))
    else
        currentSeconds = savedStopwatchSeconds
    end
    
    SKIN:Bang('!SetVariable', 'IsTimerMode', isTimerMode)
    SKIN:Bang('!SetVariable', 'IsPaused', isPaused)
    SKIN:Bang('!SetVariable', 'CurrentSeconds', currentSeconds)
    SyncStateVariables()
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

function Reset()
    isPaused = 1
    if isTimerMode == 1 then
        currentSeconds = tonumber(SKIN:GetVariable('PresetTime', 60))
        savedTimerSeconds = currentSeconds
        totalTarget = currentSeconds
    else
        currentSeconds = 0
        savedStopwatchSeconds = 0
    end
    SKIN:Bang('!SetVariable', 'IsPaused', isPaused)
    SKIN:Bang('!SetVariable', 'CurrentSeconds', currentSeconds)
    SyncStateVariables()
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

function ParseTimeInput(inputStr)
    SKIN:Bang('!SetVariable', 'IsTimeDisplayHidden', 0)
    SKIN:Bang('!SetVariable', 'IsTimeEditHidden', 1)
    if isTimerMode == 1 then
        SKIN:Bang('!SetVariable', 'IsEditPenHidden', 0)
    end

    if not inputStr or inputStr == "" then
        SKIN:Bang('!UpdateMeter', '*')
        SKIN:Bang('!Redraw')
        return
    end

    local parts = {}
    for match in string.gmatch(inputStr, "[^:]+") do
        table.insert(parts, tonumber(match) or 0)
    end
    
    if #parts == 0 then
        SKIN:Bang('!UpdateMeter', '*')
        SKIN:Bang('!Redraw')
        return
    end

    local secs = 0
    if #parts == 1 then
        secs = parts[1] -- Just seconds entered
    elseif #parts == 2 then
        secs = (parts[1] * 60) + parts[2] -- MM:SS entered
    elseif #parts == 3 then
        secs = (parts[1] * 3600) + (parts[2] * 60) + parts[3] -- HH:MM:SS entered
    end
    
    currentSeconds = secs
    totalTarget = secs
    savedTimerSeconds = secs
    SKIN:Bang('!SetVariable', 'PresetTime', secs)
    SKIN:Bang('!SetVariable', 'CurrentSeconds', secs)
    SKIN:Bang('!SetVariable', 'TotalTarget', secs)
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

function SetTaskTitle(newTitle)
    SKIN:Bang('!SetVariable', 'IsTitleViewHidden', 0)
    SKIN:Bang('!SetVariable', 'IsTitleEditHidden', 1)
    
    if newTitle and newTitle ~= "" then
        if string.len(newTitle) > 25 then
            newTitle = string.sub(newTitle, 1, 25)
        end
        SKIN:Bang('!SetVariable', 'TaskTitle', newTitle)
        SKIN:Bang('!WriteKeyValue', 'Variables', 'TaskTitle', newTitle)
    end
    
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

function GetProgress()
    if isTimerMode == 1 then
        local target = totalTarget > 0 and totalTarget or 1
        return currentSeconds / target
    else
        return (currentSeconds % 60) / 60
    end
end

function EditTime()
    if isTimerMode == 1 then
        local timeStr = GetTimeForInput()
        SKIN:Bang('!SetVariable', 'TimeInputDefault', timeStr)
        SKIN:Bang('!SetVariable', 'IsTimeDisplayHidden', 1)
        SKIN:Bang('!SetVariable', 'IsTimeEditHidden', 0)
        SKIN:Bang('!SetVariable', 'IsEditPenHidden', 1)
        SKIN:Bang('!UpdateMeter', '*')
        SKIN:Bang('!Redraw')
        SKIN:Bang('!CommandMeasure', 'MeterTimeInput', 'ExecuteBatch 1')
    end
end

function EditTitle()
    SKIN:Bang('!SetVariable', 'IsTitleViewHidden', 1)
    SKIN:Bang('!SetVariable', 'IsTitleEditHidden', 0)
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
    SKIN:Bang('!CommandMeasure', 'MeterTitleInput', 'ExecuteBatch 1')
end

function GetTimeForInput()
    local h = math.floor(currentSeconds / 3600)
    local m = math.floor((currentSeconds % 3600) / 60)
    local s = currentSeconds % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

function GetFormatted()
    local h = math.floor(currentSeconds / 3600)
    local m = math.floor((currentSeconds % 3600) / 60)
    local s = currentSeconds % 60
    return string.format("%02dh %02dm %02ds", h, m, s)
end

function CancelEditTitle()
    SKIN:Bang('!SetVariable', 'IsTitleViewHidden', 0)
    SKIN:Bang('!SetVariable', 'IsTitleEditHidden', 1)
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

function CancelEditTime()
    SKIN:Bang('!SetVariable', 'IsTimeDisplayHidden', 0)
    SKIN:Bang('!SetVariable', 'IsTimeEditHidden', 1)
    SKIN:Bang('!SetVariable', 'IsEditPenHidden', 0)
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

function ToggleInfo()
    local isInfoOpen = tonumber(SKIN:GetVariable('IsInfoOpen', '0'))
    if isInfoOpen == 1 then
        SKIN:Bang('!SetVariable', 'IsInfoOpen', '0')
    else
        SKIN:Bang('!SetVariable', 'IsInfoOpen', '1')
    end
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

