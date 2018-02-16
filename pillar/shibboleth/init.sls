#!jinja|yamlex
# -*- mode: yaml -*-
{% import_yaml salt.cp.cache_file('salt://environment_settings.yml') as env_settings %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set server_domain_name = env_data.purposes['odl-video-service'].domain %}
nginx-shibboleth:
  overrides:
    conf_file: /etc/shibboleth/shibboleth2.xml
  config:
    shibboleth2:
      SPConfig:
        xmlns: 'urn:mace:shibboleth:2.0:native:sp:config'
        'xmlns:conf': 'urn:mace:shibboleth:2.0:native:sp:config'
        'xmlns:saml': 'urn:oasis:names:tc:SAML:2.0:assertion'
        'xmlns:samlp': 'urn:oasis:names:tc:SAML:2.0:protocol'
        'xmlns:md': 'urn:oasis:names:tc:SAML:2.0:metadata'
        clockSkew: 180
        RequestMapper:
          type: Native
          RequestMap:
            Host:
              name: {{ server_domain_name }}
              authType: shibboleth
              requireSession: 'true'
              Path:
                name: secure
        ApplicationDefaults:
          entityID: {{ server_domain_name }}
          REMOTE_USER: "eppn persistent-id targeted-id"
          Sessions:
            lifetime: 28800
            timeout: 3600
            relayState: 'ss:mem'
            checkAddress: 'false'
            handlerSSL: 'true'
            cookieProps: https
            SSO:
              discoveryProtocol: SAMLDS
              discoveryURL: "https://wayf.mit.edu/DS"
              text: SAML2 SAML1
            Logout:
              - SAML2 Local
            Handler:
              - type: MetadataGenerator
                Location: /Metadata
                signing: 'false'
              - type: Status
                Location: /Status
                acl: "127.0.0.1 ::1"
              - type: Session
                Location: /Session
                showAttributeValues: 'false'
              - type: DiscoveryFeed
                Location: /DiscoFeed
          Errors:
            supportContact: mitx-devops@mit.edu
            helpLocation: /about.html
            styleSheet: /shibboleth-sp/main.css
          MetadataProvider:
            type: XML
            uri: 'http://touchstone.mit.edu/metadata/MIT-metadata.xml'
            backingFilePath: MIT-metadata.xml
            reloadInterval: 7200
            MetadataFilter:
              - type: RequireValidUntil
                maxValidityInterval: 2419200
              - type: Signature
                certificate: inc-md-cert.pem
              - type: EntityRoleWhiteList
                RetainedRole:
                  - md:IDPSSODescriptor
                  - md:AttributeAuthorityDescriptor
          AttributeExtractor:
            type: XML
            validate: "true"
            reloadChanges: "false"
            path: attribute-map.xml
          AttributeResolver:
            type: Query
            subjectMatch: "true"
          AttributeFilter:
            type: XML
            validate: "true"
            path: attribute-policy.xml
          CredentialResolver:
            type: File
            key: sp-key.pem
            certificate: sp-cert.pem
        SecurityPolicyProvider:
          type: XML
          validate: "true"
          path: security-policy.xml
        ProtocolProvider:
          type: XML
          validate: "true"
          reloadChanges: "false"
          path: protocols.xml
