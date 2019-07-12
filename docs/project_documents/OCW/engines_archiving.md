# Open CourseWare

[Table of Contents](index.md) >
[Publishing Engines](engines.md)

## Archiving Process

When old versions of courses are removed from the OCW site, their contents are zipped up and uploaded to MIT's DSpace repository before being deleted from the staging and production webservers and being disabled for modification in the CMS.

When they are uploaded to DSpace, the Archiving engine receives a handle.net URI for the course, and associates that with the archived course. Current versions of the course maintain a reference to the archived course, and provide links to the DSpace archive of the old course, as well as the handle URI.

A course is first scheduled for retirement in the CMS. (The exact process for doing this is outside the scope of this document, but involves setting some flags on the course's page and scheduling it for archiving in <https://ocwcms.mit.edu/archivingagent>.

The [engine server](engines.md)'s engines.py script is then [run manally](howto_runarchiving.md) to perform the archiving process.

There is no "run" button for the Archiving engine in <https://ocwcms.mit.edu/manage-engines> as there is for other engines. It is not clear why this is the case.

The following outline is a summary of the events that occur when `engines.py` is run.

1. `engines.py:25` (`engines.RetirementEngine` extends `engines.Engine` and does not override `run()`.
    1. `engines.py:28` gets scheduled tasks from the MySQL database. For each task ...
        1. `engines.py:32` (`tasks.RetireToDSpaceTask.execute()`)
	        1. `tasks.py:489` (`tasks.RetireToDSpaceTask.process_content()`) calls `archiving.publish_to_dspace()` on the task (`archiving.py:138`)
               1. For each of the resources in the course, download XML metadata files fro the CMS to the "DSpace holding area," if necessary, and then make a Zip file of the course. Copy that Zip file to a subdirectory of the "retired course zips" directory (currently `/mnt/ocwfileshare/OCWEngines/RetiredCourseZips`).
               2. call `archiving._dspace_course_submission()` (`archiving.py:210`) on the Task. This uploads the Zip file to the DSpace server and receives an XML response, which includes the `handle.net` URI that will be associated with the archived course.
               3. at `archiving.py:182`, `publish_to_dspace()` executes `utils.callSetHandleScript()` (`utils.py:292`), which does not run a script, but makes an HTTP request to the `set_dspace_handle` view of the course in the CMS. This request, with its `dspace_handle` querystring parameter, assigns the extracted handle.net URI from the step above to the course. For example: `/courses/history/21h-126-america-in-depression-and-war-spring-2003/set_dspace_handle?__ac_name=<CMS username>&__ac_password=<CMS password>&dspace_handle=hdl://1721.1/77167`

The `RetireToDSpaceTask` class does not schedule any dependent tasks when its `execute()` method is called. It appears that the actual removal of the course from the site is governed by the managment console, perhaps when the course is put through the workflow states it goes through when it's scheduled for archiving. It does not look like any engine script removes the course. The engine code just handles the archiving to DSpace.
