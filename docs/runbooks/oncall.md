# Table of Contents

* [Style Guide](#style-guide)
* [XQueueWatcher](#xqueuewatcher)
 
# Introduction

This document is meant to be one stop shopping for your MIT OL Devops oncall needs.

Please update this doc as you handle incidents whenever you're oncall.

## Style Guide

There should be a table of contents at the top of the document with links to
each product heading. Your editor likely has a plugin to make this automatic.

Each product gets its own top level heading.

Entries that are keyed to a specific alert should have the relevant text in a
second level heading under the product. Boil the alert down to the most relevant
searchable text and omit specifics that will vary. For instance:

```
"[Prometheus]: [FIRING:1] DiskUsageWarning mitx-production (xqwatcher filesystem /dev/root ext4 ip-10-7-0-78 integrations/linux_hos"
```
would boil down to `DiskUsageWarning xqwatcher` because the rest will change and
make finding the right entry more difficult.

Each entry should have at least two sections, Diagnosis and Mitigation. Use
_bold face_ for the section title.
This will allow the oncall to get only as much Diagnosis in as required to
identify the issue and focus on putting out the fire.

# Products

## XQueueWatcher

### DiskUsageWarning xqwatcher

_Diagnosis_

This happens every few months if the xqueue watcher nodes hang around for that
long. 

_Mitigation_

```
From salt-pr master: 

sudo ssh -i /etc/salt/keys/aws/salt-production.pem ubuntu@10.7.0.78
sudo su -

root@ip-10-7-0-78:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        20G   16G  3.9G  81% /           <<<<<<<<<<<<<<<<<<<<<<<<<< offending filesystem
devtmpfs        1.9G     0  1.9G   0% /dev
tmpfs           1.9G  560K  1.9G   1% /dev/shm
tmpfs           389M  836K  389M   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           1.9G     0  1.9G   0% /sys/fs/cgroup
/dev/loop1       56M   56M     0 100% /snap/core18/2751
/dev/loop2       25M   25M     0 100% /snap/amazon-ssm-agent/6312
/dev/loop0       25M   25M     0 100% /snap/amazon-ssm-agent/6563
/dev/loop3       54M   54M     0 100% /snap/snapd/19361
/dev/loop4       64M   64M     0 100% /snap/core20/1950
/dev/loop6       56M   56M     0 100% /snap/core18/2785
/dev/loop5       54M   54M     0 100% /snap/snapd/19457
/dev/loop7       92M   92M     0 100% /snap/lxd/24061
/dev/loop8       92M   92M     0 100% /snap/lxd/23991
/dev/loop10      64M   64M     0 100% /snap/core20/1974
tmpfs           389M     0  389M   0% /run/user/1000

root@ip-10-7-0-78:~# cd /edx/var           <<<<<<<<<<<<<<<<<<< intuition / memory

root@ip-10-7-0-78:/edx/var# du -h | sort -hr | head
8.8G	.
8.7G	./log
8.2G	./log/xqwatcher         <<<<<<<<<<<< Offender 
546M	./log/supervisor
8.0K	./supervisor
4.0K	./xqwatcher
4.0K	./log/aws
4.0K	./aws
root@ip-10-7-0-78:/edx/var# cd log/xqwatcher/
root@ip-10-7-0-78:/edx/var/log/xqwatcher# ls -tlrha
total 8.2G
drwxr-xr-x 2 www-data xqwatcher 4.0K Mar 11 08:35 .
drwxr-xr-x 5 syslog   syslog    4.0K Jul 14 00:00 ..
-rw-r--r-- 1 www-data www-data  8.2G Jul 14 14:12 xqwatcher.log             <<<<<<<<< big file

root@ip-10-7-0-78:/edx/var/log/xqwatcher# rm xqwatcher.log

root@ip-10-7-0-78:/edx/var/log/xqwatcher# systemctl restart supervisor.service
Job for supervisor.service failed because the control process exited with error code.
See "systemctl status supervisor.service" and "journalctl -xe" for details.
root@ip-10-7-0-78:/edx/var/log/xqwatcher# systemctl restart supervisor.service       <<<<<<<<<<<<  Restart it twice because ???

root@ip-10-7-0-78:/edx/var/log/xqwatcher# systemctl status supervisor.service
● supervisor.service - supervisord - Supervisor process control system
     Loaded: loaded (/etc/systemd/system/supervisor.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2023-07-14 14:12:51 UTC; 4min 48s ago
       Docs: http://supervisord.org
    Process: 1114385 ExecStart=/edx/app/supervisor/venvs/supervisor/bin/supervisord --configuration /edx/app/supervisor/supervisord.conf (code=exited, status=0/SUCCESS)
   Main PID: 1114387 (supervisord)
      Tasks: 12 (limit: 4656)
     Memory: 485.8M
     CGroup: /system.slice/supervisor.service
             ├─1114387 /edx/app/supervisor/venvs/supervisor/bin/python /edx/app/supervisor/venvs/supervisor/bin/supervisord --configuration /edx/app/supervisor/supervisord.conf
             └─1114388 /edx/app/xqwatcher/venvs/xqwatcher/bin/python -m xqueue_watcher -d /edx/app/xqwatcher

root@ip-10-7-0-78:/edx/var/log/xqwatcher# ls -lthra
total 644K
drwxr-xr-x 5 syslog   syslog    4.0K Jul 14 00:00 ..
drwxr-xr-x 2 www-data xqwatcher 4.0K Jul 14 14:12 .
-rw-r--r-- 1 www-data www-data  636K Jul 14 14:17 xqwatcher.log                <<<<<<<< New file being written to
root@ip-10-7-0-78:/edx/var/log/xqwatcher# df -h .
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        20G  7.4G   12G  38%                  <<<<<<<<<<< acceptable utilization
```

