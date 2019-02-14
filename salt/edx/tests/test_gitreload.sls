test_gitreload_is_running:
  testinfra.service:
    - name: gitreload
    - is_running: True

test_gitreload_is_listening:
  testinfra.socket:
    - name: 'tcp://0.0.0.0:8095'
    - is_listening: True
