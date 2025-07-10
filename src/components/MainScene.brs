' ********** Copyright 2020 Roku Corp. All Rights Reserved. **********

sub Init()
    print "Initializing MainScene"
    m.top.signalBeacon("AppLaunchComplete")
    m.top.signalBeacon("AppDialogInitiate")
    m.top.signalBeacon("AppDialogComplete")

    feedJson = m.globalFields?.feedJson
    if feedJson <> invalid
        json = ParseJson(feedJson)
        if json = invalid
            print "JSON was invalid"
        else
            print "Feed JSON parsed successfully"
            ' Do your logic here with it
        end if
    else
        print "No feedJson passed in"
    end if


    m.top.backgroundColor = "0x662D91"
    m.top.backgroundUri = "pkg:/images/2.png"
    m.loadingIndicator = m.top.FindNode("loadingIndicator")
    InitScreenStack()
    ShowGridScreen()
    RunContentTask()
end sub

sub onContentIdChange()
    contentId = m.top.contentId
    if contentId <> invalid and contentId <> ""
        print "contentId field changed, calling playContent: "; contentId
        playContent(contentId)
    else
        print "Invalid contentId in onContentIdChange"
    end if
end sub

function playContent(data as object) as void
    contentId = data.contentId
    feed = data.feedJson
    json = ParseJson(feed)

    if json = invalid
        print "Invalid JSON passed to playContent"
        return
    end if

    print "<<<<<<<<<< Valid Json received in PlayContent Function >>>>>>>>>>>>>>>>"

    skipKeys = ["providerName", "lastUpdated", "language"]

    for each key in json
        skip = false
        for each s in skipKeys
            if s = key then skip = true : exit for
        end for

        if not skip
            items = json[key]
            if type(items) = "roArray"
                for each item in items
                    if item?.DoesExist("id") and item.id = contentId
                        if item?.content?.videos?[0]?.url <> invalid
                            videoContent = CreateObject("roSGNode", "ContentNode")
                            videoContent.url = item.content.videos[0].url
                            videoContent.streamFormat = "mp4"
                            videoContent.title = item?.title
                            videoContent.description = item?.shortDescription

                            parentNode = CreateObject("roSGNode", "ContentNode")
                            parentNode.Update({ children: [videoContent] }, true)

                            overhang = m.top.findNode("overhang")
                            if overhang <> invalid
                                print "Hiding overhang"
                                overhang.visible = false
                            end if
                            loading = m.top.findNode("loadingIndicator")
                            if loading <> invalid
                                print "Hiding loadingIndicator"
                                loading.visible = false
                            end if

                            menuHidden = false
                            for each menuId in ["GridScreen", "MainMenu", "HomeScreen", "Grid"]
                                menu = m.top.findNode(menuId)
                                if menu <> invalid
                                    print "Hiding menu node: "; menuId
                                    menu.visible = false
                                    menuHidden = true
                                    exit for
                                end if
                            end for
                            if not menuHidden
                                print "Warning: No main menu node found. Listing all nodes:"
                                children = m.top.getChildren(-1, 0)
                                for each child in children
                                    print "Node ID: "; child.id; ", Type: "; child.subType(); ", Visible: "; child.visible
                                end for
                            end if

                            print "Calling ShowVideoScreen for contentId: "; contentId
                            ShowVideoScreen(parentNode, 0)
                            m.video = m.videoPlayer
                            print "Now playing: "; videoContent.url
                            if m.videoPlayer <> invalid
                                print "Video player state: "; m.videoPlayer.state
                            else
                                print "Error: m.videoPlayer is invalid after ShowVideoScreen"
                            end if
                            return
                        else
                            print "Invalid video data for contentId: "; contentId
                            return
                        end if
                    end if
                end for
            end if
        end if
    end for

    print "Content ID not found: "; contentId
end function

sub OnVideoStateChange()
    if m.video <> invalid and (m.video.state = "stopped" or m.video.state = "finished" or m.video.state = "error")
        print "Video state changed to: "; m.video.state
        CloseScreen(m.videoPlayer)
        m.top.removeChild(m.video)
        m.video = invalid
        overhang = m.top.findNode("overhang")
        if overhang <> invalid
            print "Restoring overhang"
            overhang.visible = true
        end if
        ShowGridScreen()
    end if
end sub

function OnKeyEvent(key as string, press as boolean) as boolean
    result = false
    if press
        if key = "back"
            numberOfScreens = m.screenStack.Count()
            if numberOfScreens > 1
                CloseScreen(invalid)
                result = true
            end if
        end if
    end if
    return result
end function