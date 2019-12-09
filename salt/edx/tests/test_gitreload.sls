add_an_artificial_wait_for_gitreload:
  module.run:
    - name: test.sleep
    - length: 10
    - require_in:
        - testinfra: test_gitreload_is_running
        - testinfra: test_gitreload_is_listening

test_gitreload_is_running:
  testinfra.service:
    - name: gitreload
    - is_running: True

test_gitreload_is_listening:
  testinfra.socket:
    - name: 'tcp://0.0.0.0:8095'
    - is_listening: True
