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

  # Remove cookies and query string for real static files
  if (req.url ~ "\.(bz2|css|flv|gif|gz|ico|jpeg|jpg|js|lzma|mp3|mp4|pdf|png|swf|tbz|tgz|txt|zip)(\?.*|)$") {
    unset req.http.cookie;
    set req.url = regsub(req.url, "\?.*$", "");
  }

  if (req.url ~ "wp-(login|admin|comments-post.php|cron.php)" ||
      req.url ~ "preview=true" ||
      req.url ~ "xmlrpc.php") {
    return (pass);
  }

  return (hash);
}

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
}

sub vcl_hit {
  if (req.method == "PURGE") {
    return (purge);
  }
}
