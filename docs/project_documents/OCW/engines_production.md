# Open CourseWare

[Table of Contents](index.md) >
[Publishing Engines](engines.md)

## Production Publishing Process

As mentioned in [the Overview section](engines.md), [enginescheduler.py](https://github.com/mitocw/ocwcms/blob/12b86a45ec537c07fd8dd25c0aa06fec8089f9d9/publishing/enginescheduler.py) monitors the publication task queue. When it finds a Production task, it executes `python engines.py PRODUCTION`. (See [engines.py](https://github.com/mitocw/ocwcms/blob/12b86a45ec537c07fd8dd25c0aa06fec8089f9d9/publishing/engines.py))

The following lengthy outline is just a **summary** of the events that occur when `engines.py` finds a task in the queue.

1. `enginescheduler.py:36` (`python engines.py PRODUCTION`)
2. `engines.py:168` (`ProductionEngine.run()` extends `Engine.run()`)
3. `engines.py:28` get scheduled tasks from the MySQL database.  For each task ...
    1. `engines.py:32` (`tasks.PublishToStagingTask.execute()`)
        1. `tasks.py:108`: load RSS feeds & load json files **OR** load packageslips
            1. `publishing.packageslip.load_rssfeeds()` (wrapper around `_load_rss_feeds_information()`):
                1. gets packageslip XML file from staging server
                2. gets list of RSS feeds from that XML
                3. appends list of RSS feeds to `tasks.Task.rss_feed_list` property
            2. `publishing.packageslip.load_jsonfiles()`:
                1. gets packageslip XML file from staging server (again)
                2. gets list of JSON files from that XML
                3. appends list of JSON files to `tasks.Task.json_file_list` property
        2. `tasks.py:114`  if the task has JSON files, downloaad JSON files from CMS (not staging server)
        3. `tasks.PublishToProductionTask.process_content()` (`tasks.py:431`)
            1. publish RSS feeds and JSON files to production, if applicable
            2. **OR** ...
                1. publish files to production from staging, **for each related resource**:
                    1. download file from staging server
                    2. delete files and directories from relevant directory on production origin server
                    3. copy file to production origin server
                    4. copy `packageslip.xml` file to production origin server
                    5. copy course JSON file to production origin server
                2. append `/files/QAEngines/export_urls.txt` with files that were published. A [cron job](cron_jobs.md) will eventually run `export_courses_json.sh`, which will read this text file and use it to generate a JSON file for the course and upload it to an S3 bucket.
                3. publish to mirror server (`publishing.mirror.publish_to_mirror()`):
                    1. delete files from mirror server
                    2. copy files to mirror server, either from CMS or from the staging server, depending on whether the resource is a course or department
                    3. copy JSON file to mirror server
                4. publish ZIP file to S3 bucket, if this Task is for a course or supplemental resource (`tasks.py:445`)
                5. publish to DSpace holding area, if this Task is for a course or supplemental resource (`tasks.py:448`)
                6. publish RSS feeds to production origin if this Task is not for a course
4. Go through the dependent module tasks added above and do `tasks.Task.execute()` (above) for each of them.
