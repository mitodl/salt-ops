# Open Courseware

[Table of Contents](index.md)

## Cron jobs

There are a number of cron jobs that run on the CMS engine server (CMS 2). Most of these generate XML and JSON files that are needed for mobile apps, client-side Javascript code, and for integrating with MITx.

### Generate OCW News Feeds

`/mnt/ocwfileshare/OCWEngines/generate_ocw_news_feeds.sh`

Runs as `ocwuser` from that account's crontab.

Runs [`news_feeds_downloader.py`](https://github.com/mitocw/ocwcms/blob/32acfd7d9d217afbe88fb58263da8e2755391ee1/publishing/news_feeds_dowloader.py)

Downloads the file `ocw_news_feeds.xml` from <https://www.ocw-openmatters.org/feed/> and copies it to the [mirror server and production server](architecture_overview.md). This file is consumed by [a Javascript script on the home page](https://github.com/mitocw/ocwcms/blob/5488df87bdd09ffeea2b874fb8db21d49a826457/web/scripts/ocw_rss_news.js) that displays course-related news.

The cron job is managed by [our `engines.sls` Salt state](https://github.com/mitodl/salt-ops/blob/f41844f3bb4fc2c38f06bd8a5760e583097ec3df/salt/apps/ocw/engines.sls#L40-L45).

### Generate JSON for Mobile Devices

`/mnt/ocwfileshare/OCWEngines/generate_json_for_mobile.sh`

Runs as `ocwuser` in that account's crontab.

Runs [`copy_json_for_mobile_data.py`](https://github.com/mitocw/ocwcms/blob/32acfd7d9d217afbe88fb58263da8e2755391ee1/publishing/copy_json_for_mobile_data.py). This requests the `json_for_mobile` Plone view for every department in the CMS, saving the results and copying individual JSON files for each department to the production origin server. The JSON contains detailed metadata about the courses, and is consumed by an OCW mobile app, in addition to some partner sites.

An example JSON file for one department: <https://ocw.mit.edu/courses/mathematics/mathematics.json>

The cron job is managed by [our `engines.sls` Salt state](https://github.com/mitodl/salt-ops/blob/f41844f3bb4fc2c38f06bd8a5760e583097ec3df/salt/apps/ocw/engines.sls#L47-L53).

### Generate Youtube Videos CSV File

`/mnt/ocwfileshare/OCWEngines/generate_youtube_videos_tab.sh`

Runs as `ocwuser` in that account's crontab.

Runs [`youtubevideosCSVcreator.py`](https://github.com/mitocw/ocwcms/blob/3349a9c732a2beb176730d9ab63ccbfb693d67e8/publishing/youtubevideosCSVcreator.py). This requests the CMS's `/view_csv_creator` resource, which returns a tab-delimted text response, with data about Youtube videos that have been embedded throughout the site. This file is then copied to the [mirror server](architecture_overview.md), where it will be referenced during the [mirror publishing process](engines_mirror.md) for downloading videos from Youtube in order to create a static mirror of the site. The file on the mirror server is `/data2/work/courses/ocw_youtube_videos.tab`.

The cron job is managed by [our `engines.sls` Salt state](https://github.com/mitodl/salt-ops/blob/f41844f3bb4fc2c38f06bd8a5760e583097ec3df/salt/apps/ocw/engines.sls#L55-L61).

### Generate `find-by-topic` URLs for Sitemap (a no-op).

This cron job was originally designed to write an XML file that would get appended to the `sitemap.xml` file created in the following section of this document. However, its functionality has been disabled and it does no more than generate an empty file which is `cat`ed onto the end of `sitemap.xml` by `sitemap.sh`.

The cron job has been disabled for the time being because it serves no purpose.

The cron job runs `/mnt/ocwfileshare/OCWEngines/runGenerateURLforSitemap.sh` as `ocwuser` in that account's crontab.

`runGenerateURLforSitemap.sh` executes [`generateURLforSitemap.py`](https://github.com/mitocw/ocwcms/blob/4c812b4c25ccdd8a39b8447ce79948cb7e94b2e5/publishing/generateURLforSitemap.py).


That script reads <https://ocw.mit.edu/courses/find-by-topic/topics.json>, which provides an array of departments, giving their names along with the filenames of corresponding JSON files.

The script then gets a list of JSON files from that file, one per department, and was designed to create a JSON file of departments, topics, and subtopics from all of those department JSON files. The output file, `generated_find_by_topic_Url_file.txt`, is finally used by `sitemap.sh` (see below) in building `sitemap.xml`.

This was apparently someone's idea of how to stop the cron job from writing this file, back in March 2017:
<https://github.com/mitocw/ocwcms/commit/fbf0ce3588986228a0b45b858244fab8daad89f0>

It is filtering out any lines that contain "find-by-topic", which applies to every line, because it constructs each line with 
<https://github.com/mitocw/ocwcms/blob/fbf0ce3588986228a0b45b858244fab8daad89f0/publishing/generateURLforSitemap.py#L67>.

### Generate Sitemap and ZIP File List

`/mnt/ocwfileshare/OCWEngines/run_aka_scripts.sh`

Runs as `ocwuser` in that account's crontab.

`run_aka_scripts.sh` executes [`sitemap.sh`](https://github.com/mitocw/ocwcms/blob/32acfd7d9d217afbe88fb58263da8e2755391ee1/publishing/sitemap.sh) and [`listzips.sh`](https://github.com/mitocw/ocwcms/blob/32acfd7d9d217afbe88fb58263da8e2755391ee1/publishing/listzips.sh) over SSH on the origin webservers.

`sitemap.sh` runs a series of `find` commands that apply a pipeline of filters to the HTML files on the webserver, creating `/var/www/ocw/sitemap.xml` (i.e. <https://www.ocw.mit.edu/sitemap.xml>).

`listzips.sh` runs a `find` command that applies a pipeline of filters to the HTML files in `courses` and `resources`, generating a list of URLs for ZIP files that it finds in hyperlinks in those files. The purpose of its output, `zips.txt` (<https://www.ocw.mit.edu/zips.txt>), is unclear. (`zips.txt` is not referenced by any of the code checked in to `ocwcms`, outside of the cron job, and there are no comments indicating its purpose.)

The cron job is managed by [our `engines.sls` Salt state](https://github.com/mitodl/salt-ops/blob/f41844f3bb4fc2c38f06bd8a5760e583097ec3df/salt/apps/ocw/engines.sls#L75-L81).

### Generate MITx Feeds

`/mnt/ocwfileshare/OCWEngines/generate_mitx_feeds.sh`

Runs as `ocwuser` in that account's crontab.

Runs [`mitxfeedsdownloader.py`](https://github.com/mitocw/ocwcms/blob/4c812b4c25ccdd8a39b8447ce79948cb7e94b2e5/publishing/mitxfeedsdownloader.py).  

Downloads an XML file of MITx courses from edX.org and merges the data in that file with `/mnt/ocwfileshare/mitx_archived_xml/mitx_archived_courses.xml`, which is generated by the CMS, producing a file, `mitx_feeds.xml`, which is then uploaded to the staging and production origin servers, and the mirror server.

For a given MIT course code, the XML describes the relevant course on MITx.

It's not clear from anything in the `ocwcms` repo what this file is used for, but there is a JSON file ([`edx_courses.json`](https://github.com/mitocw/ocwcms/blob/32acfd7d9d217afbe88fb58263da8e2755391ee1/web/scripts/mitx-related-courses.js#L9)) that is consumed by the Javascript that writes the "MITx Versions" section of a course's home page. This cron job does not appear to generate that JSON file. We have observed at least one page on the website (<https://ocw.mit.edu/courses/materials-science-and-engineering/3-091sc-introduction-to-solid-state-chemistry-fall-2010/>) that incurs requests in our Nginx access log from a mobile device for `mitx_feeds.xml`, so it's possible that there's some "magic" in the Javascript that's not apparent from a global keyword search through the code. It's also possible that the XML is consumed by a partner site.

The cron job is managed by [our `engines.sls` Salt state](https://github.com/mitodl/salt-ops/blob/f41844f3bb4fc2c38f06bd8a5760e583097ec3df/salt/apps/ocw/engines.sls#L102-L108).

### Update Broken Links Report

`/mnt/ocwfileshare/OCWEngines/run_broken_links_updater.sh`

Runs as `ocwcms` in that user's crontab.

The CMS has a broken links report available for content maintainers, in the [dashboard](https://ocwcms.mit.edu/dashboard). The report is regenerated by requesting the `/broken_links_checker` endpoint on the CMS.

This script executes `brokenlinkschecker.py`, which makes that HTTP request.

The cron job is managed by [our `engines.sls` Salt state](https://github.com/mitodl/salt-ops/blob/f41844f3bb4fc2c38f06bd8a5760e583097ec3df/salt/apps/ocw/engines.sls#L83-L89).

### Export Course JSON Files to S3

`/mnt/ocwfileshare/OCWEngines/export_courses_json.sh`

Whenever a course goes through [being published](engines_production.md), there is some corresponding JSON metadata that needs to be uploaded to an S3 bucket for consumption by related MIT and partner sites. There is a JSON view for every course that, when requested, causes a JSON file for the course to be saved to a subdirectory of `/export` on the CMS server. When the course is published, the file `/mnt/ocwfileshare/OCWEngines/export_urls.txt` is appended to indicate that the JSON needs to be uploaded. This script reads that file and hits the JSON view for each newly-published course, generating the JSON file. When it's done with all of those endpoint requests, it uploads all of the files to S3 using the `awscli` S3 client.

The cron job is managed by [our `engines.sls` Salt state](https://github.com/mitodl/salt-ops/blob/f41844f3bb4fc2c38f06bd8a5760e583097ec3df/salt/apps/ocw/engines.sls#L118-L126). It only runs in production.
