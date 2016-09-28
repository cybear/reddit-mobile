backend mweb {
    .host = "mweb";
    .port = "4444";
}
/* backend www {
    .host = "www.reddit.com";
    .port = "80";
} */

sub vcl_recv {
  call device_detect;

  # NOTE(wting|2016-09-26): Normally we would redirect the user to different
  # backends, but instead we're just returning rarely used status codes for
  # easy programmatic testing.
  if (req.http.Cookie !~ "(^|;\s*)(mweb-no-redirect=1)(;|$)"
      && (req.http.X-UA-Device ~ "^mobile-" || req.http.X-UA-Device ~ "^tablet-")) {
    # set req.backend = mweb;
    error 444;
  } else {
    # set req.backend = www;
    error 451;
  }
}

# Vendorized from https://github.com/varnish/varnish-devicedetect/blob/master/devicedetect.vcl
# BSD-2 License
sub device_detect {
  unset req.http.X-UA-Device;
  set req.http.X-UA-Device = "pc";

  # Handle that a cookie may override the detection alltogether.
  if (req.http.Cookie ~ "(?i)X-UA-Device-force") {
    /* ;?? means zero or one ;, non-greedy to match the first. */
    set req.http.X-UA-Device = regsub(req.http.Cookie, "(?i).*X-UA-Device-force=([^;]+);??.*", "\1");
    /* Clean up our mess in the cookie header */
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|; ) *X-UA-Device-force=[^;]+;? *", "\1");
    /* If the cookie header is now empty, or just whitespace, unset it. */
    if (req.http.Cookie ~ "^ *$") {
      unset req.http.Cookie;
    }
  } else {
    if (req.http.User-Agent ~ "\(compatible; Googlebot-Mobile/2.1; \+http://www.google.com/bot.html\)"
        || (req.http.User-Agent ~ "(Android|iPhone)"
            && req.http.User-Agent ~ "\(compatible.?; Googlebot/2.1.?; \+http://www.google.com/bot.html")
        || (req.http.User-Agent ~ "(iPhone|Windows Phone)"
            && req.http.User-Agent ~ "\(compatible; bingbot/2.0; \+http://www.bing.com/bingbot.htm")
    ) {
      set req.http.X-UA-Device = "mobile-bot";
    } elsif (req.http.User-Agent ~ "(?i)(ads|google|bing|msn|yandex|baidu|ro|career|seznam|)bot"
             || req.http.User-Agent ~ "(?i)(baidu|jike|symantec)spider"
             || req.http.User-Agent ~ "(?i)scanner"
             || req.http.User-Agent ~ "(?i)(web)crawler"
    ) {
      set req.http.X-UA-Device = "bot";
    } elsif (req.http.User-Agent ~ "(?i)ipad") {
      set req.http.X-UA-Device = "tablet-ipad";
    } elsif (req.http.User-Agent ~ "(?i)ip(hone|od)") {
      set req.http.X-UA-Device = "mobile-iphone";
    } elsif (req.http.User-Agent ~ "(?i)android.*(mobile|mini)") {
      /* how do we differ between an android phone and an android tablet? */
      /* http://stackoverflow.com/questions/5341637/how-do-detect-android-tablets-in-general-useragent */
      set req.http.X-UA-Device = "mobile-android";
    }
    elsif (req.http.User-Agent ~ "(?i)android 3") {
      /* https://github.com/varnish/varnish-devicedetect/blob/master/devicedetect.vcl */
      set req.http.X-UA-Device = "tablet-android";
    } elsif (req.http.User-Agent ~ "Opera Mobi") {
      /* Opera Mobile */
      set req.http.X-UA-Device = "mobile-smartphone";
    }
    elsif (req.http.User-Agent ~ "(?i)android") {
      /* May very well give false positives towards android tablets. Suggestions welcome. */
      set req.http.X-UA-Device = "tablet-android";
    } elsif (req.http.User-Agent ~ "PlayBook; U; RIM Tablet") {
      set req.http.X-UA-Device = "tablet-rim";
    } elsif (req.http.User-Agent ~ "hp-tablet.*TouchPad") {
      set req.http.X-UA-Device = "tablet-hp";
    } elsif (req.http.User-Agent ~ "Kindle/3") {
      set req.http.X-UA-Device = "tablet-kindle";
    } elsif (req.http.User-Agent ~ "Touch.+Tablet PC" || req.http.User-Agent ~ "Windows NT [0-9.]+; ARM;" ) {
      set req.http.X-UA-Device = "tablet-microsoft";
    } elsif (req.http.User-Agent ~ "Mobile.+Firefox") {
      set req.http.X-UA-Device = "mobile-firefoxos";
    } elsif (req.http.User-Agent ~ "^HTC"
             || req.http.User-Agent ~ "Fennec"
             || req.http.User-Agent ~ "IEMobile"
             || req.http.User-Agent ~ "BlackBerry"
             || req.http.User-Agent ~ "BB10.*Mobile"
             || req.http.User-Agent ~ "GT-.*Build/GINGERBREAD"
             || req.http.User-Agent ~ "SymbianOS.*AppleWebKit") {
      set req.http.X-UA-Device = "mobile-smartphone";
    }
    elsif (req.http.User-Agent ~ "(?i)symbian"
           || req.http.User-Agent ~ "(?i)^sonyericsson"
           || req.http.User-Agent ~ "(?i)^nokia"
           || req.http.User-Agent ~ "(?i)^samsung"
           || req.http.User-Agent ~ "(?i)^lg"
           || req.http.User-Agent ~ "(?i)bada"
           || req.http.User-Agent ~ "(?i)blazer"
           || req.http.User-Agent ~ "(?i)cellphone"
           || req.http.User-Agent ~ "(?i)iemobile"
           || req.http.User-Agent ~ "(?i)midp-2.0"
           || req.http.User-Agent ~ "(?i)u990"
           || req.http.User-Agent ~ "(?i)netfront"
           || req.http.User-Agent ~ "(?i)opera mini"
           || req.http.User-Agent ~ "(?i)palm"
           || req.http.User-Agent ~ "(?i)nintendo wii"
           || req.http.User-Agent ~ "(?i)playstation portable"
           || req.http.User-Agent ~ "(?i)portalmmm"
           || req.http.User-Agent ~ "(?i)proxinet"
           || req.http.User-Agent ~ "(?i)sonyericsson"
           || req.http.User-Agent ~ "(?i)symbian"
           || req.http.User-Agent ~ "(?i)windows\ ?ce"
           || req.http.User-Agent ~ "(?i)winwap"
           || req.http.User-Agent ~ "(?i)eudoraweb"
           || req.http.User-Agent ~ "(?i)htc"
           || req.http.User-Agent ~ "(?i)240x320"
           || req.http.User-Agent ~ "(?i)avantgo") {
      set req.http.X-UA-Device = "mobile-generic";
    }
  }
}