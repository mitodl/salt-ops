
{% set dbhost_ipaddr_data =
     salt.saltutil.runner('mine.get',
                          tgt='G@roles:ocw-db and G@ocw-environment:production',
                          fun='network.ip_addrs',
                          tgt_type='compound')
%}
{# The "db2" database host is always the MySQL one, per our naming convention. #}
{% set mysql_db_ipaddr = dbhost_ipaddr_data['ocw-production-cms-db2'][0] %}
{% set zodb_ipaddr = dbhost_ipaddr_data['ocw-production-cms-db1'][0] %}

mine_functions:
  network.ip_addrs: [eth0]

ocw:
  ocwcms_git_ref: master
  engines_conf:
    # database is the MySQL database, not Zope database.
    database:
      host: "{{ mysql_db_ipaddr }}"
    cms:
      url: https://ocw-production-cms-2.odl.mit.edu
      host: ocw-production-cms-2
      engine_host: ocw-production-cms-2
      engine_url: https://ocw-production-cms-2.odl.mit.edu
    staging:
      url: https://ocw-production-ocw2.odl.mit.edu
      host: ocw-production-ocw2.odl.mit.edu
      user: fsuser
    production:
      url: https://ocw-origin.odl.mit.edu
      host: ocw-origin-ocw-0
    mirror:
      url: http://ocw-rsync.odl.mit.edu/
      host: ocw-production-rsync
    netstorage:
      host: ocwzip.upload.akamai.com
      user: sshacs
      rootdirectory: /15436/ZipForEndUsers
      zipurlprefix: /ans15436/ZipForEndUsers
    dspace:
      retiredcourseziproot: /mnt/ocwfileshare/OCWEngines/RetiredCourseZips
      # current_environment's value matches the header in the engines.conf
      # template file.
      current_environment: Production_Dspace_conf
    # test_dspace_conf is for Test_Dspace_conf in engines.conf.jinja
    test_dspace_conf:
      dspace_host_id: dome-test.mit.edu
      dspace_host_port: 443
      dspace_endpoint_prefix: https://dome-test.mit.edu/sword/deposit/
      deposit_uri_lookup_file_name: UAT_DepositURILookup.xml
    # production_dspace_conf is for Production_Dspace_conf in engines.conf.jinja
    production_dspace_conf:
      dspace_host_id: dspace.mit.edu
      dspace_host_port: 443
      dspace_endpoint_prefix: https://dspace.mit.edu/sword/deposit/
      deposit_uri_lookup_file_name: DepositURILookup.xml
  zope_conf:
    base_site_url: https://ocw.mit.edu
    base_staging_site_url: http://ocw2.mit.edu
    zodb_ipaddr: "{{ zodb_ipaddr }}"
  mirror:
    host_aliases:
      - ['ocw.mit.edu', '10.100.0.9']
      - ['ocwcms.mit.edu', '10.100.0.54']
      - ['ocwpcms2.mit.edu', '10.100.0.24']
