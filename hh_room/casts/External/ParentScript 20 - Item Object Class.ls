property pClass, pName, pCustom, pType, pSprList, pLocX, pLocY, pLocH, pLocZ, pXFactor, pWallX, pWallY, pLocalX, pLocalY, pFormatVer, pDirection, pParentWallLocZ

on construct me
  pClass = EMPTY
  pName = EMPTY
  pCustom = EMPTY
  pType = EMPTY
  pSprList = []
  pLocX = 0
  pLocY = 0
  pLocH = 0
  pLocZ = 0
  pWallX = 0
  pWallY = 0
  pLocalX = 0
  pLocalY = 0
  pFormatVer = 0
  pDirection = 0
  pParentWallLocZ = VOID
  return 1
end

on deconstruct me
  repeat with tSpr in pSprList
    releaseSprite(tSpr.spriteNum)
  end repeat
  pParentWallLocZ = VOID
  pSprList = []
  return 1
end

on define me, tProps
  pClass = tProps[#class]
  pLocX = tProps[#x]
  pLocY = tProps[#y]
  pLocH = tProps[#h]
  pLocZ = tProps[#z]
  pLocalX = tProps[#local_x]
  pLocalY = tProps[#local_y]
  pWallX = tProps[#wall_x]
  pWallY = tProps[#wall_y]
  pFormatVer = tProps[#formatVersion]
  pDirection = tProps[#direction]
  pType = tProps[#type]
  pXFactor = getThread(#room).getInterface().getGeometry().pXFactor
  case pClass of
    "poster":
      pName = getText("poster_" & pType & "_name", "poster_" & pType & "_name")
      pCustom = getText("poster_" & pType & "_desc", "poster_" & pType & "_desc")
    "post.it.vd", "post.it":
      pName = getText("wallitem_" & pClass & "_name", "wallitem_" & pClass & "_name")
      pCustom = getText("wallitem_" & pClass & "_desc", "wallitem_" & pClass & "_desc")
    "photo":
      pName = getText("wallitem_" & pClass & "_name", "wallitem_" & pClass & "_name")
      pCustom = getText("wallitem_" & pClass & "_desc", "wallitem_" & pClass & "_desc")
  end case
  me.solveMembers()
  me.updateLocation()
  return 1
end

on getClass me
  return pClass
end

on setDirection me, tDirection
  me.pDirection = tDirection
end

on getInfo me
  tInfo = [:]
  tInfo[#name] = pName
  tInfo[#class] = pClass
  tInfo[#custom] = pCustom
  tInfo[#smallmember] = pClass & "_small"
  if memberExists(pClass & "_small") then
    tInfo[#image] = member(getmemnum(pClass & "_small")).image
  else
    if pSprList.count > 0 then
      tTestMem2 = pSprList[1].member.name.char[1..length(pSprList[1].member.name) - 11] & "small"
      if memberExists(tTestMem2) then
        tInfo[#image] = getMember(tTestMem2).image
      else
        tInfo[#image] = pSprList[1].member.image
      end if
    else
      tInfo[#image] = getMember("no_icon_small").image
    end if
  end if
  return tInfo
end

on getLocation me
  return [pWallX, pWallY]
end

on getCustom me
  return pCustom
end

on getSprites me
  return pSprList
end

on select me
  return 1
end

on solveMembers me
  case pClass of
    "post.it", "post.it.vd":
      tMemName = pDirection && pClass
    "poster":
      tMemName = pDirection && pClass && pType
    "photo":
      tMemName = pDirection && pClass
    otherwise:
      return error(me, "Unknown item class:" && pClass, #solveMembers)
  end case
  if pXFactor = 32 then
    tMemName = "s_" & tMemName
  end if
  tMemNum = getmemnum(tMemName)
  if tMemNum <> 0 then
    if pSprList.count = 0 then
      tSpr = sprite(reserveSprite(me.getID()))
      tTargetID = getThread(#room).getInterface().getID()
      setEventBroker(tSpr.spriteNum, me.getID())
      if tMemNum < 1 then
        tMemNum = abs(tMemNum)
        tSpr.flipH = 1
      else
        tSpr.flipH = 0
      end if
      tSpr.castNum = tMemNum
      tSpr.width = member(tMemNum).width
      tSpr.height = member(tMemNum).height
      tSpr.registerProcedure(#eventProcItemObj, tTargetID, #mouseDown)
      tSpr.registerProcedure(#eventProcItemRollOver, tTargetID, #mouseEnter)
      tSpr.registerProcedure(#eventProcItemRollOver, tTargetID, #mouseLeave)
      pSprList.add(tSpr)
    else
      tSpr = pSprList[1]
    end if
    me.updateColor(pType)
    return 1
  end if
  return 0
end

on updateColor me, tHexstr
  if not listp(pSprList) then
    return 0
  end if
  if pSprList.count < 1 then
    return 0
  end if
  tSpr = pSprList[1]
  tSpr.ink = 8
  if pClass = "post.it" then
    if tHexstr = EMPTY then
      tHexstr = "#FFFF33"
    end if
    tSpr.bgColor = rgb(tHexstr)
    tSpr.color = paletteIndex(255)
  else
    if pClass = "post.it.vd" then
      tHexstr = "FFFFFF"
      tSpr.bgColor = rgb(tHexstr)
      tSpr.color = rgb(0, 0, 0)
    end if
  end if
end

on updatePosition me, pWallLocString, pLocalLocString, tDirChar
  pLocX = 0
  pLocY = 0
  pLocH = 0
  pLocZ = 0
  pWallX = 0
  pWallY = 0
  pLocalX = 0
  pLocalY = 0
  tDelim = the itemDelimiter
  tWallLoc = pWallLocString.word[1].char[4..length(pWallLocString.word[1])]
  the itemDelimiter = ","
  pWallX = integer(tWallLoc.item[1])
  pWallY = integer(tWallLoc.item[2])
  tLocalLoc = pLocalLocString.word[1].char[3..length(pLocalLocString.word[1])]
  pLocalX = integer(tLocalLoc.item[1])
  pLocalY = integer(tLocalLoc.item[2])
  case tDirChar of
    "r":
      pDirection = "rightwall"
    "l":
      pDirection = "leftwall"
  end case
  the itemDelimiter = tDelim
  me.updateLocation()
end

on updateLocation me
  case pFormatVer of
    #old:
      tGeometry = getThread(#room).getInterface().getGeometry()
      tScreenLocs = tGeometry.getScreenCoordinate(pLocX, pLocY, pLocH * 18.0 / 32.0)
      repeat with tSpr in pSprList
        tSpr.locH = tScreenLocs[1]
        tSpr.locV = tScreenLocs[2]
      end repeat
    #new:
      tWallObjs = getThread(#room).getComponent().getPassiveObject(#list)
      tWallObjFound = 0
      if tWallObjs.count > 0 then
        repeat with tWallObj in tWallObjs
          if (tWallObj.getLocation()[1] = pWallX) and (tWallObj.getLocation()[2] = pWallY) then
            tWallSprites = tWallObj.getSprites()
            repeat with tSpr in pSprList
              tSpr.locH = tWallSprites[1].locH - tWallSprites[1].member.regPoint[1] + pLocalX
              tSpr.locV = tWallSprites[1].locV - tWallSprites[1].member.regPoint[2] + pLocalY
            end repeat
            tWallObjFound = 1
            exit repeat
          end if
        end repeat
      end if
      if not tWallObjFound then
        tVisualizer = getThread(#room).getInterface().getRoomVisualizer()
        if not voidp(tVisualizer) then
          case pDirection of
            "leftwall":
              tPartTypes = [#wallleft]
            "rightwall":
              tPartTypes = [#wallright]
          end case
          tLounge = tVisualizer.getProperty(#layout)
          if (tLounge = "model_a.room") and (pWallY = 1) and (pClass contains "post.it") and (pWallX > 0) and (pDirection = #right) then
            pWallY = 0
          end if
          tPartProps = tVisualizer.getPartAtLocation(pWallX, pWallY, tPartTypes)
          if ilk(tPartProps) = #propList then
            tWallObjFound = 1
            repeat with tSpr in pSprList
              tMem = member(getmemnum(tPartProps.member))
              tFixNegativeLoc = 0
              if tLounge = "model_b.room" then
                if (pWallX = 4) and (pWallY = 4) and (pLocalX < 0) then
                  tFixNegativeLoc = 1
                end if
              else
                if tLounge = "model_f.room" then
                  if (pWallX = 2) and (pWallY = 6) and (pLocalX < 0) then
                    tFixNegativeLoc = 1
                  end if
                  if (pWallX = 6) and (pWallY = 2) and (pLocalX < 0) then
                    tFixNegativeLoc = 1
                  end if
                else
                  if tLounge = "model_g.room" then
                    if (pWallX = 6) and (pWallY = 4) and (pLocalX < 0) then
                      tFixNegativeLoc = 1
                    end if
                  else
                    if tLounge = "model_h.room" then
                      if (pWallX = 4) and (pWallY = 8) and (pLocalX < 0) then
                        tFixNegativeLoc = 1
                      end if
                    end if
                  end if
                end if
              end if
              if tFixNegativeLoc then
                pLocalX = 32 + pLocalX
              end if
              tSpr.locH = tPartProps.locH - tMem.regPoint[1] + pLocalX
              tSpr.locV = tPartProps.locV - tMem.regPoint[2] + pLocalY
            end repeat
            pParentWallLocZ = tPartProps[#locZ]
          end if
        end if
      end if
      if not (pClass contains "post.it") then
        if not tWallObjFound and getObject(#session).get(#room_owner) then
          tComponent = getThread(#room).getComponent()
          if not (tComponent = 0) then
            tComponent.getRoomConnection().send("ADDSTRIPITEM", "new item" && me.getID())
          end if
        end if
      end if
  end case
  tObjMover = getThread(#room).getInterface().getObjectMover()
  if not voidp(pParentWallLocZ) then
    repeat with i = 1 to pSprList.count
      pSprList[i].locZ = pParentWallLocZ + 20000 + i
    end repeat
  else
    repeat with tSpr in pSprList
      tItemRp = tSpr.member.regPoint
      tItemR = rect(tSpr.locH, tSpr.locV, tSpr.locH, tSpr.locV) + rect(-tItemRp[1], -tItemRp[2], tSpr.member.width - tItemRp[1], tSpr.member.height - tItemRp[2])
      tPieceUnderSpr = tObjMover.getPassiveObjectIntersectingRect(tItemR)[1]
      if objectp(tPieceUnderSpr) then
        tlocz = tPieceUnderSpr.getSprites()[1].locZ
        if tPieceUnderSpr.getSprites().count > 1 then
          if tPieceUnderSpr.getSprites()[2].locZ > tPieceUnderSpr.getSprites()[1].locZ then
            tlocz = tPieceUnderSpr.getSprites()[2].locZ
          end if
        end if
        tSpr.locZ = tlocz + 2
        next repeat
      end if
      tSpr.locZ = getIntVariable("window.default.locz") - 10000
    end repeat
  end if
end
