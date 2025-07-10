sub init()
    print "ContentTask: Initializing"
    m.top.functionName = "fetchContent"
end sub

sub fetchContent()
    print "ContentTask: Fetching content from URL: "; m.top.url
    http = CreateObject("roUrlTransfer")
    http.SetUrl(m.top.url)
    http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    http.InitClientCertificates()
    http.EnableHostVerification(false)
    http.EnablePeerVerification(false)

    response = http.GetToString()
    if response <> ""
        print "ContentTask: Received response: "; Left(response, 100); "..."
        json = ParseJson(response)
        if json <> invalid
            print "ContentTask: Parsed JSON successfully"
            m.top.content = json
        else
            print "ContentTask: Error: Failed to parse JSON"
            m.top.content = {}
        end if
    else
        print "ContentTask: Error: No response from server"
        m.top.content = {}
    end if
end sub