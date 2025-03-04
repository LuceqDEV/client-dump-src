on construct me
  return me.regMsgList(1)
end

on deconstruct me
  return me.regMsgList(0)
end

on handle_opc_ok me, tMsg
  if me.getComponent().getRoomID() = "private" then
    me.getComponent().roomConnected(VOID, "OPC_OK")
  end if
end

on handle_clc me
  me.getComponent().roomDisconnected()
end

on handle_youaremod me, tMsg
  return 1
end

on handle_flat_letin me, tMsg
  tConn = tMsg.connection
  tName = tConn.GetStrFrom()
  me.getInterface().showDoorBellAccepted(tName)
  if tName <> EMPTY then
    return 1
  end if
  return me.getComponent().roomConnected(VOID, "FLAT_LETIN")
end

on handle_room_ready me, tMsg
  me.getComponent().roomConnected(tMsg.content.word[1], "ROOM_READY")
end

on handle_logout me, tMsg
  tuser = tMsg.content.word[1]
  if tuser <> getObject(#session).get("user_index") then
    me.getComponent().removeUserObject(tuser)
  end if
end

on handle_disconnect me
  me.getComponent().roomDisconnected()
end

on handle_error me, tMsg
  tErr = tMsg.content
  error(me, tMsg.connection.getID() & ":" && tErr, #handle_error)
  case tErr of
    "Incorrect flat password":
      if threadExists(#navigator) then
        getThread(#navigator).getComponent().flatAccessResult(tErr)
      end if
    "Password required":
      if threadExists(#navigator) then
        getThread(#navigator).getComponent().flatAccessResult(tErr)
      end if
    "weird error":
      executeMessage(#leaveRoom)
    "Not owner":
      getObject(#session).set("room_controller", 0)
      me.getInterface().hideInterface(#hide)
  end case
end

on handle_doorbell_ringing me, tMsg
  if tMsg.content = EMPTY then
    return me.getInterface().showDoorBellWaiting()
  else
    return me.getInterface().showDoorBellDialog(tMsg.connection.GetStrFrom())
  end if
end

on handle_flatnotallowedtoenter me, tMsg
  tConn = tMsg.connection.GetStrFrom()
  tName = tConn.GetStrFrom()
  return me.getInterface().showDoorBellRejected(tName)
end

on handle_status me, tMsg
  tList = []
  tDelim = the itemDelimiter
  the itemDelimiter = "/"
  tTotalStatusUpdates = tMsg.connection.GetIntFrom()
  repeat with i = 1 to tTotalStatusUpdates
    tuser = [:]
    tuser[#id] = tMsg.connection.GetIntFrom()
    tuser[#x] = tMsg.connection.GetIntFrom()
    tuser[#y] = tMsg.connection.GetIntFrom()
    tuser[#h] = getLocalFloat(tMsg.connection.GetStrFrom())
    tuser[#dirHead] = tMsg.connection.GetIntFrom() mod 8
    tuser[#dirBody] = tMsg.connection.GetIntFrom() mod 8
    tActionString = tMsg.connection.GetStrFrom()
    tActions = []
    the itemDelimiter = "/"
    repeat with j = 1 to tActionString.item.count
      if length(tActionString.item[j]) > 1 then
        tActionName = tActionString.item[j].word[1]
        tActions.add([#name: tActionName, #params: tActionString.item[j]])
      end if
    end repeat
    tuser[#actions] = tActions
    tList.add(tuser)
  end repeat
  the itemDelimiter = tDelim
  repeat with tuser in tList
    tUserObj = me.getComponent().getUserObject(tuser[#id])
    if tUserObj <> 0 then
      tUserObj.resetValues(tuser[#x], tuser[#y], tuser[#h], tuser[#dirHead], tuser[#dirBody])
      repeat with tAction in tuser[#actions]
        call(symbol("action_" & tAction[#name]), [tUserObj], tAction[#params])
      end repeat
      tUserObj.Refresh(tuser[#x], tuser[#y], tuser[#h])
    end if
  end repeat
end

on handle_chat me, tMsg
  tConn = tMsg.getaProp(#connection)
  tuser = string(tConn.GetIntFrom())
  tChat = tConn.GetStrFrom()
  if me.getInterface().getIgnoreStatus(tuser) then
    return 0
  end if
  case tMsg.getaProp(#subject) of
    24:
      tMode = "CHAT"
    25:
      tMode = "WHISPER"
    26:
      tMode = "SHOUT"
  end case
  if me.getComponent().userObjectExists(tuser) then
    me.getComponent().getBalloon().createBalloon([#command: tMode, #id: tuser, #message: tChat])
    tUserObject = me.getComponent().getUserObject(tuser)
    if not voidp(tUserObject) then
      me.recordChatForReporting(tUserObject.getInfo().getaProp(#name), tChat)
    end if
  end if
end

on recordChatForReporting me, tUserName, tChat
  tReportableUsers = getObject("session").get("reportable_users")
  tRoomID = me.getComponent().pReportRoomId
  repeat with i = 1 to count(tReportableUsers)
    if tReportableUsers[i][#name] = tUserName then
      tChatRecord = [#chatLine: tChat, #roomId: tRoomID]
      if count(tReportableUsers[i][#chatLines]) >= 25 then
        tReportableUsers[i][#chatLines].deleteAt(1)
      end if
      tReportableUsers[i][#chatLines].append(tChatRecord)
      getObject("session").set("reportable_users", tReportableUsers)
      exit
    end if
  end repeat
end

on handle_users me, tMsg
  tDelim = the itemDelimiter
  if not objectExists("Figure_System") then
    return error(me, "Figure system object not found!", #handle_users)
  end if
  tSessionUsername = getObject(#session).get(#userName)
  tReportableUsers = getObject(#session).get("reportable_users")
  tList = []
  tuser = EMPTY
  tTotalUsers = tMsg.connection.GetIntFrom()
  repeat with i = 1 to tTotalUsers
    tRoomIndex = tMsg.connection.GetIntFrom()
    tuser = string(tRoomIndex)
    tListItem = [:]
    tListItem[#id] = tuser
    tListItem[#direction] = [0, 0]
    tUserName = tMsg.connection.GetStrFrom()
    tListItem[#name] = tUserName
    tListItem[#figure] = tMsg.connection.GetStrFrom()
    tGender = tMsg.connection.GetStrFrom()
    if (tGender = "F") or (tGender = "f") then
      tListItem[#sex] = "F"
    else
      tListItem[#sex] = "M"
    end if
    tListItem[#custom] = tMsg.connection.GetStrFrom()
    tListItem[#x] = tMsg.connection.GetIntFrom()
    tListItem[#y] = tMsg.connection.GetIntFrom()
    tListItem[#h] = getLocalFloat(tMsg.connection.GetStrFrom())
    tPoolFigure = tMsg.connection.GetStrFrom()
    if tPoolFigure <> EMPTY then
      the itemDelimiter = "/"
      tmodel = tPoolFigure.char[1..3]
      tColor = tPoolFigure.item[2]
      the itemDelimiter = ","
      tisColorValid = 0
      if tColor.item.count = 3 then
        tColor = color(#rgb, integer(tColor.item[1]), integer(tColor.item[2]), integer(tColor.item[3]))
      else
        tColor = rgb("#EEEEEE")
      end if
      tListItem[#phfigure] = ["model": tmodel, "color": tColor]
      tListItem[#class] = "pelle"
    end if
    tBadgeCode = tMsg.connection.GetStrFrom()
    if tBadgeCode <> EMPTY then
      tListItem[#badge] = tBadgeCode
    end if
    tUserType = tMsg.connection.GetIntFrom()
    if tListItem[#class] <> "pelle" then
      if tUserType = 1 then
        tListItem[#class] = "user"
      else
        if tUserType = 2 then
          tListItem[#class] = "pet"
        else
          if (tUserType = 3) or (tUserType = 4) then
            tListItem[#class] = "bot"
          end if
        end if
      end if
    end if
    if (tListItem[#class] = "user") or (tListItem[#class] = "pelle") then
      if (tSessionUsername <> tUserName) and not me.isUserReported(tReportableUsers, tUserName) then
        if count(tReportableUsers) >= 150 then
          tReportableUsers.deleteAt(1)
        end if
        tReportableUsers.append([#name: tUserName, #chatLines: []])
      end if
    end if
    tList.add(tListItem)
  end repeat
  getObject(#session).set("reportable_users", tReportableUsers)
  tFigureParser = getObject("Figure_System")
  repeat with tObject in tList
    tObject[#figure] = tFigureParser.parseFigure(tObject[#figure], tObject[#sex], tObject[#class])
  end repeat
  the itemDelimiter = tDelim
  if count(tList) = 0 then
    me.getComponent().validateUserObjects(0)
  else
    tName = getObject(#session).get(#userName)
    repeat with tuser in tList
      me.getComponent().validateUserObjects(tuser)
      if me.getComponent().getPickedCryName() = tuser[#name] then
        me.getComponent().showCfhSenderDelayed(tuser[#id])
      end if
      if tuser[#name] = tName then
        getObject(#session).set("user_index", tuser[#id])
        me.getInterface().eventProcUserObj(#selection, tuser[#id], #userEnters)
      end if
    end repeat
  end if
end

on isUserReported me, tUserList, tUserName
  repeat with tUserObject in tUserList
    if tUserObject[#name] = tUserName then
      return 1
    end if
  end repeat
  return 0
end

on handle_showprogram me, tMsg
  tLine = tMsg.content
  tDst = tLine.word[1]
  tCmd = tLine.word[2]
  tArg = tLine.word[3..tLine.word.count]
  tdata = [#command: "SHOWPROGRAM", #show_dest: tDst, #show_command: tCmd, #show_params: tArg]
  tObj = me.getComponent().getRoomPrg()
  if objectp(tObj) then
    call(#showprogram, [tObj], tdata)
  end if
end

on handle_heightmap me, tMsg
  me.getComponent().validateHeightMap(tMsg.content)
end

on handle_heightmapupdate me, tMsg
  me.getComponent().updateHeightMap(tMsg.content)
end

on handle_OBJECTS me, tMsg
  tList = []
  tCount = tMsg.content.line.count
  repeat with i = 1 to tCount
    tLine = tMsg.content.line[i]
    if length(tLine) > 5 then
      tObj = [:]
      tObj[#id] = tLine.word[1]
      tObj[#class] = tLine.word[2]
      tObj[#x] = integer(tLine.word[3])
      tObj[#y] = integer(tLine.word[4])
      tObj[#h] = integer(tLine.word[5])
      if tLine.word.count = 6 then
        tdir = integer(tLine.word[6]) mod 8
        tObj[#direction] = [tdir, tdir, tdir]
        tObj[#dimensions] = 0
      else
        tWidth = integer(tLine.word[6])
        tHeight = integer(tLine.word[7])
        tObj[#dimensions] = [tWidth, tHeight]
        tObj[#x] = tObj[#x] + tObj[#width] - 1
        tObj[#y] = tObj[#y] + tObj[#height] - 1
      end if
      if tObj[#id] <> EMPTY then
        tList.add(tObj)
      end if
    end if
  end repeat
  if count(tList) > 0 then
    repeat with tObj in tList
      me.getComponent().validatePassiveObjects(tObj)
    end repeat
  else
    me.getComponent().validatePassiveObjects(0)
  end if
end

on parseActiveObject me, tConn
  if not tConn then
    return 0
  end if
  tObj = [:]
  tObj[#id] = tConn.GetStrFrom()
  tObj[#class] = tConn.GetStrFrom()
  tObj[#x] = tConn.GetIntFrom()
  tObj[#y] = tConn.GetIntFrom()
  tWidth = tConn.GetIntFrom()
  tHeight = tConn.GetIntFrom()
  tDirection = tConn.GetIntFrom() mod 8
  tObj[#direction] = [tDirection, tDirection, tDirection]
  tObj[#dimensions] = [tWidth, tHeight]
  tObj[#altitude] = getLocalFloat(tConn.GetStrFrom())
  tObj[#colors] = tConn.GetStrFrom()
  if tObj[#colors] = EMPTY then
    tObj[#colors] = "0"
  end if
  tRuntimeData = tConn.GetStrFrom()
  tExtra = tConn.GetIntFrom()
  tStuffData = tConn.GetStrFrom()
  tObj[#props] = [#runtimedata: tRuntimeData, #extra: tExtra, #stuffdata: tStuffData]
  return tObj
end

on handle_activeobjects me, tMsg
  tConn = tMsg.connection
  if not tConn then
    return 0
  end if
  tList = []
  tCount = tConn.GetIntFrom()
  repeat with i = 1 to tCount
    if tConn <> 0 then
      tObj = me.parseActiveObject(tConn)
      if listp(tObj) then
        tList.add(tObj)
      end if
    end if
  end repeat
  if count(tList) > 0 then
    repeat with tObj in tList
      me.getComponent().validateActiveObjects(tObj)
    end repeat
    executeMessage(#activeObjectsUpdated)
  else
    me.getComponent().validateActiveObjects(0)
  end if
end

on handle_activeobject_remove me, tMsg
  me.getComponent().removeActiveObject(tMsg.content.word[1])
  executeMessage(#activeObjectRemoved)
  return 1
end

on handle_activeobject_add me, tMsg
  tConn = tMsg.connection
  if not tConn then
    return 0
  end if
  tObj = me.parseActiveObject(tConn)
  if not listp(tObj) then
    return 0
  end if
  me.getComponent().validateActiveObjects(tObj)
  executeMessage(#activeObjectsUpdated)
  return 1
end

on handle_activeobject_update me, tMsg
  tConn = tMsg.connection
  if not tConn then
    return 0
  end if
  tObj = me.parseActiveObject(tConn)
  if not listp(tObj) then
    return 0
  end if
  tComponent = me.getComponent()
  if tComponent.activeObjectExists(tObj[#id]) then
    tActiveObj = tComponent.getActiveObject(tObj[#id])
    tActiveObj.define(tObj)
    tComponent.removeSlideObject(tObj[#id])
    call(#prepareForMove, [tActiveObj])
    executeMessage(#activeObjectsUpdated)
  else
    return error(me, "Active object not found:" && tObj[#id], #handle_activeobject_update)
  end if
end

on handle_items me, tMsg
  tList = []
  tDelim = the itemDelimiter
  repeat with i = 1 to tMsg.content.line.count
    the itemDelimiter = TAB
    tLine = tMsg.content.line[i]
    if tLine <> EMPTY then
      tObj = [:]
      tObj[#id] = string(integer(tLine.item[1]))
      tObj[#class] = tLine.item[2]
      tObj[#owner] = tLine.item[3]
      tObj[#type] = tLine.item[5]
      if not (tLine.item[4].char[1] = ":") then
        tObj[#direction] = tLine.item[4].word[1]
        if tObj[#direction] = "frontwall" then
          tObj[#direction] = "rightwall"
        end if
        tlocation = tLine.item[4].word[2..tLine.item[4].word.count]
        the itemDelimiter = ","
        tObj[#x] = 0
        tObj[#y] = tlocation.item[1]
        tObj[#h] = getLocalFloat(tlocation.item[2])
        tObj[#z] = integer(tlocation.item[3])
        tObj[#formatVersion] = #old
      else
        tLocString = tLine.item[4]
        tWallLoc = tLocString.word[1].char[4..length(tLocString.word[1])]
        the itemDelimiter = ","
        tObj[#wall_x] = integer(tWallLoc.item[1])
        tObj[#wall_y] = integer(tWallLoc.item[2])
        tLocalLoc = tLocString.word[2].char[3..length(tLocString.word[2])]
        tObj[#local_x] = integer(tLocalLoc.item[1])
        tObj[#local_y] = integer(tLocalLoc.item[2])
        tDirChar = tLocString.word[3]
        case tDirChar of
          "r":
            tObj[#direction] = "rightwall"
          "l":
            tObj[#direction] = "leftwall"
        end case
        tObj[#formatVersion] = #new
      end if
      tList.add(tObj)
    end if
  end repeat
  the itemDelimiter = tDelim
  if count(tList) > 0 then
    repeat with tItem in tList
      me.getComponent().validateItemObjects(tItem)
    end repeat
    executeMessage(#itemObjectsUpdated)
  else
    me.getComponent().validateItemObjects(0)
  end if
end

on handle_removeitem me, tMsg
  me.getComponent().removeItemObject(tMsg.content)
  executeMessage(#itemObjectRemoved)
  me.getInterface().stopObjectMover()
end

on handle_updateitem me, tMsg
  tItem = me.getComponent().getItemObject(tMsg.content.word[1])
  if objectp(tItem) then
    if tItem.getClass() = "post.it" then
      tItem.updateColor(the last word in the content of tMsg)
      return 1
    else
      if tItem.getClass() = "post.it" then
        return 1
      else
        tItem.updatePosition(tMsg.content.word[4], tMsg.content.word[5], tMsg.content.word[6])
        executeMessage(#itemObjectsUpdated)
      end if
    end if
  end if
end

on handle_stuffdataupdate me, tMsg
  tConn = tMsg.connection
  if not tConn then
    return 0
  end if
  tTarget = tConn.GetStrFrom()
  tValue = tConn.GetStrFrom()
  if me.getComponent().activeObjectExists(tTarget) then
    call(#updateStuffdata, [me.getComponent().getActiveObject(tTarget)], tValue)
  else
    return error(me, "Active object not found:" && tTarget, #handle_stuffdataupdate)
  end if
end

on handle_presentopen me, tMsg
  ttype = tMsg.content.line[1]
  tCode = tMsg.content.line[2]
  tCard = "PackageCardObj"
  if objectExists(tCard) then
    getObject(tCard).showContent([#type: ttype, #code: tCode])
  else
    error(me, "Package card obj not found!", #handle_presentopen)
  end if
end

on handle_flatproperty me, tMsg
  tDelim = the itemDelimiter
  the itemDelimiter = "/"
  tLine = tMsg.content
  tdata = [#key: tLine.item[1], #value: tLine.item[2]]
  the itemDelimiter = tDelim
  tRoomPrg = me.getComponent().getRoomPrg()
  if tRoomPrg <> 0 then
    tRoomPrg.setProperty(tdata[#key], tdata[#value])
  else
    error(me, "Private room program not found!", #handle_flatproperty)
  end if
end

on handle_room_rights me, tMsg
  case tMsg.subject of
    42:
      getObject(#session).set("room_controller", 1)
    43:
      getObject(#session).set("room_controller", 0)
    47:
      getObject(#session).set("room_owner", 1)
  end case
end

on handle_stripinfo me, tMsg
  tConn = tMsg.connection
  if tMsg.subject = 98 then
    tCount = 1
  else
    tCount = tConn.GetIntFrom()
  end if
  tStripMax = 0
  tTotalItemCount = 0
  tProps = [#objects: [], #count: tCount]
  repeat with i = 1 to tCount
    tObj = me.parse_stripinfoitem(tConn)
    tObjectPos = tObj[#objectPos]
    tObj.deleteProp(#objectPos)
    tProps[#objects].add(tObj)
    if tObjectPos > tStripMax then
      tStripMax = tObjectPos
    end if
  end repeat
  tTotalItemCount = tConn.GetIntFrom()
  tInventory = me.getInterface().getContainer()
  tInventory.setHandButton("next", tTotalItemCount > integer(tStripMax))
  tInventory.setHandButton("prev", integer(tStripMax) > 8)
  case tMsg.subject of
    140:
      tInventory.updateStripItems(tProps[#objects])
      tInventory.setStripItemCount(tProps[#count])
      tInventory.open(1)
      tInventory.Refresh()
    98:
      tInventory.appendStripItem(tProps[#objects][1])
      tInventory.open(1)
      tInventory.Refresh()
    108:
      return tProps
  end case
end

on parse_stripinfoitem me, tConn
  tObj = [:]
  tObj[#stripId] = string(tConn.GetIntFrom())
  tObj[#objectPos] = tConn.GetIntFrom()
  tObj[#striptype] = tConn.GetStrFrom()
  tObj[#id] = string(tConn.GetIntFrom())
  tObj[#class] = tConn.GetStrFrom()
  case tObj[#striptype] of
    "S":
      tObj[#name] = getText("furni_" & tObj[#class] & "_name", "furni_" & tObj[#class] & "_name")
      tObj[#striptype] = "active"
      tObj[#custom] = getText("furni_" & tObj[#class] & "_name", "furni_" & tObj[#class] & "_desc")
      tObj[#dimensions] = [integer(tConn.GetIntFrom()), integer(tConn.GetIntFrom())]
      tObj[#colors] = tConn.GetStrFrom()
      the itemDelimiter = ","
      if tObj[#colors].char[1] = "#" then
        if tObj[#colors].item.count > 1 then
          tObj[#stripColor] = rgb(tObj[#colors].item[tObj[#colors].item.count])
        else
          tObj[#stripColor] = rgb(tObj[#colors])
        end if
      else
        tObj[#stripColor] = 0
      end if
    "I":
      tObj[#striptype] = "item"
      tObj[#props] = tConn.GetStrFrom()
      case tObj[#class] of
        "poster":
          tObj[#name] = getText("poster_" & tObj[#props] & "_name", "poster_" & tObj[#props] & "_name")
        otherwise:
          tObj[#name] = getText("wallitem_" & tObj[#class] & "_name", "wallitem_" & tObj[#class] & "_name")
      end case
  end case
  return tObj
end

on handle_stripupdated me, tMsg
  tMsg.connection.send("GETSTRIP", "new")
end

on handle_removestripitem me, tMsg
  me.getInterface().getContainer().removeStripItem(tMsg.content.word[1])
end

on handle_youarenotallowed me
  executeMessage(#alert, [#Msg: "trade_youarenotallowed", #id: "youarenotallowed"])
end

on handle_othernotallowed me
  executeMessage(#alert, [#Msg: "trade_othernotallowed", #id: "othernotallowed"])
end

on handle_idata me, tMsg
  tConn = tMsg.connection
  if not tConn then
    return 0
  end if
  tDelim = the itemDelimiter
  the itemDelimiter = TAB
  tid = integer(tConn.GetStrFrom())
  tdata = tConn.GetStrFrom()
  ttype = tdata.line[1].item[1]
  tText = ttype & RETURN & tdata.line[2..tdata.line.count]
  the itemDelimiter = tDelim
  executeMessage(symbol("itemdata_received" & tid), [#id: tid, #text: tText, #type: ttype])
end

on handle_trade_items me, tMsg
  tMessage = [:]
  tConn = tMsg.connection
  repeat with i = 1 to 2
    tdata = [:]
    tUserName = tConn.GetStrFrom()
    if tUserName = EMPTY then
      return error(me, "No username from server", #handle_trade_items)
    end if
    if me.getInterface().getIgnoreStatus(VOID, tUserName) then
      return me.getComponent().getRoomConnection().send("TRADE_CLOSE")
    end if
    tdata[#accept] = tConn.GetIntFrom() = 1
    tProps = [#objects: []]
    tCount = tConn.GetIntFrom()
    repeat with j = 1 to tCount
      tObj = me.parse_stripinfoitem(tConn)
      tProps[#objects].add(tObj)
    end repeat
    tdata[#items] = tProps.getaProp(#objects)
    if not listp(tdata[#items]) then
      return error(me, "Invalid itemdata from server!", #handle_trade_items)
    end if
    tMessage[tUserName] = tdata
  end repeat
  return me.getInterface().getSafeTrader().Refresh(tMessage)
end

on handle_trade_close me, tMsg
  me.getInterface().getSafeTrader().close()
  tMsg.connection.send("GETSTRIP", "new")
end

on handle_trade_accept me, tMsg
  tDelim = the itemDelimiter
  the itemDelimiter = "/"
  tuser = tMsg.content.item[1]
  tValue = tMsg.content.item[2] = "true"
  the itemDelimiter = tDelim
  me.getInterface().getSafeTrader().accept(tuser, tValue)
end

on handle_trade_completed me, tMsg
  me.getInterface().getSafeTrader().complete()
end

on handle_door_in me, tMsg
  tDelim = the itemDelimiter
  the itemDelimiter = "/"
  tDoor = tMsg.content.item[1]
  tuser = tMsg.content.item[2]
  the itemDelimiter = tDelim
  tDoorObj = me.getComponent().getActiveObject(tDoor)
  if tDoorObj <> 0 then
    tDoorObj.animate(18)
    if getObject(#session).get("user_name") = tuser then
      tDoorObj.prepareToKick(tuser)
    end if
  end if
end

on handle_door_out me, tMsg
  tDelim = the itemDelimiter
  tDoor = me.getComponent().getActiveObject(tMsg.content.item[1])
  the itemDelimiter = "/"
  if tDoor <> 0 then
    return tDoor.animate()
  end if
end

on handle_doorflat me, tMsg
  tConn = tMsg.connection
  tTeleId = tConn.GetIntFrom()
  tFlatID = tConn.GetIntFrom()
  if not (tTeleId and tFlatID) then
    return error(me, "Retarded doorflat data!", #handle_doorflat)
  end if
  me.getComponent().startTeleport(tTeleId, tFlatID)
end

on handle_doordeleted me, tMsg
  if getObject(#session).exists("current_door_ID") then
    tDoorID = getObject(#session).get("current_door_ID")
    tDoorObj = me.getComponent().getActiveObject(tDoorID)
    if tDoorObj <> 0 then
      tDoorObj.kickOut()
    end if
  end if
end

on handle_dice_value me, tMsg
  tid = tMsg.content.word[1]
  if tMsg.content.word.count = 1 then
    tValue = -1
  else
    tValue = integer(tMsg.content.word[2] - (tid * 38))
    if tValue > 6 then
      tValue = 0
    end if
  end if
  if me.getComponent().activeObjectExists(tid) then
    me.getComponent().getActiveObject(tid).diceThrown(tValue)
  end if
end

on handle_roomad me, tMsg
  if tMsg.content.length > 1 then
    tDelim = the itemDelimiter
    the itemDelimiter = TAB
    tSourceURL = tMsg.content.item[1]
    tTargetURL = tMsg.content.item[2]
    the itemDelimiter = tDelim
    tLayoutID = me.getInterface().getRoomVisualizer().pLayout
    me.getComponent().getAd().Init(tSourceURL, tTargetURL, tLayoutID)
  else
    me.getComponent().getAd().Init(0)
  end if
end

on handle_petstat me, tMsg
  tPetObj = me.getComponent().getUserObject(tMsg.connection.GetIntFrom())
  if tPetObj = 0 then
    return error(me, "Pet object not found!", #handle_petstat)
  end if
  tName = tPetObj.getName()
  tAge = tMsg.connection.GetIntFrom()
  tHungry = getText("pet_hung_" & tMsg.connection.GetIntFrom(), "???")
  tThirsty = getText("pet_thir_" & tMsg.connection.GetIntFrom(), "???")
  tHappiness = getText("pet_mood_" & tMsg.connection.GetIntFrom(), "???")
  tNature01 = getText("pet_enrg_" & tMsg.connection.GetIntFrom(), "???")
  tNature02 = getText("pet_frnd_" & tMsg.connection.GetIntFrom(), "???")
  if createWindow("pet_status_dialog") then
    tWndObj = getWindow("pet_status_dialog")
    tWndObj.moveTo(8, 8)
    tWndObj.setProperty(#title, tName)
    if not tWndObj.merge("habbo_full.window") then
      return tWndObj.close()
    end if
    if not tWndObj.merge("petstatus.window") then
      return tWndObj.close()
    end if
    tWndObj.getElement("age").setText(tAge)
    tWndObj.getElement("hungry").setText(tHungry)
    tWndObj.getElement("thirsty").setText(tThirsty)
    tWndObj.getElement("happiness").setText(tHappiness)
    tWndObj.getElement("nature").setText(tNature01 & "," && tNature02)
    tWndObj.getElement("picture").feedImage(tPetObj.getPicture())
    registerMessage(#leaveRoom, tWndObj.getID(), #close)
    registerMessage(#changeRoom, tWndObj.getID(), #close)
  end if
end

on handle_userbadge me, tMsg
  if voidp(tMsg.connection) then
    return 0
  end if
  tUserID = string(tMsg.connection.GetIntFrom())
  tBadge = tMsg.connection.GetStrFrom()
  tUserObj = me.getComponent().getUserObject(tUserID)
  if not objectp(tUserObj) then
    return 0
  end if
  tUserObj.pBadge = tBadge
  me.getInterface().unignoreAdmin(tUserID, tBadge)
  me.getInterface().updateInfoStandBadge(tBadge, tUserID)
end

on handle_slideobjectbundle me, tMsg
  tConn = tMsg.getaProp(#connection)
  tComponent = me.getComponent()
  tTimeNow = the milliSeconds
  tObjList = []
  tContainsObjects = 0
  tFromX = tConn.GetIntFrom()
  tFromY = tConn.GetIntFrom()
  tToX = tConn.GetIntFrom()
  tToY = tConn.GetIntFrom()
  tStuffCount = tConn.GetIntFrom()
  repeat with tCount = 1 to tStuffCount
    tObj = []
    tItemID = tConn.GetIntFrom()
    tItemFromH = getLocalFloat(tConn.GetStrFrom())
    tItemToH = getLocalFloat(tConn.GetStrFrom())
    tFrom = [tFromX, tFromY, tItemFromH]
    tTo = [tToX, tToY, tItemToH]
    tObj = [tItemID, tFrom, tTo]
    tObjList.add(tObj)
    tContainsObjects = 1
  end repeat
  tTileID = tConn.GetIntFrom()
  tTileObj = tComponent.getActiveObject(tTileID)
  if tTileObj <> 0 then
    call(#setAnimation, tTileObj, 1)
  end if
  tMoveType = tConn.GetIntFrom()
  case tMoveType of
    0:
      tHasCharacter = 0
    1:
      tMoveType = "mv"
      tHasCharacter = 1
    2:
      tMoveType = "sld"
      tHasCharacter = 1
    otherwise:
      return error(me, "Incompatible character movetype", #handle_slideobjectbundle)
  end case
  if tHasCharacter then
    tCharID = tConn.GetIntFrom()
    tFromH = getLocalFloat(tConn.GetStrFrom())
    tToH = getLocalFloat(tConn.GetStrFrom())
    tUserObj = me.getComponent().getUserObject(tCharID)
    if tUserObj <> 0 then
      tCommandStr = tMoveType && tToX & "," & tToY & "," & tToH && tContainsObjects.integer && tTimeNow
      call(symbol("action_" & tMoveType), [tUserObj], tCommandStr)
    end if
  end if
  repeat with tObj in tObjList
    tComponent.addSlideObject(tObj[1], tObj[2], tObj[3], tTimeNow, tHasCharacter)
  end repeat
end

on handle_interstitialdata me, tMsg
  if tMsg.content.length > 1 then
    tDelim = the itemDelimiter
    the itemDelimiter = TAB
    tSourceURL = tMsg.content.item[1]
    tTargetURL = tMsg.content.item[2]
    the itemDelimiter = tDelim
    me.getComponent().getInterstitial().Init(tSourceURL, tTargetURL)
  else
    me.getComponent().getInterstitial().Init(0)
  end if
end

on handle_roomqueuedata me, tMsg
  tConn = tMsg.getaProp(#connection)
  tQueueSet = tConn.GetStrFrom()
  tNumberOfQueues = tConn.GetIntFrom()
  tQueueData = [:]
  repeat with t = 1 to tNumberOfQueues
    tQueueID = tConn.GetStrFrom()
    tQueueLength = tConn.GetIntFrom()
    tQueueData[tQueueID] = tQueueLength
  end repeat
  me.getInterface().updateQueueWindow(tQueueSet, tQueueData)
end

on handle_youarespectator me
  return me.getComponent().setSpectatorMode(1)
end

on regMsgList me, tBool
  tMsgs = [:]
  tMsgs.setaProp(-1, #handle_disconnect)
  tMsgs.setaProp(18, #handle_clc)
  tMsgs.setaProp(19, #handle_opc_ok)
  tMsgs.setaProp(24, #handle_chat)
  tMsgs.setaProp(25, #handle_chat)
  tMsgs.setaProp(26, #handle_chat)
  tMsgs.setaProp(28, #handle_users)
  tMsgs.setaProp(29, #handle_logout)
  tMsgs.setaProp(30, #handle_OBJECTS)
  tMsgs.setaProp(31, #handle_heightmap)
  tMsgs.setaProp(32, #handle_activeobjects)
  tMsgs.setaProp(33, #handle_error)
  tMsgs.setaProp(34, #handle_status)
  tMsgs.setaProp(41, #handle_flat_letin)
  tMsgs.setaProp(45, #handle_items)
  tMsgs.setaProp(42, #handle_room_rights)
  tMsgs.setaProp(43, #handle_room_rights)
  tMsgs.setaProp(46, #handle_flatproperty)
  tMsgs.setaProp(47, #handle_room_rights)
  tMsgs.setaProp(48, #handle_idata)
  tMsgs.setaProp(62, #handle_doorflat)
  tMsgs.setaProp(63, #handle_doordeleted)
  tMsgs.setaProp(64, #handle_doordeleted)
  tMsgs.setaProp(69, #handle_room_ready)
  tMsgs.setaProp(70, #handle_youaremod)
  tMsgs.setaProp(71, #handle_showprogram)
  tMsgs.setaProp(83, #handle_items)
  tMsgs.setaProp(84, #handle_removeitem)
  tMsgs.setaProp(85, #handle_updateitem)
  tMsgs.setaProp(88, #handle_stuffdataupdate)
  tMsgs.setaProp(89, #handle_door_out)
  tMsgs.setaProp(90, #handle_dice_value)
  tMsgs.setaProp(91, #handle_doorbell_ringing)
  tMsgs.setaProp(92, #handle_door_in)
  tMsgs.setaProp(93, #handle_activeobject_add)
  tMsgs.setaProp(94, #handle_activeobject_remove)
  tMsgs.setaProp(95, #handle_activeobject_update)
  tMsgs.setaProp(98, #handle_stripinfo)
  tMsgs.setaProp(99, #handle_removestripitem)
  tMsgs.setaProp(101, #handle_stripupdated)
  tMsgs.setaProp(102, #handle_youarenotallowed)
  tMsgs.setaProp(103, #handle_othernotallowed)
  tMsgs.setaProp(105, #handle_trade_completed)
  tMsgs.setaProp(108, #handle_trade_items)
  tMsgs.setaProp(109, #handle_trade_accept)
  tMsgs.setaProp(110, #handle_trade_close)
  tMsgs.setaProp(112, #handle_trade_completed)
  tMsgs.setaProp(129, #handle_presentopen)
  tMsgs.setaProp(131, #handle_flatnotallowedtoenter)
  tMsgs.setaProp(140, #handle_stripinfo)
  tMsgs.setaProp(208, #handle_roomad)
  tMsgs.setaProp(210, #handle_petstat)
  tMsgs.setaProp(219, #handle_heightmapupdate)
  tMsgs.setaProp(228, #handle_userbadge)
  tMsgs.setaProp(230, #handle_slideobjectbundle)
  tMsgs.setaProp(258, #handle_interstitialdata)
  tMsgs.setaProp(259, #handle_roomqueuedata)
  tMsgs.setaProp(254, #handle_youarespectator)
  tCmds = [:]
  tCmds.setaProp(#room_directory, 2)
  tCmds.setaProp("GETDOORFLAT", 28)
  tCmds.setaProp("CHAT", 52)
  tCmds.setaProp("SHOUT", 55)
  tCmds.setaProp("WHISPER", 56)
  tCmds.setaProp("QUIT", 53)
  tCmds.setaProp("GOVIADOOR", 54)
  tCmds.setaProp("TRYFLAT", 57)
  tCmds.setaProp("GOTOFLAT", 59)
  tCmds.setaProp("G_HMAP", 60)
  tCmds.setaProp("G_USRS", 61)
  tCmds.setaProp("G_OBJS", 62)
  tCmds.setaProp("G_ITEMS", 63)
  tCmds.setaProp("G_STAT", 64)
  tCmds.setaProp("GETSTRIP", 65)
  tCmds.setaProp("FLATPROPBYITEM", 66)
  tCmds.setaProp("ADDSTRIPITEM", 67)
  tCmds.setaProp("TRADE_UNACCEPT", 68)
  tCmds.setaProp("TRADE_ACCEPT", 69)
  tCmds.setaProp("TRADE_CLOSE", 70)
  tCmds.setaProp("TRADE_OPEN", 71)
  tCmds.setaProp("TRADE_ADDITEM", 72)
  tCmds.setaProp("MOVESTUFF", 73)
  tCmds.setaProp("SETSTUFFDATA", 74)
  tCmds.setaProp("MOVE", 75)
  tCmds.setaProp("THROW_DICE", 76)
  tCmds.setaProp("DICE_OFF", 77)
  tCmds.setaProp("PRESENTOPEN", 78)
  tCmds.setaProp("LOOKTO", 79)
  tCmds.setaProp("CARRYDRINK", 80)
  tCmds.setaProp("INTODOOR", 81)
  tCmds.setaProp("DOORGOIN", 82)
  tCmds.setaProp("G_IDATA", 83)
  tCmds.setaProp("SETITEMDATA", 84)
  tCmds.setaProp("REMOVEITEM", 85)
  tCmds.setaProp("CARRYITEM", 87)
  tCmds.setaProp("STOP", 88)
  tCmds.setaProp("USEITEM", 89)
  tCmds.setaProp("PLACESTUFF", 90)
  tCmds.setaProp("MOVEITEM", 91)
  tCmds.setaProp("DANCE", 93)
  tCmds.setaProp("WAVE", 94)
  tCmds.setaProp("KICKUSER", 95)
  tCmds.setaProp("ASSIGNRIGHTS", 96)
  tCmds.setaProp("REMOVERIGHTS", 97)
  tCmds.setaProp("LETUSERIN", 98)
  tCmds.setaProp("REMOVESTUFF", 99)
  tCmds.setaProp("GOAWAY", 115)
  tCmds.setaProp("GETROOMAD", 126)
  tCmds.setaProp("GETPETSTAT", 128)
  tCmds.setaProp("SETBADGE", 158)
  tCmds.setaProp("GETINTERST", 182)
  tCmds.setaProp("ROOMBAN", 330)
  if tBool then
    registerListener(getVariable("connection.room.id"), me.getID(), tMsgs)
    registerCommands(getVariable("connection.room.id"), me.getID(), tCmds)
  else
    unregisterListener(getVariable("connection.room.id"), me.getID(), tMsgs)
    unregisterCommands(getVariable("connection.room.id"), me.getID(), tCmds)
  end if
  return 1
end
