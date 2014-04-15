if not VIP_USER then
  PrintChat("Unstoppable Series is for vip only.")
  return
end
if myHero.charName ~= "Zed" then return end

local REQUIRED_LIBS = {
        ["VPrediction"] = "https://bitbucket.org/honda7/bol/raw/master/Common/VPrediction.lua",
        ["SOW"] = "https://bitbucket.org/honda7/bol/raw/master/Common/SOW.lua",
        ["SourceLib"] = "https://bitbucket.org/TheRealSource/public/raw/master/common/SourceLib.lua",
    }

local DOWNLOADING_LIBS, DOWNLOAD_COUNT = false, 0
local SELF_NAME = GetCurrentEnv() and GetCurrentEnv().FILE_NAME or ""

function AfterDownload()
    DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
    if DOWNLOAD_COUNT == 0 then
        DOWNLOADING_LIBS = false
        print("<b>[Unstoppable Series]: Required libraries downloaded successfully, please reload (double F9).</b>")
    else
        print(DOWNLOAD_COUNT.." downloads remaining...")
    end
end

for DOWNLOAD_LIB_NAME, DOWNLOAD_LIB_URL in pairs(REQUIRED_LIBS) do
    if FileExist(LIB_PATH .. DOWNLOAD_LIB_NAME .. ".lua") then
        require(DOWNLOAD_LIB_NAME)
    else
        DOWNLOADING_LIBS = true
        DOWNLOAD_COUNT = DOWNLOAD_COUNT + 1
        DownloadFile(DOWNLOAD_LIB_URL, LIB_PATH .. DOWNLOAD_LIB_NAME..".lua", AfterDownload)
    end
end

if DOWNLOADING_LIBS then print("Downloading required libraries...") return end


function OnLoad()
  LoadVars()
  LoadMenu()
  PrintChat("<font color='#0000FF'> >> Unstoppable Zed V1.0 Loaded! <<</font>")
end

function LoadMenu()

  Menu = scriptConfig("Unstoppable Zed by Rythimy V1.0", "Unstoppable Zed")
  
  Menu:addSubMenu("Target selector", "STS")
  STS:AddToMenu(Menu.STS)
  
  Menu:addSubMenu("Simple Orbwalker", "SOW")
      AArangeCircle:AddToMenu(Menu.SOW, "Draw Auto Attack range", true, true, true)
      SOWi:LoadToMenu(Menu.SOW)
  
  Menu:addSubMenu("Zed - Combo Settings", "combo")
    Menu.combo:addParam("combo", "Full Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    Menu.combo:addParam("rMode", "Ult settings", SCRIPT_PARAM_LIST, 3, {"Don't use", "Use always", "Use when killable"})
    Menu.combo:addParam("wMode", "W settings", SCRIPT_PARAM_LIST, 2, {"Use always", "Use when enemy is out of range"})
    Menu.combo:permaShow("combo")
  
    
  Menu:addSubMenu("Zed - Harass Settings", "harass")
    Menu.harass:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
    Menu.harass:addParam("wMode", "W settings", SCRIPT_PARAM_LIST, 3, {"Don't use", "Use always", "Use when WE is hittable"})
    Menu.harass:permaShow("harass")
  
  --Menu:addSubMenu("Zed - Killsteal Settings", "ks")
  --  Menu.ks:addParam("killsteal", "Enable KS", SCRIPT_PARAM_ONOFF, true)
    
  Menu:addSubMenu("Zed - Ignite Settings", "mignite") 
    Menu.mignite:addParam("igniteOptions", "Ignite Options", SCRIPT_PARAM_LIST, 2, {"Don't use", "Combo mode", "KS Mode"})
    Menu.mignite:permaShow("igniteOptions")
    
  Menu:addSubMenu("Zed - Item Settings", "mitems")  
    Menu.mitems:addParam("itemsOptions", "Item Options", SCRIPT_PARAM_LIST, 2, {"Don't use", "Combo mode", "KS Mode"})
    Menu.mitems:permaShow("itemsOptions")
    
  Menu:addSubMenu("Zed - Drawing Settings", "drawing")  
    DamageManager:AddToMenu(Menu.drawing, {_R, _Q, _E, _P, _AA, _IGNITE})
    QrangeCircle:AddToMenu(Menu.drawing, "Draw Q Range", true, true, true)
    WrangeCircle:AddToMenu(Menu.drawing, "Draw W Range", true, true, true)
    ErangeCircle:AddToMenu(Menu.drawing, "Draw E Range", true, true, true)
    RrangeCircle:AddToMenu(Menu.drawing, "Draw R Range", true, true, true)
end

function LoadVars()
  qRange, wRange, eRange, rRange, iRange = 900, 550, 280, 625, 600
  qReady, wReady, eReady, rReady = false, false, false, false
  qDelay, qWidth, qSpeed = 0.25, 80, 1750
  
  wObj, rObj = nil, nil
  wUsed = false
  
  colorText = ARGB(255,0,255,0)


  orange = 0xFFFFE303
  green = ARGB(255,0,255,0)
  blue = ARGB(255,0,0,255)
  red = ARGB(255,255,0,0)
  
  STS = SimpleTS(STS_LESS_CAST_PHYSICAL)
  
  DManager = DrawManager()
  VP = VPrediction(true)
  SOWi = SOW(VP, STS)
  AArangeCircle = DManager:CreateCircle(myHero, SOWi:MyRange(), 1, {255, 255, 255, 255})
  QrangeCircle = DManager:CreateCircle(myHero, 900, 1, {255, 0, 255, 0})
  WrangeCircle = DManager:CreateCircle(myHero, 550, 1, {255, 0, 255, 0})
  ErangeCircle = DManager:CreateCircle(myHero, 280, 1, {255, 0, 255, 0})
  RrangeCircle = DManager:CreateCircle(myHero, 625, 1, {255, 0, 255, 0})
  
  DamageManager = DamageLib(myHero)
  
  DamageManager:RegisterDamageSource(_QDOUBLE, _PHYSICAL, 17.5, 20, _PHYSICAL, _BONUS_AD, 0.5, function() return (player:CanUseSpell(_W) == READY) end)
  
  DamageManager:RegisterDamageSource(_Q, _PHYSICAL, 35, 40, _PHYSICAL, _BONUS_AD, 1.0, function() return (player:CanUseSpell(_Q) == READY) end, function(target) return DamageManager:CalcSpellDamage(target, _QDOUBLE) end)
  
  DamageManager:RegisterDamageSource(_E, _PHYSICAL, 30, 30, _PHYSICAL, _BONUS_AD, 0.9, function() return (player:CanUseSpell(_E) == READY) end)
    
  DamageManager:RegisterDamageSource(_P, _MAGIC, 0, 0, _MAGIC, _AP, 0, function() return true end, function(target) if not HasBuff(target, "zedpassivecd") then return 0.08 * target.maxHealth else return 0 end end)
   
  DamageManager:RegisterDamageSource(_R, _PHYSICAL, 0, 0, _PHYSICAL, _AD, 1.0, function() return ((player:CanUseSpell(_R) == READY) and (myHero:GetSpellData(_R).name ~= "ZedR2")) end, function(target) return (0.05 + (player:GetSpellData(_R).level * 0.15)) * (DamageManager:CalcComboDamage(target, {_Q, _E, _P, _AA})) end)

  end
  
function OnTick()
  if (_G.AutoCarry == nil and _G.MMA_Loaded == nil) then
    if SOWi and AArangeCircle then
      AArangeCircle.radius = SOWi:MyRange()
    end
  else
    if SOWi.Menu.Enabled then
      SOWi.Menu.Enabled = false
      AArangeCircle.enabled = false
      print("SAC or MMA is detected. Simple Orbwalker is disabled.")
    end
  end
  
  RenewVars()

  if qReady then
    QrangeCircle.enabled = true
  else
    QrangeCircle.enabled = false
  end
  if wReady then
    WrangeCircle.enabled = true
  else
    WrangeCircle.enabled = false
  end
  if eReady then
    ErangeCircle.enabled = true
  else
    ErangeCircle.enabled = false
  end
  if rReady then
    RrangeCircle.enabled = true
  else
    RrangeCircle.enabled = false
  end
  
  if Menu.mignite.igniteOptions ~= 1 then KsIgnite() end
  if Menu.mitems.itemsOptions ~= 1 then KsItems() end
  if target ~= nil and ValidTarget(target) then
    if Menu.combo.combo then DoCombo() end
    if Menu.harass.harass then DoHarass() end
  end
end


function DoCombo()
  if ValidTarget(target) then
    if rReady and (Menu.combo.rMode == 2) then
      if myHero:GetSpellData(_R).name ~= "ZedR2" then
        if (GetDistance(target) < 625) then --zedw2
          CastSpell(_R, target)
        elseif wReady and (not wUsed) then
          if CastW() then
           CastSpell(_W)
          end
        elseif  myHero:GetSpellData(_W).name == "zedw2" then
          CastSpell(_W)
        end
        return
      end
    end
    
    if DamageManager:IsKillable(target, {_R, _Q, _E, _P, _AA, _IGNITE}) then
      if rReady and (Menu.combo.rMode == 3) then
        if myHero:GetSpellData(_R).name ~= "ZedR2" then
          if (GetDistance(target) < 625) then
            CastSpell(_R, target)
          elseif wReady and (not wUsed) then
            if CastW() then
              CastSpell(_W)
            end
          elseif  myHero:GetSpellData(_W).name == "zedw2" then
            CastSpell(_W)
          end
          return
        end
      end
            
      if Menu.mitems.itemsOptions == 2 then
        CastItems()
      end
      if Menu.mignite.igniteOptions == 2 then
        if GetDistance(target) <= 600 then
          CastSpell(ignite, target)
        end
      end      
    end
  if Menu.combo.wMode == 1 then
    if wReady and not wUsed then
      if not CastWFORE() and GetDistance(target) > 750 then
        CastW()
      end
    end
  else
    if GetDistance(target) > 280 then
      if wReady and not wUsed then
        if not CastWFORE() and GetDistance(target) > 750 then
          CastW()
        end
      end
    end
  end
  if (not wUsed and not wReady) or (not wUsed and GetDistance(target) > 280) or (wUsed and wObj ~= nil and wObj.valid) then
    CastE()
    CastQ()
  end
end
  DoSwap()
end

function DoSwap()
  local wDist = 0
  local rDist = 0
  if wObj and wObj.valid then wDist = GetDistance(target, wObj) end
  if rObj and rObj.valid then rDist = GetDistance(target, rObj) end 
  if GetDistance(target) > 150 then
    if wDist < rDist and wDist ~= 0 and GetDistance(target) > wDist and (myHero:CanUseSpell(_W) == READY) then
      CastSpell(_W)
    elseif rDist < wDist and rDist ~= 0 and GetDistance(target) > rDist then
      CastSpell(_R)
    end
  end
end

function DoHarass()
  if ValidTarget(target) then
    if (Menu.harass.wMode == 3) and (qReady or eReady) and (not wUsed) and wReady then
      CastWFORE()
    elseif (Menu.harass.wMode == 2) and (qReady or eReady) and (not wUsed) and wReady then
      if not CastWFORE() and GetDistance(target) > 750 then
        CastW()
      end
    end
    if (not wUsed and not wReady and Menu.harass.wMode == 1) or (wUsed and wObj ~= nil and wObj.valid) then
      CastE()
      CastQ()
    end
  end
end


function CastQ()
  if qReady then
    local OriObj = myHero
    local wDist = 0
    local rDist = 0
    if wObj and wObj.valid then wDist = GetDistance(target, wObj) end
    if rObj and rObj.valid then rDist = GetDistance(target, rObj) end 
    if GetDistance(target) > 150 then
      if wDist < rDist and wDist ~= 0 and GetDistance(target) > wDist then
        OriObj = wObj
      elseif rDist < wDist and rDist ~= 0 and GetDistance(target) > rDist then
        OriObj = rObj
      end
    end

    if (GetDistance(target, OriObj) < qRange) and ValidTarget(target) then
      local CastPosition,  HitChance, HeroPosition = VP:GetLineCastPosition(target, qDelay, qWidth, qRange, qSpeed, OriObj, false)
      if HitChance > 0 then
        CastSpell(_Q, CastPosition.x, CastPosition.z)
        return true
      end
    end
  end
  return false
end


function CastE()
  if eReady then
    local box = 280
    if ((not wUsed or (wObj ~= nil and wObj.valid)) and GetDistance(target) < box) or (wUsed and wObj ~= nil and wObj.valid and GetDistance(target, wObj) < box) or (rObj ~= nil and rObj.valid and GetDistance(target, rObj) < box) then
      CastSpell(_E)
      return true
    else
      for i = 1, heroManager.iCount do
        local enemy = heroManager:getHero(i)
        if enemy.team ~= myHero.team then
          if ValidTarget(enemy) and (not wUsed or (wObj ~= nil and wObj.valid)) and GetDistance(enemy) < box or (wUsed and wObj ~= nil and wObj.valid and GetDistance(enemy, wObj) < box) or (rObj ~= nil and rObj.valid and GetDistance(enemy, rObj) < box) then
            CastSpell(_E)
            return true
          end
        end
      end
    end
  end
  return false
end


function CastWFORE()
  if wReady and (myHero:GetSpellData(_W).name ~= "zedw2") and ValidTarget(target) then
    local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(target, 0.25, 280, 550, 1500, myHero, false)
    if HitChance > 1 then
      CastSpell(_W, CastPosition.x, CastPosition.z)
      return true
    end
  end
  return false
end

function CastW()

  if wReady and (myHero:GetSpellData(_W).name ~= "zedw2") and ValidTarget(target) then
    local MaxEndPosition = myHero + Vector(target.x - myHero.x, 0, target.z - myHero.z):normalized()*550
    CastSpell(_W, MaxEndPosition.x, MaxEndPosition.z)  
    return true
  end
  return false
end

function CastItems()
  if not ValidTarget(target) then 
    return
  else
    if GetDistance(target) <=500 then
      CastItem(3144, target) --Bilgewater Cutlass
      CastItem(3153, target) --Blade Of The Ruined King
    end
    if GetDistance(target) <= 350 then
      CastItem(3074, target) --Ravenous Hydra
      CastItem(3077, target) --Tiamat
      CastItem(3142, target) --Youmuu's Ghostblade
    end
    if GetDistance(target) <= 125 then
      CastItem(3131, target) --Sword of the Divine
    end
  end
end

function RenewVars()

  target = nil
  for i = 1, heroManager.iCount, 1 do
    local enemyhero = heroManager:getHero(i)
    if enemyhero.team ~= myHero.team and ValidTarget(enemyhero, 1400) and HasBuff(enemyhero, "zedulttargetmark") then        
      target = enemyhero
    end
  end
  if target == nil then
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then
      target = _G.MMA_Target
    elseif _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then
      target = _G.AutoCarry.Attack_Crosshair.target
    else
      target = STS:GetTarget(1150)
    end
  end

  
  if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
    ignite = SUMMONER_1
  elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
    ignite = SUMMONER_2
  end
  
  BOTRKSlot = GetInventorySlotItem(3153) --Blade Of The Ruined King
  BCRSlot = GetInventorySlotItem(3144) --Bilgewater Cutlass
  HYDRASlot = GetInventorySlotItem(3074) --Ravenous Hydra
  TIAMATSlot = GetInventorySlotItem(3077) --Tiamat
  SOTDSlot = GetInventorySlotItem(3131) --Sword of the Divine
  
  qReady = (myHero:CanUseSpell(_Q) == READY)
  wReady = (myHero:CanUseSpell(_W) == READY)
  eReady = (myHero:CanUseSpell(_E) == READY)
  rReady = (myHero:CanUseSpell(_R) == READY)
  iReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
  BotrkReady = (BotrkSlot ~= nil and myHero:CanUseSpell(BotrkSlot) == READY) --Blade Of The Ruined King
  BCRReady = (BCRSlot ~= nil and myHero:CanUseSpell(BCRSlot) == READY) --Bilgewater Cutlass
  HYDRAReady = (HYDRASlot ~= nil and myHero:CanUseSpell(HYDRASlot) == READY) --Ravenous Hydra
  TIAMATReady = (TIAMATSlot ~= nil and myHero:CanUseSpell(TIAMATSlot) == READY) --Tiamat
  SOTDReady = (SOTDSlot ~= nil and myHero:CanUseSpell(SOTDSlot) == READY) --Sword of the Divine
end


function KsIgnite()
  if iReady then
    for i = 1, heroManager.iCount, 1 do
      local enemyhero = heroManager:getHero(i)
      if ValidTarget(enemyhero,600) then
        if enemyhero.health <= getDmg("IGNITE", enemyhero, myHero) then
          CastSpell(ignite, enemyhero)
        end
      end
    end
  end
end

function KsItems()
  if dfgReady then
    for i = 1, heroManager.iCount, 1 do
      local enemyhero = heroManager:getHero(i)
      if ValidTarget(enemyhero,500) then
        if enemyhero.health <= getDmg("RUINEDKING", enemyhero, myHero, 2) then
          CastSpell(BotrkReady, enemyhero)
        end
      end
    end
  end
end

function OnCreateObj(obj)
  if obj.valid and obj.name == "Shadow" then
    if wUsed and wObj == nil then
      wObj = obj
    elseif rObj == nil then
      rObj = obj
    end
  end
end

function OnDeleteObj(obj)
  if obj.valid and wObj and obj == wObj then
    wUsed = false
    wObj = nil  
  elseif obj.valid and rObj and obj == rObj then
    rObj = nil
  end
end

function OnProcessSpell(unit, spell)
  if unit.isMe and spell.name == "ZedShadowDash" then
    wUsed = true
  end
end