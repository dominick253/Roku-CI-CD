sub Main(args as dynamic)
    print "Main started with args: "; args
    contentId = args.contentId
    mediaType = args.mediaType
    print "mediaType: "; mediaType
    print "contentId: "; contentId

    xfer = CreateObject("roURLTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.SetURL("https://nazarene.dominickp.com/feed")
    feed = xfer.GetToString()

    m.screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    m.screen.SetMessagePort(m.port)

    m.scene = m.screen.CreateScene("MainScene")
    print "Showing screen"
    m.scene.feedJson = feed

    m.screen.Show()

    ' Handle deep link if present
    if contentId <> invalid and type(contentId) = "roString"
        print "Checking contentId: "; contentId
        if valid_contentId(contentId)
            print "ContentId valid, calling playContent"
            ' Wait briefly to ensure scene is initialized
            sleep(100)
            m.scene.callFunc("playContent", {
                contentId: contentId,
                feedJson: feed
            })
        else
            print "Invalid contentId: "; contentId
        end if
    else
        print "No valid contentId provided or contentId is invalid"
    end if

    while true
        msg = wait(0, m.port)
        if type(msg) = "roSGScreenEvent" then
            if msg.IsScreenClosed() then
                exit while
            end if
        else if type(msg) = "roInputEvent" then
            if msg.IsInput()
                info = msg.GetInfo()
                if info.DoesExist("mediaType") and info.DoesExist("contentId")
                    mediaType = info.mediaType
                    contentId = info.contentId
                    print "Input event - mediaType: "; mediaType; ", contentId: "; contentId
                    if contentId <> invalid and type(contentId) = "roString" and valid_contentId(contentId)
                        print "Input event: Calling playContent"
                        m.scene.callFunc("playContent", {
                            contentId: contentId,
                            feedJson: feed
                        })
                    else
                        print "Input event: Invalid contentId: "; contentId
                    end if
                end if
            end if
        end if
    end while
end sub

function valid_contentId(contentId as string) as boolean
    print "Validating contentId: "; contentId
    xfer = CreateObject("roURLTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.SetURL("https://nazarene.dominickp.com/feed")
    rsp = xfer.GetToString()

    json = ParseJson(rsp)
    if json = invalid then
        print "Invalid JSON in valid_contentId"
        return false
    end if

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
                    if item.DoesExist("id") and item.id = contentId
                        print contentId + " exists in the JSON feed >>>>>>"
                        return true
                    end if
                end for
            end if
        end if
    end for

    print "ContentId not found: "; contentId
    return false
end function