property pChanges, pActive, pAnimFrame, pTimer

on prepare me, tdata
  if (tdata[#stuffdata] = "ON") or (tdata[#stuffdata] = "1") then
    me.setOn()
    pChanges = 1
  else
    me.setOff()
    pChanges = 0
  end if
  pTimer = 0
  pAnimFrame = 1
  return 1
end

on updateStuffdata me, tValue
  if (tValue = "ON") or (tValue = "1") then
    me.setOn()
  else
    me.setOff()
  end if
  pChanges = 1
end

on update me
  if me.pSprList.count < 8 then
    return 
  end if
  if not pChanges then
    return 
  end if
  tName = me.pSprList[6].member.name
  tDelim = the itemDelimiter
  the itemDelimiter = "_"
  tClass = tName.item[1..tName.item.count - 6]
  the itemDelimiter = tDelim
  if pActive then
    pTimer = pTimer + 1
    if pTimer > 4 then
      tNewNameE = tClass & "_e_0_1_2_" & me.pDirection[1] & "_" & pActive
      tNewNameG = tClass & "_g_0_1_2_" & me.pDirection[1] & "_" & pActive
      if memberExists(tNewNameE) then
        me.pSprList[5].castNum = abs(getmemnum(tNewNameE))
      end if
      if memberExists(tNewNameG) then
        me.pSprList[7].castNum = abs(getmemnum(tNewNameG))
      end if
      pAnimFrame = pAnimFrame + 1
      if pAnimFrame > 3 then
        pAnimFrame = 1
      end if
      tNewNameH = tClass & "_h_0_1_2_" & me.pDirection[1] & "_" & pAnimFrame
      me.pSprList[8].castNum = abs(getmemnum(tNewNameH))
      tNewNameF = tClass & "_f_0_1_2_" & me.pDirection[1] & "_" & pAnimFrame
      me.pSprList[6].castNum = abs(getmemnum(tNewNameF))
      pTimer = 0
      pChanges = 1
    end if
  else
    tNewNameE = tClass & "_e_0_1_2_" & me.pDirection[1] & "_" & 0
    tNewNameF = tClass & "_f_0_1_2_" & me.pDirection[1] & "_" & 0
    tNewNameG = tClass & "_g_0_1_2_" & me.pDirection[1] & "_" & 0
    tNewNameH = tClass & "_h_0_1_2_" & me.pDirection[1] & "_" & 0
    me.pSprList[5].castNum = abs(getmemnum(tNewNameE))
    me.pSprList[6].castNum = abs(getmemnum(tNewNameF))
    me.pSprList[7].castNum = abs(getmemnum(tNewNameG))
    me.pSprList[8].castNum = abs(getmemnum(tNewNameH))
    pChanges = 0
  end if
  me.pSprList[5].width = me.pSprList[5].member.width
  me.pSprList[5].height = me.pSprList[5].member.height
  me.pSprList[6].width = me.pSprList[6].member.width
  me.pSprList[6].height = me.pSprList[6].member.height
  me.pSprList[7].width = me.pSprList[7].member.width
  me.pSprList[7].height = me.pSprList[7].member.height
  me.pSprList[8].width = me.pSprList[8].member.width
  me.pSprList[8].height = me.pSprList[8].member.height
end

on setOn me
  pActive = 1
end

on setOff me
  pActive = 0
end

on select me
  if the doubleClick then
    if pActive then
      tStr = "OFF"
    else
      tStr = "ON"
    end if
    getThread(#room).getComponent().getRoomConnection().send("SETSTUFFDATA", [#string: string(me.getID()), #string: tStr])
  else
    getThread(#room).getComponent().getRoomConnection().send("MOVE", [#short: me.pLocX, #short: me.pLocY])
  end if
  return 1
end
