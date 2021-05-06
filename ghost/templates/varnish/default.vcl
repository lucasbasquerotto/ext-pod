vcl 4.0;

# set default backend if no server cluster specified
backend default {
    .host = "ghost";
    .port = "2368";
}

# access control list for "purge": open to only localhost and other local nodes
acl purge {
    "127.0.0.1";
    "10.0.0.0"/8; # RFC1918 possible internal network
    "172.16.0.0"/12; # RFC1918 possible internal network
    "192.168.0.0"/16; # RFC1918 possible internal network
    "fc00::"/7; # RFC 4193 local private network range
    "fe80::"/10; # RFC 4291 link-local (directly plugged) machines
}

# vcl_recv is called whenever a request is received
sub vcl_recv {
    # Serve objects up to 2 minutes past their expiry if the backend
    # is slow to respond.
    # set req.grace = 120s;

    # Did not cache the admin and preview pages
    if (req.url ~ "/(admin|p|ghost)/") {
        return (pass);
    }

    # Pass requests from logged-in users directly.
    # Only detect cookies with "session" and "Token" in file name, otherwise nothing get cached.
    if (req.http.Authorization || req.http.Cookie ~ "session" || req.http.Cookie ~ "Token") {
        return (pass);
    } /* Not cacheable by default */

    # This uses the ACL action called "purge". Basically if a request to
    # PURGE the cache comes from anywhere other than localhost, ignore it.
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return (synth(405, "Not allowed."));
        } else {
            return (purge);
        }
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
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.

    set beresp.ttl = 5m;
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.

   if ( req.url ~ "/ghost/" || req.url ~ "/signout" || req.url ~ "/p/" ) {
        set resp.http.Cache-Control = "no-cache, private, no-store, must-revalidate, max-stale=0, post-check=0, pre-check=0";
        set resp.http.expires = "0";
    }

    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }

    set resp.http.X-Proxy-Cache = "1";
}
