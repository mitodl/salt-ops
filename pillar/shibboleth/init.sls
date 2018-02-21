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
    shibboleth2: |
      <?xml version="1.0" ?>
      <SPConfig clockSkew="180" xmlns="urn:mace:shibboleth:2.0:native:sp:config" xmlns:conf="urn:mace:shibboleth:2.0:native:sp:config" xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol">
       <RequestMapper type="Native">
        <RequestMap>
         <Host authType="shibboleth" name="{{ server_domain_name }}" requireSession="true">
          <Path name="secure"/>
         </Host>
        </RequestMap>
       </RequestMapper>
       <ApplicationDefaults REMOTE_USER="eppn persistent-id targeted-id" entityID="https://{{ server_domain_name }}/shibboleth">
        <Sessions checkAddress="false" cookieProps="https" handlerSSL="true" lifetime="28800" relayState="ss:mem" timeout="3600">
         <SSO discoveryProtocol="SAMLDS" discoveryURL="https://wayf.mit.edu/DS" text="SAML2 SAML1"/>
         <Logout>SAML2 Local</Logout>
         <Handler Location="/Metadata" signing="false" type="MetadataGenerator"/>
         <Handler Location="/Status" acl="127.0.0.1 ::1" type="Status"/>
         <Handler Location="/Session" showAttributeValues="false" type="Session"/>
         <Handler Location="/DiscoFeed" type="DiscoveryFeed"/>
        </Sessions>
        <Errors helpLocation="/about.html" styleSheet="/shibboleth-sp/main.css" supportContact="mitx-devops@mit.edu"/>
        <MetadataProvider backingFilePath="MIT-metadata.xml" reloadInterval="7200" type="XML" uri="http://touchstone.mit.edu/metadata/MIT-metadata.xml">
         <MetadataFilter maxValidityInterval="2419200" type="RequireValidUntil"/>
         <MetadataFilter certificate="inc-md-cert.pem" type="Signature"/>
         <MetadataFilter type="EntityRoleWhiteList">
          <RetainedRole>md:IDPSSODescriptor</RetainedRole>
          <RetainedRole>md:AttributeAuthorityDescriptor</RetainedRole>
         </MetadataFilter>
        </MetadataProvider>
        <AttributeResolver subjectMatch="true" type="Query"/>
        <AttributeFilter path="attribute-policy.xml" type="XML" validate="true"/>
        <AttributeExtractor path="attribute-map.xml" reloadChanges="false" type="XML" validate="true"/>
        <CredentialResolver certificate="sp-cert.pem" key="sp-key.pem" type="File"/>
       </ApplicationDefaults>
       <SecurityPolicyProvider path="security-policy.xml" type="XML" validate="true"/>
       <ProtocolProvider path="protocols.xml" reloadChanges="false" type="XML" validate="true"/>
      </SPConfig>
