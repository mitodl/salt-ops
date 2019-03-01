create_mitca_pem_file:
  file.managed:
    - name: /etc/ssl/certs/mitca.pem
    - contents_pillar: mitca:pem_contents
