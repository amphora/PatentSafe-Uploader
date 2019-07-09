From [this site](https://xiix.wordpress.com/2006/03/23/mozillafirefox-cookie-format/):


This applies to permanent cookies only, as session cookies (cleared when you quit the browser) are not saved to a text 
file. One complete cookie per line, and each piece is separated by a tab character (‘\t’ in Python), not a standard 
space character as shown here:

```
.example.com TRUE / FALSE 1143149359 login_id 123456
www.yermom.com FALSE / FALSE 1143149359 my_nuts on
```

Column | Use | Description
--- | --- | ---
1 | Domain | The domain that set & can subsequently read the cookie. This could include subdomains, e.g., .google.com means that local.google.com, news.google.com, whatever.google.com could possibly read the cookie, based on the next flag.
2 | Flag | Either TRUE or FALSE, whether or not all machines under that domain can read the cookie’s information.
3 | Path | the root path under the domain where the cookie is valid. If this is /, the cookie is valid for the entire domain.
4 | Secure Flag| Either TRUE or FALSE, whether or not a secure connection (HTTPS) is required to read the cookie.
5 | Expiration Timestamp| The “Unix Time” in seconds when the cookie is set to expire. You can [use this site](https://www.epochconverter.com) to calculate values - make sure you use the Epoch timestamp, not the milliseconds one.  
6 | Name | The name of the value that the cookie is storing/saving.
7 | Value| The value of the cookie itself

