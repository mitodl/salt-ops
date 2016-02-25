def test_salt_contrib_installed(File):
    grains = File('/srv/salt/_grains')
    assert grains.exists
    assert grains.is_symlink
    contrib_repo = File('/etc/salt/contrib')
    assert contrib_repo.exists
    assert contrib_repo.is_directory
