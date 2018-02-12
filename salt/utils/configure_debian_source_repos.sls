ensure_debian_source_repo_is_present:
  pkgrepo.managed:
    - name: deb-src http://cloudfront.debian.net/debian {{ salt.grains.get('oscodename', 'stretch') }} main
