vcl 4.0;

backend default {
  .host = "wordpress";
  .port = "80";
}

acl purge {
  "127.0.0.1";
  "10.0.0.0"/8; # RFC1918 possible internal network
  "172.16.0.0"/12; # RFC1918 possible internal network
  "192.168.0.0"/16; # RFC1918 possible internal network
  "fc00::"/7; # RFC 4193 local private network range
  "fe80::"/10; # RFC 4291 link-local (directly plugged) machines
}

sub vcl_recv {
  if (req.method == "PURGE") {
    if (!client.ip ~ purge) {
      return (synth(405, "Not allowed."));
    }

    ban("req.url ~ ^" + req.url + "$ && req.http.host == " + req.http.host);
  }

  # Post requests will not be cached
  if (req.http.Authorization || req.method == "POST") {
    return (pass);
  }

  # --- WordPress specific configuration

  # Did not cache the RSS feed
  if (req.url ~ "/feed") {
          return (pass);
  }

  # Blitz hack
  if (req.url ~ "/mu-.*") {
          return (pass);
  }

  # Do not cache the admin, login and similar pages
  if (req.url ~ "wp-(login|admin|comments-post.php|cron.php)" ||
      req.url ~ "preview=true" ||
      req.url ~ "xmlrpc.php") {
    return (pass);
  }

  # Remove the "has_js" cookie
  set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");

  # Remove any Google Analytics based cookies
  set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");

  # Remove the Quant Capital cookies (added by some plugin, all __qca)
  set req.http.Cookie = regsuball(req.http.Cookie, "__qc.=[^;]+(; )?", "");

  # Remove the wp-settings-1 cookie
  set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-1=[^;]+(; )?", "");

  # Remove the wp-settings-time-1 cookie
  set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-time-1=[^;]+(; )?", "");

  # Remove the wp test cookie
  set req.http.Cookie = regsuball(req.http.Cookie, "wordpress_test_cookie=[^;]+(; )?", "");

  # Are there cookies left with only spaces or that are empty?
  if (req.http.cookie ~ "^ *$") {
    unset req.http.cookie;
  }

  # Remove cookies and query string for real static files
  if (req.url ~ "\.(bz2|css|flv|gif|gz|ico|jpeg|jpg|js|lzma|mp3|mp4|pdf|png|swf|tbz|tgz|txt|zip)(\?.*|)$") {
    unset req.http.cookie;
    set req.url = regsub(req.url, "\?.*$", "");
  }

  # Normalize content-encoding
  if (req.http.Accept-Encoding) {
    if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|lzma|tbz)(\?.*|)$") {
      unset req.http.Accept-Encoding;
    } elsif (req.http.Accept-Encoding ~ "gzip") {
      set req.http.Accept-Encoding = "gzip";
    } elsif (req.http.Accept-Encoding ~ "deflate") {
      set req.http.Accept-Encoding = "deflate";
    } else {
      unset req.http.Accept-Encoding;
    }
  }

  # Check the cookies for wordpress-specific items
  if (req.http.Cookie ~ "wordpress_" || req.http.Cookie ~ "comment_") {
    return (pass);
  }
  if (!req.http.cookie) {
    unset req.http.cookie;
  }

  # --- End of WordPress specific configuration

  # Do not cache HTTP authentication and HTTP Cookie
  if (req.http.Authorization || req.http.Cookie) {
    # Not cacheable by default
    return (pass);
  }

  # Cache all others requests
  return (hash);
}

sub vcl_pipe {
  return (pipe);
}

sub vcl_pass {
  return (fetch);
}

# The data on which the hashing will take place
sub vcl_hash {
  hash_data(req.url);
  if (req.http.host) {
    hash_data(req.http.host);
  } else {
    hash_data(server.ip);
  }

  # If the client supports compression, keep that in a different cache
  if (req.http.Accept-Encoding) {
    hash_data(req.http.Accept-Encoding);
  }

  return (lookup);
}

# This function is used when a request is sent by our backend
sub vcl_backend_response {
  # Don't cache backend
  if (bereq.url ~ "wp-(login|admin|comments-post.php|cron.php)" ||
    bereq.url ~ "preview=true" ||
    bereq.url ~ "xmlrpc.php") {
    # Dont modify anything, it's (pass) object
  } else {
    unset beresp.http.set-cookie;

    if (beresp.status == 307) {
      # Don't cache temporary redirects like ?repeat=w3tc
      set beresp.ttl = 0h;
    } else if (bereq.url ~ "\.(bz2|css|flv|gif|gz|ico|jpeg|jpg|js|lzma|mp3|mp4|pdf|png|swf|tbz|tgz|txt|zip)$") {
      set beresp.ttl = 30d;
    } else {
      set beresp.ttl = 4h;
    }
  }

  # don't cache response to posted requests or those with basic auth
  if (bereq.method == "POST" || bereq.http.Authorization) {
    set beresp.uncacheable = true;
    set beresp.ttl = 120s;
    return (deliver);
  }

  # don't cache search results
  if (bereq.url ~ "\?s="){
    set beresp.uncacheable = true;
    set beresp.ttl = 120s;
    return (deliver);
  }

  # only cache status ok
  if (beresp.status != 200) {
    set beresp.uncacheable = true;
    set beresp.ttl = 120s;
    return (deliver);
  }

  # Define the default grace period to serve cached content
  set beresp.grace = 30s;

  return (deliver);
}

# The routine when we deliver the HTTP request to the user
# Last chance to modify headers that are sent to the client
sub vcl_deliver {
  if (obj.hits > 0) {
    set resp.http.X-Cache = "cached";
  } else {
    set resp.http.x-Cache = "uncached";
  }

  # Remove some headers: PHP version
  unset resp.http.X-Powered-By;

  # Remove some headers: Apache version & OS
  unset resp.http.Server;

  # Remove some headers: Varnish
  unset resp.http.Via;
  unset resp.http.X-Varnish;

  return (deliver);
}

# Additional options
sub vcl_init {
  return (ok);
}
sub vcl_fini {
  return (ok);
}