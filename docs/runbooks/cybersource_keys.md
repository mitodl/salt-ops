# CyberSource
CyberSource is the payment processing and fraud management third party that the Institute uses for its online transactions. Additionally, CyberSource provides the ability to run OFAC checks for compliance which we leverage in our apps.

Currently, any requests for new keys or renewal of existing ones need to go through Peter as he is the one with an account to the CyberSource portal.

## Vault
Ideally, we should store all cybersource related values under the following vault path:
`secret-{{ business_unit }}/{{ environment }}/cybersource`

## CyberSource keys used

### CYBERSOURCE_ACCESS_KEY
32 character alphanumeric key referred to as an API key.

### CYBERSOURCE_INQUIRY_LOG_NACL_ENCRYPTION_KEY

This is a public key to encrypt export results with for our own security purposes. Generating the private and public key requires running the following python script:

```
from nacl.public import PrivateKey
from nacl.encoding import Base64Encoder

private_key = PrivateKey.generate()
public_key = private_key.public_key

print(Base64Encoder.encode(bytes(private_key)).decode("utf-8"))
print(Base64Encoder.encode(bytes(public_key)).decode("utf-8"))
```

Only the public key is required to be added to the config variables in the Heroku app, however you need to store both public and private keys in vault.

Required for compliance check.

### CYBERSOURCE_MERCHANT_ID
This key is specified when first creating the CyberSource application, example `mit_odl_xpro`

Required for compliance check

### CYBERSOURCE_PROFILE_ID
36 character alpahnumeric key (including hyphens)

### CYBERSOURCE_REFRENCE_PREFIX
A string prefix to identify the application in CyberSource transactions. Typically refers to environment, `rc-apps` or `production-apps`

### CYBERSOUCE_SECURE_ACCEPTANCE_URL
Two URLs are typically used here based on environment:
- CI/RC: `https://testsecureacceptance.cybersource.com/pay`
- Production: `https://secureacceptance.cybersource.com/pay`

### CYBERSOURCE_SECURITY_KEY
256 character long alphanumeric key.

### CYBERSOURCE_TRANSACTION_KEY
344 character long key referred to as a SOAP key.

Required for compliance check

### CYBERSOURCE_WSDL_URL
Two URLs are typically used here based on environment:
- CI/RC: `https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl`
- Production: `https://ics2wsa.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl`

Required for compliance check
