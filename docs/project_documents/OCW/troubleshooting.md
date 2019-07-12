# Open CourseWare

[Table of Contents](index.md)

## Troubleshooting

### Logs

Log messages for Zope events, engines, and webserver access and errors are all shipped to our Elasticsearch logging cluster and are visible in Kibana at <https://logs.odl.mit.edu/>.

You can filter on the `logstash-ocw-*` index pattern to make queries a little more efficient.

Useful FluentD tag values to filter your queries (as `fluentd_tag`):

* `ocwcms.engine`
* `ocwcms.zope.event`
* `ocwcms.apache.access`
* `ocwcms.apache.error`
* `ocwcms.zope.access`
* `ocworigin.nginx.access`
* `ocworigin.nginx.error`
* `ocwdb.zope.log`

The [mirror engine](engines_mirror.md) executes scripts on the mirror server itself, which put their output into multiple working directories and log directories under `/data2`. These are not shipped to the logging cluster yet and have to be viewed manually.


### `invalid literal for int()` errors from Zope / Plone

This may have been solved since we tuned our memory parameters in the Zope configuration files, but it is worth mentioning it here, in case it resurfaces.

The CMS used to stop responding from time to time, and we would notice error messages partly stating, "invalid literal for int()" in Zope's `event.log`. The solution in these cases was always to restart Zope, which would bring everything back to normal. Because doing so freed up a significant chunk of memory, and freed up some disk space in Zope's `blobstorage` cache on the CMS server, we deduced that this error had something to do with memory or cache overconsumption (though system available memory was seldom used up).

[The Zope documentation's section about the Zope configuration file](https://zope.readthedocs.io/en/latest/operation.html#zope-configuration-reference) describes two `cache-size` parameters which were probably causing the issue because they had not been tuned properly, since the time they existed on the legacy servers. The `cache-size` parameter for `zodb_db` represents the maximum number of objects to be cached, whereas the `cache-size` parameter within each `zeoclient` section represents an amount of memory to allocate. Zope's documentation does not provide any insight into how these values interact, but it appears they were set too high in the past. The `zodb_db` numbers were 2,000,000 -- two million objects in the cache  -- and the `zeoclient` numbers were 15GB. 15 Gigabytes is probably more memory than Python 2.4 can address, and it's also possible that two million objects' worth of cache was more than Python 2.4 could handle.

If you ever see `invalid literal for int()` errors in Zope's `event.log`, consider adjusting these `cache-size` values.

See also: a commit to parameterize these in `salt-ops`: <https://github.com/mitodl/salt-ops/commit/38a9e2d09a73526d68a42750bd9fcd2f0895d744>. Use Salt's `grains.set` module on the Salt master to adjust the grains, and then run the `cms_plone.sls` Salt state, if you need to adjust them.