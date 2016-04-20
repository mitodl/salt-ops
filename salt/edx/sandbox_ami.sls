# This plan deploys sets up a full edX sandbox by installing and running
# ansible on the target host.

test_command:
  salt.function:
    - name: test.ping
