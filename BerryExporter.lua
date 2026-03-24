local ctx = reaper.ImGui_CreateContext('Berry Exporter')
local berry_violet = 0x8A2BE2FF
local berry_hover = 0x9932CCFF
local berry_active = 0x4B0082FF

local columns = {
  {name = "Track Number", active = true, id = "NUM"},
  {name = "Track Name", active = true, id = "NAME"},
  {name = "Start Time", active = true, id = "START"},
  {name = "Duration", active = true, id = "LEN"},
  {name = "Peak Volume (dB)", active = true, id = "PEAK"}
}



function GetTrackData(track, id)

  if id == "NUM" then
    return tostring(math.floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")))
  elseif id == "NAME" then
    local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    return name
  elseif id == "START" then
    local first_item = reaper.GetTrackMediaItem(track, 0)
    if first_item then
      return string.format("%.3f", reaper.GetMediaItemInfo_Value(first_item, "D_POSITION"))
    end
    return "0.000"
  elseif id == "LEN" then
    local track_len = 0
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
      local item = reaper.GetTrackMediaItem(track, i)
      local i_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local i_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      if i_start + i_len > track_len then track_len = i_start + i_len end
    end
    return string.format("%.3f", track_len)
  elseif id == "PEAK" then
    local peak = reaper.Track_GetPeakInfo(track, 0)
    if peak > 0 then
      local db = 20 * math.log(peak, 10)
      return string.format("%.2f", db)
    end
    return "-inf"
  end
  return ""
end

function SaveCSV()
  local retval, filename = reaper.JS_Dialog_BrowseForSaveFile("Zapisz Berry Report CSV", "", "", "CSV files (*.csv)\0*.csv\0")
  if retval == 0 or filename == "" then return end
  if not filename:match("%.csv$") then filename = filename .. ".csv" end

  local file = io.open(filename, "w")
  local header = {}
  for _, col in ipairs(columns) do
    if col.active then table.insert(header, col.name) end
  end
  file:write(table.concat(header, ";") .. "\n")

  for i = 0, reaper.CountSelectedTracks(0) - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    local row = {}
    for _, col in ipairs(columns) do
      if col.active then
        table.insert(row, GetTrackData(track, col.id))
      end
    end
    file:write(table.concat(row, ";") .. "\n")
  end

  file:close()
  reaper.ShowMessageBox("CSV gotowy dźwiękowy świrze!", "Berry Exporter", 0)
end

function RunUI()
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(), berry_violet)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x221133FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x332244FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), berry_violet)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), berry_hover)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), berry_active)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), berry_violet)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x1A0A26FF)

  local visible, open = reaper.ImGui_Begin(ctx, 'Berry Exporter', true)
  if visible then
    reaper.ImGui_Text(ctx, "Wybierz kolumny do pliku CSV:")
    reaper.ImGui_Spacing(ctx)
    
    for i, col in ipairs(columns) do
      local retval, v = reaper.ImGui_Checkbox(ctx, col.name, col.active)
      if retval then columns[i].active = v end
    end
    
    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Spacing(ctx)
    
    if reaper.ImGui_Button(ctx, 'EKSPORTUJ DO CSV', -1, 35) then
      SaveCSV()
    end
    reaper.ImGui_End(ctx)
  end
  
  reaper.ImGui_PopStyleColor(ctx, 8)
  
  if open then reaper.defer(RunUI) end
end

reaper.defer(RunUI)

-- Jagoda Jazownik XD