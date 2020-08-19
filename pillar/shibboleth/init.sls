# -*- mode: yaml -*-
{% set env_settings = salt.file.read(salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml"))|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set app_name = salt.grains.get('app') %}
{% set server_domain_names = env_data.purposes[app_name].domains %}

nginx-shibboleth:
  overrides:
    conf_file: /etc/shibboleth/shibboleth2.xml
  config:
    attribute-map: |
      <Attributes xmlns="urn:mace:shibboleth:2.0:attribute-map" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

        <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.6" id="eppn">
          <AttributeDecoder xsi:type="ScopedAttributeDecoder"/>
        </Attribute>
        <Attribute name="urn:mace:dir:attribute-def:eduPersonPrincipalName" id="eppn">
          <AttributeDecoder xsi:type="ScopedAttributeDecoder"/>
        </Attribute>

        <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.9" id="affiliation">
          <AttributeDecoder xsi:type="ScopedAttributeDecoder" caseSensitive="false"/>
        </Attribute>
        <Attribute name="urn:mace:dir:attribute-def:eduPersonScopedAffiliation" id="affiliation">
          <AttributeDecoder xsi:type="ScopedAttributeDecoder" caseSensitive="false"/>
        </Attribute>

        <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.1" id="unscoped-affiliation">
          <AttributeDecoder xsi:type="StringAttributeDecoder" caseSensitive="false"/>
        </Attribute>
        <Attribute name="urn:mace:dir:attribute-def:eduPersonAffiliation" id="unscoped-affiliation">
          <AttributeDecoder xsi:type="StringAttributeDecoder" caseSensitive="false"/>
        </Attribute>

        <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.7" id="entitlement"/>
        <Attribute name="urn:mace:dir:attribute-def:eduPersonEntitlement" id="entitlement"/>

        <Attribute name="urn:mace:dir:attribute-def:eduPersonTargetedID" id="targeted-id">
          <AttributeDecoder xsi:type="ScopedAttributeDecoder"/>
        </Attribute>

        <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.10" id="persistent-id">
          <AttributeDecoder xsi:type="NameIDAttributeDecoder" formatter="$NameQualifier!$SPNameQualifier!$Name" defaultQualifiers="true"/>
        </Attribute>

        <Attribute name="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent" id="persistent-id">
          <AttributeDecoder xsi:type="NameIDAttributeDecoder" formatter="$NameQualifier!$SPNameQualifier!$Name" defaultQualifiers="true"/>
        </Attribute>
        <Attribute name="urn:oid:2.5.4.3" id="cn"/>
        <Attribute name="urn:oid:2.5.4.4" id="sn"/>
        <Attribute name="urn:oid:2.5.4.42" id="givenName"/>
        <Attribute name="urn:oid:2.16.840.1.113730.3.1.241" id="displayName"/>
        <Attribute name="urn:oid:0.9.2342.19200300.100.1.1" id="uid"/>
        <Attribute name="urn:oid:0.9.2342.19200300.100.1.3" id="mail"/>
        <Attribute name="urn:oid:2.5.4.20" id="telephoneNumber"/>
        <Attribute name="urn:oid:2.5.4.12" id="title"/>
        <Attribute name="urn:oid:2.5.4.43" id="initials"/>
        <Attribute name="urn:oid:2.5.4.13" id="description"/>
        <Attribute name="urn:oid:2.16.840.1.113730.3.1.1" id="carLicense"/>
        <Attribute name="urn:oid:2.16.840.1.113730.3.1.2" id="departmentNumber"/>
        <Attribute name="urn:oid:2.16.840.1.113730.3.1.3" id="employeeNumber"/>
        <Attribute name="urn:oid:2.16.840.1.113730.3.1.4" id="employeeType"/>
        <Attribute name="urn:oid:2.16.840.1.113730.3.1.39" id="preferredLanguage"/>
        <Attribute name="urn:oid:0.9.2342.19200300.100.1.10" id="manager"/>
        <Attribute name="urn:oid:2.5.4.34" id="seeAlso"/>
        <Attribute name="urn:oid:2.5.4.23" id="facsimileTelephoneNumber"/>
        <Attribute name="urn:oid:2.5.4.9" id="street"/>
        <Attribute name="urn:oid:2.5.4.18" id="postOfficeBox"/>
        <Attribute name="urn:oid:2.5.4.17" id="postalCode"/>
        <Attribute name="urn:oid:2.5.4.8" id="st"/>
        <Attribute name="urn:oid:2.5.4.7" id="l"/>
        <Attribute name="urn:oid:2.5.4.10" id="o"/>
        <Attribute name="urn:oid:2.5.4.11" id="ou"/>
        <Attribute name="urn:oid:2.5.4.15" id="businessCategory"/>
        <Attribute name="urn:oid:2.5.4.19" id="physicalDeliveryOfficeName"/>

        <Attribute name="urn:mace:dir:attribute-def:cn" id="cn"/>
        <Attribute name="urn:mace:dir:attribute-def:sn" id="sn"/>
        <Attribute name="urn:mace:dir:attribute-def:givenName" id="givenName"/>
        <Attribute name="urn:mace:dir:attribute-def:displayName" id="displayName"/>
        <Attribute name="urn:mace:dir:attribute-def:uid" id="uid"/>
        <Attribute name="urn:mace:dir:attribute-def:mail" id="mail"/>
        <Attribute name="urn:mace:dir:attribute-def:telephoneNumber" id="telephoneNumber"/>
        <Attribute name="urn:mace:dir:attribute-def:title" id="title"/>
        <Attribute name="urn:mace:dir:attribute-def:initials" id="initials"/>
        <Attribute name="urn:mace:dir:attribute-def:description" id="description"/>
        <Attribute name="urn:mace:dir:attribute-def:carLicense" id="carLicense"/>
        <Attribute name="urn:mace:dir:attribute-def:departmentNumber" id="departmentNumber"/>
        <Attribute name="urn:mace:dir:attribute-def:employeeNumber" id="employeeNumber"/>
        <Attribute name="urn:mace:dir:attribute-def:employeeType" id="employeeType"/>
        <Attribute name="urn:mace:dir:attribute-def:preferredLanguage" id="preferredLanguage"/>
        <Attribute name="urn:mace:dir:attribute-def:manager" id="manager"/>
        <Attribute name="urn:mace:dir:attribute-def:seeAlso" id="seeAlso"/>
        <Attribute name="urn:mace:dir:attribute-def:facsimileTelephoneNumber" id="facsimileTelephoneNumber"/>
        <Attribute name="urn:mace:dir:attribute-def:street" id="street"/>
        <Attribute name="urn:mace:dir:attribute-def:postOfficeBox" id="postOfficeBox"/>
        <Attribute name="urn:mace:dir:attribute-def:postalCode" id="postalCode"/>
        <Attribute name="urn:mace:dir:attribute-def:st" id="st"/>
        <Attribute name="urn:mace:dir:attribute-def:l" id="l"/>
        <Attribute name="urn:mace:dir:attribute-def:o" id="o"/>
        <Attribute name="urn:mace:dir:attribute-def:ou" id="ou"/>
        <Attribute name="urn:mace:dir:attribute-def:businessCategory" id="businessCategory"/>
        <Attribute name="urn:mace:dir:attribute-def:physicalDeliveryOfficeName" id="physicalDeliveryOfficeName"/>

      </Attributes>
    shibboleth2: |
      <?xml version="1.0" ?>
      <SPConfig xmlns="urn:mace:shibboleth:2.0:native:sp:config"
                xmlns:conf="urn:mace:shibboleth:2.0:native:sp:config"
                xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                clockSkew="180">

        <RequestMapper type="Native">

          <RequestMap>
          {% for server_domain_name in server_domain_names %}
            <Host authType="shibboleth" name="{{ server_domain_name }}" requireSession="true"/>
          {% endfor %}
          </RequestMap>

        </RequestMapper>

        <ApplicationDefaults entityID="https://{{ server_domain_names[0] }}/shibboleth"
                             REMOTE_USER="eppn persistent-id targeted-id">

          <Sessions lifetime="28800" timeout="3600" relayState="ss:mem"
                    checkAddress="false" handlerSSL="true" cookieProps="https">

            <SSO discoveryProtocol="SAMLDS" discoveryURL="https://wayf.mit.edu/DS">
              SAML2 SAML1
            </SSO>

            <Logout>SAML2 Local</Logout>

            <Handler type="MetadataGenerator" Location="/Metadata" signing="false"/>

            <Handler type="Status" Location="/Status" acl="127.0.0.1 ::1"/>

            <Handler type="Session" Location="/Session" showAttributeValues="false"/>

            <Handler type="DiscoveryFeed" Location="/DiscoFeed"/>
          </Sessions>

          <Errors supportContact="odl-devops@mit.edu"
                  helpLocation="/about.html"
                  styleSheet="/shibboleth-sp/main.css"/>

          <MetadataProvider type="XML" uri="http://web.mit.edu/touchstone/shibboleth/config/metadata/MIT-metadata.xml"
                            backingFilePath="MIT-metadata.xml" reloadInterval="7200">
            <MetadataFilter type="EntityRoleWhiteList">
              <RetainedRole>md:IDPSSODescriptor</RetainedRole>
              <RetainedRole>md:AttributeAuthorityDescriptor</RetainedRole>
            </MetadataFilter>
          </MetadataProvider>

          <TrustEngine type="ExplicitKey" />

          <AttributeExtractor type="XML" validate="true" reloadChanges="false" path="attribute-map.xml"/>

          <AttributeResolver type="Query" subjectMatch="true"/>

          <AttributeFilter type="XML" validate="true" path="attribute-policy.xml"/>

          <CredentialResolver type="File" key="sp-key.pem" certificate="sp-cert.pem"/>

        </ApplicationDefaults>

        <SecurityPolicyProvider type="XML" validate="true" path="security-policy.xml"/>

        <ProtocolProvider type="XML" validate="true" reloadChanges="false" path="protocols.xml"/>

      </SPConfig>
