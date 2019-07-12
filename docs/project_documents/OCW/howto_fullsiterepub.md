# Open CourseWare

[Table of Contents](index.md) > [HOWTO](howto.md)

## How to Perform a Full-Site Republish

A full-site republish is a series of actions that cause all of the site's content to be published again to the origin webservers. It is performed in cases where some kind of global change has to be made to the site's resources; for example, when there is some template or configuration change that means that the HTML meta tags throughout the site need to be updated.

First all of the site's content is published to staging, and then all of the site's content is published to production, where the publish to production basically takes the files from staging and sends them to production. So one normally performs both in sequence.

Content maintainers should be told not to edit content in the CMS while a full-site republish is running.

The whole process takes a number of days to complete.

For each step in the process, a Python script within the Zope management console is run. (This is a Python script that is stored inside the Zope database. It does not exist on the filesystem.) The script generates text output that is a series of MySQL SQL stored procedure calls. This output is copied and pasted or saved and transferred to a file, which is subsequently fed into a `mysql` command to execute the statements. The statements cause a number of [staging or production publication tasks](engines.md) to be enqueued by adding records to the MySQL database table (`publication_task_queue`), which the engine scripts query.

After the tasks are enqueued, the appropriate staging or production engine is run in <https://ocwcms.mit.edu/manage-engines>.

In cach of the steps below, the script is `SiteRepub`. Access it by opening <https://ocwcms.mit.edu/manage> in your browser and navigating to it in the main window.

### Step 1: The Staging Publish

Choose the "Edit" tab of `SiteRepub` and change the script as follows:

1. Ensure that the following line is _uncommented_: `if stateLower in ('staged','submitted_for_fqa','published_in_production'):`
2. Ensure that the following line _is_ commented: `#if stateLower in ('published_in_production'):`
3. Ensure that the following line is _uncommnented_: `message = "CALL schedule_implicit_module ('" + url + "', 1, 'SYSTEM', '');"`
4. Ensure that the following line _is_ commented: `#message = "CALL schedule_implicit_module ('" + url + "', 3, 'SYSTEM', '');"`

For _each_ of the lines in:

```
results = catalog.searchResults({'meta_type':('Course','SupplementalResource')})
#results = catalog.searchResults({'meta_type':('GlobalModule')})
#results = catalog.searchResults({'meta_type':('Department')})
#results = catalog.searchResults({'meta_type':('HFHModule','HFHCourse')})
```

1. Uncomment only that one line, and ensure that the others are commented.
2. Click on the "Test" tab at the top of the `SiteRepub` frame. This runs the script. There will be a delay for the run that generates statements for course pages.
3. Copy and paste, or save, the contents of the frame to a SQL script file and run it in the MySQL database from somewhere that has access to that database, such as the `ocw-production-cms-db2` `ocw-qa-cms-db2` database server (depending on the case, obviously).
4. Observe in the `manage-engines` control panel (e.g. <https://ocwcms.mit.edu/manage-engines>) that tasks have been added.
5. Run the tasks.
6. Wait. And wait ... The courses take the most time, a number of days in our experience.

The staging publish takes longer than the production publish ...

When everything is published to staging, this is everyone's change to give it a final QA check beofore sending it to the production site.

### Step 2: The Production Publish

Choose the "Edit" tab of `SiteRepub` and change the script as follows:

1. Ensure that the following line is _uncommented_: `if stateLower in ('published_in_production'):`
2. Ensure that the following line _is_ commented: `#if stateLower in ('staged','submitted_for_fqa','published_in_production'):`
3. Ensure that the following line is _uncommented_: `message = "CALL schedule_implicit_module ('" + url + "', 3, 'SYSTEM', '');"`
4. Ensure that the following line _is_ commented: `#message = "CALL schedule_implicit_module ('" + url + "', 1, 'SYSTEM', '');"`

For _each_ of the lines in:

```
results = catalog.searchResults({'meta_type':('Course','SupplementalResource')})
#results = catalog.searchResults({'meta_type':('GlobalModule')})
#results = catalog.searchResults({'meta_type':('Department')})
#results = catalog.searchResults({'meta_type':('HFHModule','HFHCourse')})
```

Perform the steps of the "For each of the lines" part in "The Staging Publish," above. (Uncomment one line each time and run the script to generate the SQL, etc.)

The production run takes less time than the staging one because it's mostly just copying files that it had to work harder to generate in the staging step.

### Step 3: Clear the Akamai cache

Someone who has access to Akamai's support personnel contacts them and asks for the CDN's cache to be cleared, at which point the republished content is live.

