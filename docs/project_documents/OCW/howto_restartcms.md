# Open CourseWare

[Table of Contents](index.md) > [HOWTO](howto.md)

## How to Restart the CMS

Restarting the CMS, on each of the CMS servers:

```
$ sudo /usr/local/Plone/zeocluster/bin/client1 restart
```

... or, better yet, on the salt master:

```
$ sudo salt ocw-production-cms-[12] cmd.run '/usr/local/Plone/zeocluster/bin/client1 restart'
```
