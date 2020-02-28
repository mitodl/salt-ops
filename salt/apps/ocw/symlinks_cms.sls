
symlink_prod_new:
  file.symlink:
    - name: /prod_new
    - target: /mnt/ocwfileshare
    - force: True
    - user: root
    - group: root

symlink_prod:
  file.symlink:
    - name: /prod
    - target: /mnt/ocwfileshare
    - force: True
    - user: root
    - group: root

symlink_files_ocwfileshare:
  file.symlink:
    - name: /files/OCWFileShare
    - target: /mnt/ocwfileshare
    - force: True
    - makedirs: True
    - owner: root
    - group: root

symlink_files_qaengines:
  file.symlink:
    - name: /files/QAEngines
    - target: /mnt/ocwfileshare/OCWEngines
    - force: True
    - owner: root
    - group: root

symlink_ocwuser_ocwengines:
  file.symlink:
    - name: /home/ocwuser/OCWEngines
    - target: /mnt/ocwfileshare/OCWEngines
    - force: True
    - owner: ocwuser
    - group: ocwuser

symlink_ocwuser_generate_json_for_mobile:
  file.symlink:
    - name: /home/ocwuser/generate_json_for_mobile.sh
    - target: /mnt/ocwfileshare/OCWEngines/generate_json_for_mobile.sh
    - force: True
    - owner: ocwuser
    - group: ocwuser

symlink_ocwuser_generate_mitx_feeds:
  file.symlink:
    - name: /home/ocwuser/generate_mitx_feeds.sh
    - target: /mnt/ocwfileshare/OCWEngines/generate_mitx_feeds.sh
    - force: True
    - owner: ocwuser
    - group: ocwuser

symlink_ocwuser_generate_youtube_videos_tab:
  file.symlink:
    - name: /home/ocwuser/generate_youtube_videos_tab.sh
    - target: /mnt/ocwfileshare/OCWEngines/generate_youtube_videos_tab.sh
    - force: True
    - owner: ocwuser
    - group: ocwuser

symlink_run_aka_scripts:
  file.symlink:
    - name: /home/ocwuser/prod-scripts/run_aka_scripts.sh
    - target: /mnt/ocwfileshare/OCWEngines/run_aka_scripts.sh
    - force: True
    - owner: ocwuser
    - group: ocwuser
    - makedirs: True

ensure_state_of_mitx_archived_xml_dir:
  file.directory:
    - name: /mnt/ocwfileshare/mitx_archived_xml
    - user: ocwuser
    - group: ocwuser
    - dir_mode: 0755

symlink_mitx_archived_xml:
  file.symlink:
    - name: /usr/local/mitx_archived_xml
    - target: /mnt/ocwfileshare/mitx_archived_xml
    - force: True
    - owner: root
    - group: root

ensure_state_of_applications_dir:
    file.directory:
        - name: /mnt/ocwfileshare/Applications
        - user: plone
        - group: plone
        - dir_mode: 0755
