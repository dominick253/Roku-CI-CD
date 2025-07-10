' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainLoaderTask.xml using relative path.
sub Init()
    ' set the name of the function in the Task node component to be executed when the state field changes to RUN
    ' in our case this method executed after the following cmd: m.contentTask.control = "run"(see Init method in MainScene)
    m.top.functionName = "GetContent"
end sub

sub GetContent()
    xfer = CreateObject("roURLTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.SetURL("https://nazarene.dominickp.com/feed")
    rsp = xfer.GetToString()

    rootChildren = []
    json = ParseJson(rsp)

    if json <> invalid
        ' Get all month-year keys and sort them
        monthKeys = []
        for each key in json
            if key <> "providerName" and key <> "lastUpdated" and key <> "language"
                monthKeys.Push(key)
            end if
        end for

        ' Sort months in descending order
        for i = 0 to monthKeys.Count() - 2
            for j = 0 to monthKeys.Count() - 2 - i
                if CompareDates(monthKeys[j], monthKeys[j + 1]) < 0 then
                    temp = monthKeys[j]
                    monthKeys[j] = monthKeys[j + 1]
                    monthKeys[j + 1] = temp
                end if
            end for
        end for

        ' Process each month
        for each monthKey in monthKeys
            videos = json[monthKey]
            if Type(videos) = "roArray" and videos.Count() > 0
                row = {
                    title: monthKey
                    children: []
                }

                ' Sort videos by releaseDate
                sortedVideos = []
                for each video in videos
                    sortedVideos.Push(video)
                end for

                for i = 0 to sortedVideos.Count() - 2
                    for j = 0 to sortedVideos.Count() - 2 - i
                        if sortedVideos[j].releaseDate < sortedVideos[j + 1].releaseDate then
                            temp = sortedVideos[j]
                            sortedVideos[j] = sortedVideos[j + 1]
                            sortedVideos[j + 1] = temp
                        end if
                    end for
                end for

                ' Add sorted videos to row
                for each item in sortedVideos
                    itemData = GetItemData(item)
                    row.children.Push(itemData)
                end for

                rootChildren.Push(row)
            end if
        end for

        contentNode = CreateObject("roSGNode", "ContentNode")
        contentNode.Update({
            children: rootChildren
        }, true)
        m.top.content = contentNode
    end if
end sub

function CompareDates(date1 as string, date2 as string) as integer
    months = ["January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"]

    d1Parts = date1.Split(" ")
    d2Parts = date2.Split(" ")

    year1 = d1Parts[1].ToInt()
    year2 = d2Parts[1].ToInt()

    if year1 > year2 then return 1
    if year1 < year2 then return -1

    month1 = -1
    month2 = -1

    for i = 0 to months.Count() - 1
        if months[i] = d1Parts[0] then month1 = i
        if months[i] = d2Parts[0] then month2 = i
        if month1 >= 0 and month2 >= 0 then exit for
    end for

    if month1 > month2 then return 1
    if month1 < month2 then return -1
    return 0
end function

' Assuming GetItemData exists elsewhere in your code
' Adjust this based on your actual video node requirements
function GetItemData(item) as object
    itemData = {}
    itemData.title = item.title
    itemData.description = item.shortDescription
    itemData.sdPosterUrl = item.thumbnail
    itemData.hdPosterUrl = item.thumbnail
    itemData.url = item.content.videos[0].url

    ' respect the feed’s declared type
    ' pull the feed’s videoType and force it into the exact lowercase strings Roku expects
    fmt = LCase(item.content.videos[0].videoType)

    ' you may also want to map any oddball values:
    if fmt = "hls" or fmt = "dash" or fmt = "mp4" then
        itemData.streamFormat = fmt
    else
        ' default fallback to mp4 if it’s something unexpected
        itemData.streamFormat = "mp4"
    end if

    return itemData
end function

