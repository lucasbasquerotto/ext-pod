acl purge {
    "yourghostserver.com";
    "10.58.33.224";
}

if (req.url ~ "/clearcache/myblog") {
        # Same ACL check as above:
        if (!client.ip ~ purge) {
                return(synth(403, "Not allowed."));
        }
        ban("req.http.host == myblog.com");

        # Throw a synthetic page so the
        # request won't go to the backend.
        return(synth(200, "Cache cleared"));
}

# Did not cache the admin and preview pages
if (req.url ~ "/(admin|p|ghost)/") {
        return (pass);
}