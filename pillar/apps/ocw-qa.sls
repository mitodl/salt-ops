
{% set dbhost_ipaddr_data =
     salt.saltutil.runner('mine.get',
                          tgt='G@roles:ocw-db and G@ocw-environment:qa',
                          fun='network.ip_addrs',
                          tgt_type='compound')
%}
{# The "db2" database host is always the MySQL one, per our naming convention. #}
{% set dbhost_ipaddr = dbhost_ipaddr_data['ocw-qa-cms-db2'][0] %}

mine_functions:
  network.ip_addrs: [eth0]

ocw:
  engines_conf:
    # database is the MySQL database, not Zope database.
    database:
      host: "{{ dbhost_ipaddr }}"
    cms:
      url: https://ocw-qa-cms-1.odl.mit.edu
      host: ocw-qa-cms1
      engine_host: ocw-qa-cms2
    staging:
      url: https://ocw-qa-ocw2.odl.mit.edu
      host: ocw-qa-ocw2.odl.mit.edu
      user: fsuser
    production:
      url: https://ocw-qa-origin.odl.mit.edu
      host: ocw-qa-origin
    mirror:
      url: not provisioned
      host: not provisioned
      user: none
    netstorage:
      host: ocw-qa-netstorage.odl.mit.edu
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
      dspace_host_port: 80
      dspace_endpoint_prefix: http://dome-test.mit.edu/sword/deposit/
      deposit_uri_lookup_file_name: UAT_DepositURILookup.xml
    # production_dspace_conf is for Production_Dspace_conf in engines.conf.jinja
    production_dspace_conf:
      dspace_host_id: dspace.mit.edu
      dspace_host_port: 80
      dspace_endpoint_prefix: http://dspace.mit.edu/sword/deposit/
      deposit_uri_lookup_file_name: DepositURILookup.xml
  zope_conf:
    base_site_url: https:///ocw-qa-origin.odl.mit.edu
    base_staging_site_url: https://ocw-qa-ocw2.odl.mit.edu
