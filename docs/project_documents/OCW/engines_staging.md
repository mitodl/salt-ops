# Open CourseWare

[Table of Contents](index.md) >
[Publishing Engines](engines.md)

## Staging Publishing Process

As mentioned in [the Overview section](engines.md), [enginescheduler.py](https://github.com/mitocw/ocwcms/blob/12b86a45ec537c07fd8dd25c0aa06fec8089f9d9/publishing/enginescheduler.py) monitors the publication task queue. When it finds a Staging task, it executes `python engines.py STAGING`. (See [engines.py](https://github.com/mitocw/ocwcms/blob/12b86a45ec537c07fd8dd25c0aa06fec8089f9d9/publishing/engines.py))

The following lengthy outline is just a **summary** of the events that occur when `engines.py` finds a task in the queue.

1. `enginescheduler.py:36` (`python engines.py STAGING`)
2. `engines.py:168` (`StagingEngine.run()` extends `Engine.run()`)
3. `engines.py:28` get scheduled tasks from the MySQL database.  **For each task ...**
    1. `engines.py:32` (`tasks.PublishToStagingTask.execute()`)
        1. `tasks.py:108`  load RSS feeds & load json files OR load packageslips
            1. `publishing.packageslip.load_rssfeeds()` (wrapper around `_load_rss_feeds_information()`):
                1. gets packageslip XML file from CMS
                2. gets list of rss feeds from that XML
                3. appends list of rss feeds to `tasks.Task.rss_feed_list property`
            2. `publishing.packageslip.load_jsonfiles()` (wrapper around `_load_json_files_information()`):
                1. gets packageslip XML file from CMS (again)
                2. gets list of JSON files from that XML
                3. appends list of JSON files to `tasks.Task.json_file_list` property
            3. `publishing.packageslip.load_packageslips()`:
                1. assigns various properties of the Task: `zip_required`, `hasJSON`, `module_type`, `module_short_id`, `department_code`, `resource_list`
                2. `packageslip._load_rss_feeds_information()`:
                    * like `load_rssfeeds()` (above), appends list of RSS feeds to `rss_feed_list` property of the Task
                3. `packageslip._load_dependent_module_information()`:
                    * loads dependend module info from packageslip XML into dependent_modules property of the Task
                4. `packageslip._linked_course_information()`:
                    * loads linked department IDs (not courses) from packageslip XML into `linked_dept_ids` property of the Task
                5. `packageslip._load_target_packageslip()` (where "target" means the origin server):
                    1. loads packageslip file from staging origin server and parses it
                    2. appends list of resources from that XML to the `target_resource_list` attribute of the Task.
                    3. this will be used later to figure out which resources to delete from the origin server
    2. `tasks.py:114`  if the task has JSON files, downloaad JSON files from CMS
    3. `tasks.PublishToStagingTask.process_content()` (`tasks.py:381`)
        1. publish JSON files to staging, if applicable
        2. **OR** publish pages
            1. publish to download holding area if the resource is a course, supplemental resource, or `/terms`
            2. publish to mirror holding area
            3. publish to DSpace holding area if the resource is a course, supplemental resource, or `/terms`
            4. publish to staging origin server
                1. `production.publish_to_staging()`
                    1. `tasks.Task.publish_to_web()`  (`tasks.py:205`)
                        1. download each resource in the Tasks's resource_list from the CMS, to the engine server
                            * This causes queries on the Zope database as well as the 3Play API for resources that have videos with transcripts. The 3Play API is probably a significant bottleneck.
                        2. delete each resource from the staging origin server
                        3. copy all of the downloaded resources to the staging origin server
                        4. request `packageslip.xml` from CMS and SCP it to the staging origin server. (packageslip file records all related resources, like PDF documents, related courses). `<course URL>/packageslip.xml`
                        5. request JSON view of the page and SCP it to the staging origin server. (high-level data about the course, small file.) `<course URL>/index.json`
        3. schedule dependent tasks if the published resource is in `/courses` or `/resources`. (Presumably updating a course index, for example, if a course is being published.)
4. Go through the dependent module tasks added above and do `tasks.Task.execute()` (above) for each of them.
