create_mitca_pem_file:
  file.managed:
    - name: /etc/ssl/certs/mitca.pem
    - contents_pillar: mitca:pem_contents

make_openssl_allow_1024_bit_ca_key:
  file.replace:
    - name: /etc/ssl/openssl.cnf
    - pattern: CipherString=DEFAULT@SECLEVEL=2
    - repl: CipherString=DEFAULT@SECLEVEL=1
