add_brightbox_ruby_ppa:
  pkgrepo.managed:
    - name: brightbox-ruby
    - humanname: BrightBox Ruby PPA
    - ppa: brightbox/ruby-ng

install_ruby_deps:
  pkg.installed:
    - pkgs:
        - ruby2.4.1
        - ruby2.4.1-dev
        - build-essential
    - update: True
    - require:
        - pkgrepo: add_brightbox_ruby_ppa