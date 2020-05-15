# Open CourseWare

[Table of Contents](index.md) >
[Publishing Engines](engines.md)

## Mirror Creation Process

In addition to maintaining the OCW website, OCW staff also produce removable storage devices that contain offline copies of the website, which they ship to remote organizations that want to have their own internal copies of the site, or want to host thier own versions of it. The [mirror, a.k.a. rsync server](architecture_overview.md) receives files both during a normal production publishing event, and also during a final "mirror" engine event, in order to process and bundle up the files, which an OCW employee can then rsync to a workstation in order to build a removable drive for shipping.

### Production publishing events

Files are pushed to the mirror server during the [production publishing process](engines_production.md), when `publishing.mirror.publish_to_mirror()` is called. As noted in [the production publishing document](engines_production.md), old files related to the course are deleted from the mirror server and new ones are uploaded, either from the production or staging server. These files include course content as well as JSON files.

### Mirror Engine publishing process

The mirror publishing process is relatively simple, compared to the other ones for staging, production, and archiving. When the "run" button is clicked in the CMS's `/manage-engines`, `engines.MirrorDriveUpdateEngine._create_new_mirror_snapshot()` is called, followed by `engines.MirrorDriveUpdateEngine._update_mirror_snapshot()`. Each of these simply runs a corresponding shell script that exists on the mirror server.

`_create_new_mirror_snapshot()` runs `/var/lib/ocwcms/mirror/scripts/create_new_snapshot.sh` and `_update_new_mirror_snapashot()` runs `/var/lib/ocwcms/mirror/scripts/update_snapshot.sh`.

`create_new_snapshot.sh` does the following:

1. Sets up a working directory and some symbolic links
2. Copies files that have been placed in `/data2/prod` by the [production publishing engine](engines_production.md) into the working directory.
3. Copies image files from `/data2/prod` into the working directory.
4. Copies ZIP files that the publishing processes put in `/ans15436`, and which have been uploaded to Amazon S3, into the working directory.
5. Copies other static page assets, like stylesheets and javascript files, into the working directory from `/data2/prod`.
6. Saves a file containing the timestamp when it started executing, and which was used to generate the name of its working directory. This timestamp will be used by `update_snapshot.sh` to determine which working directory to use.

`update_snapshot.sh` does the following:

1. Downloads some files from the Visualizing Cultures website (hosted outside of `ocw.mit.edu` via a redirect on the live site) into the working directory created by `create_new_snapshot.sh`.
2. Recursively downloads into the working directory a select list of directories within Amazon S3 (that appear in the `ans*` paths on the site). The list of files is determined by searching for URL patterns throughout every HTML file stored within the working directory, using a program named `find_links.py`
3. Downloads all media files from Internet Archive referenced throughout the site, to the working directory, searching for URL patterns in every HTML file stored within the working directory, using `find_links.py`.
4. Downloads media files and background images to the working directory, by querying for the files on the CMS engine server, or by examining [the CSV file of Youtube video data](cron_jobs.md) and then running `Download_media_background_images.py`. This Python script walks through the list of files and generates a shell script (`media_and_background_images.sh`) that it then executes to download the files from Youtube, Internet Archive, or TechTV, depending on the file.
5. Finds links to Java applets (`.class` and `.jar` files) within the HTML pages of the site, by running `find_applet_embeds.py`, which generates a file that is fed into `wget` to download them into the working directory. It also copies Java files from `/data2/mitstorage` into the working directory.
6. ~~Downloads more files from Akamai net storage by searching through the site's HTML for links, this time from `http://mfile.akamai.com/7870/`. These appear to be mostly Real Media files, based on the step below for altering links to Real Media resources~~. *This step is scheduled to be removed. It no longer produces a list of files.*
7. Rewrites URL patterns throughout the site's HTML by running `rewrite_links.py`, which performs pattern replacements. For example, the pattern `http://www.archive.org/download/` will be changed to `/OcwExport/InternetArchive/`, and the pattern `http://ocw.mit.edu/` will be changed to `/`.
8. Rewrites embedded media links throughout the site's HTML, similarly to the step above. It runs `rewrite_inline_embeds.py`, which generates a shell script (`fix_inline_embeds.sh`) which it then executes. Most of the links altered are to Youtube and Internet Archive embedded media.
9. Alters the link to the donation page on the site's home page, `index.htm`.
10. ~~Copies Real Media files from `/data2/mitstorage` into the working directory. More HTML files are grepped through, and it appears the media files being sought are files that were downloaded above, and now are just being moved into another directory~~. *This step is scheduled to be removed. It does not appear that there are any more of these files.*
11. Creates some symlinks, removes unused media files, and removes temporary files.
12. Rsyncs the contents of the working directory to `/data2/rsync`.

It appears that `/data2/rsync` is the source from which an OCW employee builds the removable media drive.
