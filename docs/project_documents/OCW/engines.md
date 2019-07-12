# Open CourseWare

[Table of Contents](index.md)

## Publishing Engines

1. [Staging Publishing Process](engines_staging.md)
1. [Production Publishing Process](engines_production.md)
1. [Archiving Process](engines_archiving.md)
1. [Mirror Drive Creation Process](engines_mirror.md)

### Overview

While the OCW site is a static site hosted on the "origin" HTTP servers, its content is edited and managed in the Plone CMS. When we want to publish the pages to the webservers or mirror server, we schedule jobs in the CMS's control panel. These jobs are run on the "CMS 2" or "engine" server by Python "engine" processes.

There is [a daemon named `enginescheduler.py`](https://github.com/mitocw/ocwcms/blob/12b86a45ec537c07fd8dd25c0aa06fec8089f9d9/publishing/enginescheduler.py) that runs on the `cms-2` server, continuously querying a job queue table named `publication_task_queue` in the MySQL database that runs on the `cms-db2` server. (See [Architecture Overview](architecture_overview.md) for diagrams.) When it sees a job record in that table, it runs a corresponding Python script for that job's task type, which often executes a series of other scripts.
