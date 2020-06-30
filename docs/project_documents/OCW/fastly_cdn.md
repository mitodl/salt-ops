# OpenCourseWare

[Table of Contents](index.md)

## Fastly Content Delivery Network

**Production**: `ocw.mit.edu` or `ocw.global.ssl.fastly.net`. Also `www.ocw.mit.edu`, which just redirects to ocw.mit.edu.

**QA production**: `ocw-qa.global.ssl.fastly.net`

There is no CDN for [production-staging or qa-staging](https://github.mit.edu/odl-engineering/project-status/wiki/App-Links#ocw).

### HTTP/2


The CDNs support HTTP/2, as a basic feature that has no configuration or billing
settings.


### Proxying the S3 Bucket for Zip Files and Large Files


There are S3 buckets that store Zip files of courses and various other files that are too large for the Plone content management system. In the past, these were stored in Akamai Netstorage volumes. The production bucket is ocw-website-storage and the QA bucket is ocw-website-storage-qa.  Each bucket has a folder named `/zipfiles` that holds the Zip files, and one named `/largefiles` that holds the large files. On both production and QA, the CDN reverse-proxies the path `/ans7870` to the `/largefiles` folder, and proxies `/ans15436` to the `/zipfiles` folder. These "ans" folder names maintain consistency with the paths that have been used for years before the cutover to Fastly.

The reverse-proxying is configured in the Fastly control panel in the "Origins" section, and in the "S3 bucket proxying" VCL snippet in the "VCL Snippets" section.

Fastly's access to the S3 bucket is governed by the `ocw-fastly-website-storage-bucket-readonly` policy, which is attached to the `ocw-fastly-website-storage-bucket-readonly` IAM user. The S3 buckets are not publicly accessible, and are not web-enabled.

Access for content maintainers is governed by the `read-write-delete-ocw-website-storage-bucket` IAM policy, which is attached to the `jmartis` IAM user and the `ocw-engine-instance-role` role, as of May, 2020.


### Managing Redirects


The `recvRedirects` VCL snippet in each CDN configuration is responsible for redirects. There are some hostname-related redirects in the top part of that code, but most redirects are handled in the condition near the end where it looks up paths and their targets the `redirects` Dictionary.

The `redirects` dictionary appears in the "Data" section of the Fastly control panel, under "Dictionaries." The `key` field of each record is the path to redirect. This must not end in a trailing "/" character. The `value` field is a "|"-delimited string that provides the type of redirect by HTTP status code, whether to keep or discard the querystring, and the target of the redirect. The substring `{{AK_HOSTHEADER}}` will be replaced by the hostname given in the `Host` header in the request.


### TLS

TLS Certificate files are kept in Keybase in `team/mitodl.devops/ssl/`.

Only the production site has a custom TLS certificate. The certificate is issued by IS&T by the usual means of making an email support request to `mitcert@mit.edu`.

The TLS certificate covers `ocw.mit.edu` and `www.ocw.mit.edu`. The latter is hosted only for the purpose of redirecting to `ocw.mit.edu`.

### Purging the Cache

Purging the cache can be done as follows.

From the [admin panel Home page](https://manage.fastly.com/services/all), choose the CDN that you want to purge via the "active version" link.

Click "Configure" at the very top of the page.

You should see a page with a "Purge" dropdown menu near the top of the page. This provides options for purging by URL or "cache key." A cache key is a token that we assign to various groups of pages; for example, courses, stylesheets, Javascript scripts, and images. Either select a particular URL or choose one of the following cache keys:

* The URL path slug of a course; for example, "16-63j-system-safety-spring-2016"
* "courses" to to purge _all_ courses, plus all of their related RSS (.xml) files
* "styles" to purge _all_ stylesheets in the "/styles" path
* "scripts" to purge _all_ Javascript in the "/scripts" path
* "images" to purge _all_ images in the "/images" path
* "high-school" to purge _all_ resources under "/high-school"
* "ocw-labs" to purge _all_ resources under "/ocw-labs"
* "about" to purge _all_ resources under "/about"
* "ans7870" to purge _all_ of the "large files" resources for courses, under "/ans7870"
* "ans15436" to purge _all_ of the "zip files" resources for courses, under "/ans15436"
* "educator" to purge _all_ resources under "/educator"
* "faculty" to purge _all_ resources under "/faculty"
* "give" to purge _all_ resources under "/give"
* "help" to purge _all_ resources under "/help"
* "resources" to purge _all_ resources under "/resources"
* "search" to purge _all_ resources under "/search"
* "terms" to purge _all_ resources under "/terms"
* "webfonts" to purge _all_ webfont files under "/webfonts"

### Differences Between QA and Production CDNs


#### Image Optimizer

The "Image Optimizer" feature is turned *on* in production, but *off* in QA. Turning it on requires getting a price quote from Fastly.

#### TLS

There are no TLS Domains associated with QA, where we use the free
`ocw-qa.global.ssl.fastly.net` domain.

#### Redirects

QA does not have all of the redirects that Production has, but it does have the same VCL and Dictionary for configuring redirects as necessary, if we need to test them.

The QA site serves up a robots.txt that forbids all robot access. This is circumvented in production by issuing a redirect to another file, robots-akamai.txt, which allows access. This redirect does not happen on the production *origin* server, causing robots to get the version that denies access. (This behavior is the same as it was with Akamai.) The combination of these behaviors guards against search engines indexing the QA site as well as the origin servers (for example, ocw-origin.odl.mit.edu.). The production redirect is managed in the "redirects" Dictionary in the production Service Configuration.

Both the production and QA CDNs redirect any plain HTTP request to HTTPS. This is governed by the "Force TLS and enable HSTS" setting in Configure > Settings in the control panel. In addition, HSTS is employed (via the `Strict-Transport-Security` HTTP header) to instruct browsers *never* to make plain HTTP requests in the future (even if the user puts "http://" in the browser address bar) and upgrade to HTTPS, after the user has visited the site once over TLS and has received the Strict-Transport-Security header.


#### Logging and Alerting

The QA and Production CDNs send log files to S3.

Production bucket: `ocw-fastly-access-logs-production`

QA bucket: `ocw-fastly-access-logs-qa`

The logs are in JSONL format, where each line is a JSON object.

The QA CDN has a shorter logfile rotation period than production. Production is currently set (as of 2020-05-14) to rotate hourly, and QA is set to rotate every five minutes. Logs can take some time to be uploaded to S3 after they are rotated. For example, a log rotated at midnight will bear a filename marking it with "000000" but it may not be be available in S3 until 00:15 or even later.

No logfiles are generated for periods lacking requests.

Fastly is configured to create a monthly (ex. 202005) subfolder in S3 and ship logs of the month to that folder.

Access to the logging bucket is granted to the `ocw-fastly-logger` IAM user, which has two attached policies, `ocw-fastly-log-bucket-rw-qa` and `ocw-fastly-log-bucket-rw-production`.  The `ocw-fastly-logger` user has two Access Keys, one for production and one for QA.

Fastly has a web API that we can use to gather analytics and to generate alerts. We have not implemented any API-based statistics or alerts, as of May, 2020; but we have a Trello card for doing so eventually.
