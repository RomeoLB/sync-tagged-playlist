'28/08/24 - RLB - Plugin for sync tagged playlist playback
'SyncTaggedPlaylist - plugin name

Function SyncTaggedPlaylist_Initialize(msgPort As Object, userVariables As Object, bsp as Object)

   ' print "SyncTaggedPlaylist_Initialize - entry"
   ' print "type of msgPort is ";type(msgPort)
    'print "type of userVariables is ";type(userVariables)

    SyncTaggedPlaylist = newSyncTaggedPlaylist(msgPort, userVariables, bsp)
	
    return SyncTaggedPlaylist
End Function



Function newSyncTaggedPlaylist(msgPort As Object, userVariables As Object, bsp as Object)
	
	print "initSyncTaggedPlaylist Plugin"

	' Create the object to return and set it up
	
	s = {}
	s.msgPort = msgPort
	s.userVariables = userVariables
	s.bsp = bsp
	s.ProcessEvent = SyncTaggedPlaylist_ProcessEvent
	s.PluginSendMessage = PluginSendMessage
	s.PluginSendZonemessage = PluginSendZonemessage
	s.sTime = createObject("roSystemTime")
	s.ImageTimer=CreateObject("roTimer")
	s.ImageTimer.SetPort(s.msgPort)
	s.vm = CreateObject("roVideoMode")
	s.PluginSystemLog = CreateObject("roSystemLog")		
	s.HandleTimerEventPlugin = HandleTimerEventPlugin
	s.HandlePluginUDPEvent = HandlePluginUDPEvent
	s.HandlePluginMessageEvent = HandlePluginMessageEvent
	s.HandlePluginroAssetFetcherEvent = HandlePluginroAssetFetcherEvent
	s.PTPRegistrySet = PTPRegistrySet
	s.PlayfilesFromStorageMedia = PlayfilesFromStorageMedia
	s.PlayFileInSync = PlayFileInSync
	s.HandlePluginSyncEvent = HandlePluginSyncEvent
	s.StartDelayedCheckTimer = StartDelayedCheckTimer
	s.CheckDownloadFeed = CheckDownloadFeed

	if s.videoPlayer <> invalid then
		s.videoPlayer.StopClear()
		s.videoPlayer = invalid
	end if

	s.videoPlayer = CreateObject("roVideoPlayer")
	s.imagePlayer = CreateObject("roImagePlayer")
	s.rect1 = CreateObject("roRectangle", 0, 0, 1920,1080)
	s.videoPlayer.SetRectangle(s.rect1)
	s.imagePlayer.SetDefaultTransition(15)
	s.imagePlayer.SetTransitionDuration(3000)
	s.videoPlayer.SetPort(s.msgport)
	s.videoPlayer.SetAudioOutput(4)
	s.videoPlayer.SetVolume(100)
	s.registrySection = CreateObject("roRegistrySection", "networking")

	'Set Seamless looping for videoPlayer - 0 to disable and 1 to enable
	s.videoPlayer.SetLoopMode(0)
	's.timeOnScreen = 6000
	s.CheckCardForMediaFiles = CheckCardForMediaFiles
	s.SyncParam = SyncParam
	s.First_CONTENT_DATA_FEED_UNCHANGED = true
	s.Player_is_Master = false

	if s.bsp.currentuservariables.playlist_name <> invalid then
		s.TaggedPlaylistName = s.bsp.currentuservariables.playlist_name.Getcurrentvalue()
		s.PluginSystemLog.sendline(" @@@ User Variable value for playlist_name: " + s.TaggedPlaylistName)
	end if

	if s.bsp.currentuservariables.ptp_domain <> invalid then
		s.ptpDomain$ = s.bsp.currentuservariables.ptp_domain.Getcurrentvalue()
		s.PluginSystemLog.sendline(" @@@ User Variable value for ptp_domain: " + s.ptpDomain$)
	end if

	if s.bsp.currentuservariables.master_serials <> invalid then
		s.masterSerialList = s.bsp.currentuservariables.master_serials.Getcurrentvalue()
		s.PluginSystemLog.sendline(" @@@ User Variable value for master_serials: " + s.masterSerialList )
		s.playerID = CreateObject("roDeviceInfo").GetDeviceUniqueId()
		's.playerID = "D7E8A0001986" ' real player ID
		's.playerID = "D7E8A0001984" ' fake player ID

		master_serial_found = -1
		master_serial_found = instr(-1, s.masterSerialList, s.playerID) 

		if master_serial_found > 0 then
			s.Player_is_Master = true
			s.PluginSystemLog.sendline(" @@@ Player IS MASTER @@@ ")
		else 	
			print ""
			print " @@@ Player IS NOT MASTER @@@"
			print ""
			s.PluginSystemLog.sendline(" @@@ Player IS NOT MASTER @@@ ")
		end if
	end if

	s.IndexTracker = -1
	s.StartImageTimer = StartImageTimer
	s.ImageTimerTimeout = 6
	s.targetFeedID = invalid

	if s.SyncManager <> invalid then
		s.SyncManager = invalid
	end if

	if s.aa <> invalid then
		s.aa = invalid
	end if 

	if s.syncManagerEvent <> invalid then
		s.syncManagerEvent = invalid
	end if

	s.aa = {}
	s.aa.SyncDomain = "BrighSign"
	s.SyncManager = CreateObject("roSyncManager", s.aa)
	if s.Player_is_Master = true then
		'Old API for master mode
		s.SyncManager.SetMasterMode(true)
		'New API for master mode
		's.SyncManager.SetLeaderMode(True)
	end if	
	s.SyncManager.SetPort(s.msgPort)
	s.PTPRegistrySet()
	s.PluginSystemLog.SendLine(" @@@ Plugin Version 1.3 for Tagged playlist Sync Playback @@@ ")

	return s
End Function


	
Function SyncTaggedPlaylist_ProcessEvent(event As Object) as boolean

	retval = false
    'print "SyncTaggedPlaylist_ProcessEvent - entry"
   ' print "type of m is ";type(m)
   ' print "type of event is ";type(event)

	if type(event) = "roControlDown" then
			
		'retval = HandlePluginGPIOEvent(event, m)
	
	else if type(event) = "roAssociativeArray" then
		
		if type(event["EventType"]) = "roString"
			print ""
			print " @@@ EventType @@@ "; event["EventType"]
			print ""
			if event["EventType"] = "EVENT_PLUGIN_MESSAGE" then
				if event["PluginName"] = "SyncTaggedPlaylist" then
					pluginMessage$ = event["PluginMessage"]	
					'retval = HandlePluginMessageEvent(pluginMessage$)
				end if
			
			else if event["EventType"] = "SEND_PLUGIN_MESSAGE" then
			
				if event["PluginName"] = "SyncTaggedPlaylist" then
					pluginMessage$ = event["PluginMessage"]
					m.HandlePluginMessageEvent(pluginMessage$)
				end if
				
			else if event["EventType"] = "USER_VARIABLES_UPDATED" then
				'stop
			else if event["EventType"] = "USER_VARIABLE_CHANGE" then

			else if event["EventType"] = "CONTENT_DATA_FEED_UNCHANGED" then	
				print ""
				print " @@@ CONTENT_DATA_FEED_UNCHANGED @@@ "
				print ""
				if m.First_CONTENT_DATA_FEED_UNCHANGED = true then
					m.First_CONTENT_DATA_FEED_UNCHANGED = false
					m.CheckDownloadFeed(event.name)
				end if 	
			else if event["EventType"] = "PREPARE_FOR_RESTART" then	
				print ""
				print " @@@ PREPARE_FOR_RESTART @@@ "
				print ""
					
			end if
		end if
	else if type(event) = "roDatagramEvent" then
		retval = HandlePluginUDPEvent(event, m)
	else if type(event) = "roTimerEvent" then
		retval = HandleTimerEventPlugin(event, m)	
	else if type(event) = "roVideoEvent" then
		retval = HandlePluginVideoEvent(event, m)
	else if type(event) = "roAssetFetcherEvent" then
		retval = HandlePluginroAssetFetcherEvent(event, m)
	else if type(event) = "roHtmlWidgetEvent" then
		'retval = HandleHtmlWidgetEventPlugin(event, m)
	else if type(event) = "roStreamByteEvent" then
		'retval = HandleStreamByteEventPlugin(event, m)	
	else if type(event) = "roStreamLineEvent" then	
		'retval = HandleStreamEventPlugin(event, m)
	else if type(event) = "roUrlEvent" then	
		'retval = HandleUrlEventPlugin(event, m)
	else if type(event) = "roSyncManagerEvent" then
		retval = HandlePluginSyncEvent(event, m)	
	end if
	
	return retval
End Function
	


Function HandlePluginroAssetFetcherEvent(origMsg as Object, m as Object) as boolean

	retval = false
	userData$ = origMsg.GetUserData()
	currentEvent = origMsg.GetEvent()

	' print ""
	' print " *********** roAssetFetcherEvent userData$  ****************  " userData$
	' print " *********** roAssetFetcherEvent  currentEvent ****************  " currentEvent
	' print ""
	
	if currentEvent = 2 then
		print ""
		print "@@@ Feed fully downloaded @@@ ";
		print ""
		m.First_CONTENT_DATA_FEED_UNCHANGED = false
		m.CheckDownloadFeed(userData$)
	end if 
	
	return retval
End Function



Function HandlePluginUDPEvent(origMsg as Object, m as Object) as boolean

	print "UDP Message Received in plugin - "; origMsg

	if origMsg = "check" then
		'm.CheckDownloadFeed("eb5fe6c6-7154-4000-ac5d-2babc51ef000")
	end if

End Function



Function HandlePluginSyncEvent(origMsg as Object, m as Object) as boolean

	print "roSyncManagerEvent Message Received in plugin - "; origMsg

	retval = false

	synchronizeEvent$ = origMsg.GetId()
	m.syncInfo = CreateObject("roAssociativeArray")
	m.syncInfo.SyncDomain = origMsg.GetDomain()
	m.syncInfo.SyncId = origMsg.GetId()
	m.syncInfo.SyncIsoTimestamp = origMsg.GetIsoTimestamp()

	ok = m.PlayFileInSync(m.syncInfo)
	if ok then
		print "synchronizeEvent$: "; synchronizeEvent$ + " at: "; m.sTime.GetLocalDateTime()
	end if

	return retval
End Function



Function HandlePluginVideoEvent(origMsg as Object, m as Object) as boolean

	print "Video Message Received in plugin - "; origMsg

	retval = false

	VideoPlayerEventReceived = origMsg.GetInt()
			
	if VideoPlayerEventReceived = 8 then 
		m.IndexTracker = m.IndexTracker + 1
		print "Video End Event Received at: ";m.sTime.GetLocalDateTime()
		m.PlayfilesFromStorageMedia()
	else if VideoPlayerEventReceived = 3 then
		print "Video playing Event Received at ";m.sTime.GetLocalDateTime()	
	end if

End Function



Function HandleTimerEventPlugin(origMsg as Object, m as Object) as boolean

	timerIdentity = origMsg.GetSourceIdentity()

	if m.Player_is_Master = true then
		if type(m.ImageTimer) = "roTimer" then
			if m.ImageTimer.GetIdentity() = origMsg.GetSourceIdentity() then
				m.IndexTracker = m.IndexTracker + 1	
				m.PlayfilesFromStorageMedia()
				return true
			end if
		end if
	end if

	if type(m.DelayedCheckTimer) = "roTimer" then
		if m.DelayedCheckTimer.GetIdentity() = origMsg.GetSourceIdentity() then
			userData = origMsg.GetUserData()
			'print "FeedID: "; userData.FeedID
			m.CheckCardForMediaFiles(userData.FeedID)
			return true
		end if
	end if
End Function
	


Function HandlePluginMessageEvent(origMsg as string)

	print ""
	print " @@@ HandlePluginMessageEvent: "; origMsg
	print ""

	if origMsg = "GenNum" then
		'm.GenerateAllSessionSets()
	end if 	
End Function



Function PluginSendMessage(Pmessage$ As String)

	pluginMessageCmd = CreateObject("roAssociativeArray")
	pluginMessageCmd["EventType"] = "EVENT_PLUGIN_MESSAGE"
	pluginMessageCmd["PluginName"] = "SyncTaggedPlaylist"
	pluginMessageCmd["PluginMessage"] = Pmessage$
	m.msgPort.PostMessage(pluginMessageCmd)
End Function



Sub PluginSendZonemessage(msg$ as String)
	' send ZoneMessage message
	zoneMessageCmd = CreateObject("roAssociativeArray")
	zoneMessageCmd["EventType"] = "SEND_ZONE_MESSAGE"
	zoneMessageCmd["EventParameter"] = msg$
	m.msgPort.PostMessage(zoneMessageCmd)
End Sub



Function StartDelayedCheckTimer(FeedID as String, TimeoutVal as integer)
    userdata = {}
    userdata.FeedID = FeedID
    userdata.TimeoutVal = TimeoutVal

    newTimeout = m.sTime.GetLocalDateTime()
    newTimeout.AddMilliseconds(TimeoutVal)
    m.DelayedCheckTimer = CreateObject("roTimer")
    m.DelayedCheckTimer.SetPort(m.msgPort)	
    m.DelayedCheckTimer.SetDateTime(newTimeout)
    m.DelayedCheckTimer.SetUserData(userdata)	
    ok = m.DelayedCheckTimer.Start()
End Function



Function CheckDownloadFeed(feed as String)

	path = "sd:/feed_cache/"
	UserVarStringKey = ""
	xmlFileName$ = path + feed + ".xml"
	xml = CreateObject("roXMLElement")

	if not xml.Parse(ReadAsciiFile(xmlFileName$)) then 
		print "xml read failed"	
	else
		itemsByTitle = []

		if type(xml.channel.title) = "roXMLList" then
			if	xml.channel.title.gettext() = m.TaggedPlaylistName then	
				m.targetFeedID = feed
				' print ""
				' print " Target Feed Found and READY: "; m.targetFeedID
				' print ""
				m.StartDelayedCheckTimer(feed, 2000)
			end if			
		end if
	end if
End Function



Function PlayFileInSync(PlayParam as Object) As Boolean

	result = invalid
	playbackstarted = false

	if PlayParam <> invalid then

		fileindex$ = PlayParam.lookup("SyncId")
		fileindex% = int((val(fileindex$)))
		
		if m.targetFeedID <> invalid AND m.FileList <> invalid then
			if m.FileList[fileindex%] <> invalid then
				' print ""
				' print "m.targetFeedID: "; m.targetFeedID
				' print "m.FileList[fileindex%]: "; m.FileList[fileindex%]
				' print ""
				fullfilepath = m.bsp.liveDataFeeds[m.targetFeedID].assetpoolfiles.GetPoolFilePath(m.FileList[fileindex%])
				PlayParam.AddReplace("Filename", fullfilepath)
				if m.imagePlayer <> invalid then
					m.imagePlayer.StopDisplay()	
				end if
						
				result = m.videoPlayer.PlayFile(PlayParam)
			end if							
		end if
	end if	

	if result <> invalid then
		playbackstarted = true
	end if

	return playbackstarted
End Function



Sub SyncParam()

	SyncID$ = stri(m.IndexTracker)

	if m.SyncManager.GetCurrentConfig().master = 0 AND m.Player_is_Master = true then
		print "Re-Setting Master Mode"
		m.SyncManager.SetMasterMode(true)
	end if 	

	if m.bsp.liveDataFeeds[m.targetFeedID].assetpoolfiles <> invalid then
		m.syncManagerEvent = m.SyncManager.Synchronize(SyncID$, 1500)
		feedfilename = m.bsp.liveDataFeeds[m.targetFeedID].assetpoolfiles.GetPoolFilePath(m.FileList[m.IndexTracker])

		' print ""
		' print "SyncParam - entry: "
		' print "feedfilename: "; feedfilename
		' print "m.targetFeedID: "; m.targetFeedID
		' print "type(m.syncManagerEvent): "; type(m.syncManagerEvent)
		' print "type(m.SyncManager): "; type(m.SyncManager)
		' print "m.SyncManager.GetCurrentConfig()"
		' print m.SyncManager.GetCurrentConfig()
		' print ""
		
		if m.syncManagerEvent <> invalid then
			m.aa.AddReplace("Filename", feedfilename)
			m.aa.AddReplace("SyncDomain", m.syncManagerEvent.GetDomain())
			m.aa.AddReplace("SyncId", m.syncManagerEvent.GetId())
			m.aa.AddReplace("SyncIsoTimestamp", m.syncManagerEvent.GetIsoTimestamp())
			m.aa.AddReplace("FileIndex", m.IndexTracker)
		end if	

		' if m.syncManagerEvent = invalid then
		' 	print "SyncManagerEvent is invalid"
		' 	print "m.SyncManager.GetCurrentConfig()"
		' 	print m.SyncManager.GetCurrentConfig()
		' 	print "m.SyncManager.GetCurrentConfig().master: "; m.SyncManager.GetCurrentConfig().master
		' end if
	end if	
End Sub



Sub PTPRegistrySet()

	rebootRequired = false
	'm.ptpDomain$ = "0" - value extracted from presentation
	
	ptpDomainInRegistry$ = m.registrySection.Read("ptp_domain")
	if ptpDomainInRegistry$ <> m.ptpDomain$ then	
		Print"**** Writing ptp_domain to the Registry NOW ******"
		m.registrySection.Write("ptp_domain", m.ptpDomain$)
		rebootRequired = true
	endif
	
	if rebootRequired then
		Print"Flush the registry and reboot the system..." 
		m.registrySection.Flush()
		RebootSystem()
	endif
	
	m.vm.SetSyncDomain(m.ptpDomain$)
    print "@@@ VSYNC Enabled @@@ "
End Sub



Function StartImageTimer()
	
	newTimeout = m.sTime.GetLocalDateTime()
	newTimeout.AddSeconds(m.ImageTimerTimeout)
	m.ImageTimer.SetDateTime(newTimeout)
	m.ImageTimer.Start()
End Function



Function PlayfilesFromStorageMedia() As Boolean

	' print ""
	' print "PlayfilesFromStorageMedia - entry: "
	' print "m.FileList.count(): "; m.FileList.count()
	' print "m.IndexTracker: "; m.IndexTracker
	' print ""

	if m.FileList.count() <> invalid then
		if m.FileList.count() >= 0 then
			
			if m.IndexTracker = -1 or m.IndexTracker = m.FileList.count() then			
				m.IndexTracker = 0				
			end if
			
			if m.IndexTracker <= m.FileList.count() then

				if m.FileType[m.IndexTracker] = "V" then		
					if m.Player_is_Master = true then
						m.SyncParam()
					end if
					m.imagePlayer.StopDisplay()
				else if m.FileType[m.IndexTracker] = "I" then
					if m.Player_is_Master = true then				
						m.SyncParam()
						m.videoPlayer.StopClear()
						m.StartImageTimer()
					else 
						m.videoPlayer.StopClear()	
					end if						
				end if					
			end if
		end if
	end if	
	'return ok
End Function



Function CheckCardForMediaFiles(feed as String) As Object

	m.FileList = CreateObject("roArray", 1, true)
	m.FileType = CreateObject("roArray", 1, true)
	
	retval = false
	m.count = 0

	for each article in m.bsp.liveDataFeeds[feed].articles
		m.FileList[m.count] = ucase(article)
		m.FileType[m.count] = "V"
		m.count = m.count + 1
	next	
	
	if m.FileList.count() = 0 then
		print ""
		print "No Files Found"
		print ""
		m.videoPlayer.StopClear()
		m.imagePlayer.StopDisplay()
	else if m.FileList.count() > 0 then
		print stri(m.FileList.count()) + " Files found in target feed "
		if m.Player_is_Master = true then
			m.PlayfilesFromStorageMedia()
		end if	
	end if
	
	return retval
End Function
