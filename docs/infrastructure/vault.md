# Automated End to End Deployment of Vault

By leveraging several pieces of SaltStack and its ability to be extended we have managed to create a workflow that will allow for deploying a fully functional, highly available [Vault](https://www.vaultproject.io/) cluster from scratch in a fully automated manner. After the cluster is bootstrapped the salt master will be able to communicate with an unsealed Vault instance to read and write secrets without any manual intervention. The only manual portion of the process is to unseal the additional nodes for fail-over purposes, although there is the capacity to make this part automated as well.

## Background
Vault is a project from [Hashicorp](https://www.hashicorp.com/) for centralized, secure and auditable secrets management. This is useful from an operational context because it removes the need for tracking sensitive information in source control or using cobbled together solutions. Vault can provide a single location to store and generate passwords, API keys, SSL certificates, etc. While the installation and configuration of Vault is fairly painless, the difficulty arises in bringing a newly deployed Vault instance or cluster to a point where there is an authenticated client that can read or write data.

The reason that an end-to-end setup is difficult is due to the fact that before a Vault node can be used it needs to be [initialized and unsealed](https://www.vaultproject.io/intro/getting-started/deploy.html). To do this in a fully automated manner while maintaining an appropriate level of security is non-trivial. To make this possible some custom integration work was needed. The relevant pieces that were required are contained in the following locations:
- https://github.com/mitodl/hvac
- https://github.com/mitodl/salt-extensions/blob/master/extensions/_modules/vault.py
- https://github.com/mitodl/salt-extensions/blob/master/extensions/_states/vault.py
- https://github.com/mitodl/vault-formula

## Workflow
The process by which a newly created instance or cluster can be brought under the control of a Salt master is as follows:

1. One or more server instances are provisioned (e.g. an EC2 node)
2. Vault (and, optionally, Consul) is installed to the server
3. Salt initializes (one of) the Vault instance(s)

This is the point at which the automated process is generally handed to an operator to complete the setup manually with unsealing the vault and provisioning authentication backends. In our setup the following steps can optionally be performed in a fully automated manner:

4. Unseal the initialized vault
5. (optional) Regenerate the sealing keys and encrypt them with the operators public GPG key(s)
6. Provision the EC2 authentication backend
7. Create a Vault policy with an appropriate level of access
8. Create an EC2 instance profile that links the policy with an appropriate subset of the data needed to identify a salt master (e.g. IAM instance profile and AWS account number)
9. Authenticate the salt master against the Vault server using the generated EC2 instance profile as the credentials
10. Write the returned client token to a configuration file on the master instance for both minion and master for future use when interacting with Vault.

## How It Works
The execution module linked above wraps the HVAC python library so that it can be used in the context of a Salt process. Part of the wrapper instantiates a client instance which is then memoized such that is bound to the current execution context and gets reused for subsequent states. The state module uses this capability such that when the Vault instance is initialized the sealing tokens are maintained in memory. Once the vault is unsealed, if the function is passed a list of GPG public keys, the sealing keys are regenerated and encrypted with the provided keys. The newly generated and encrypted keys are backed up to Vault for later retrieval if needed as well as being provided in the return data from the salt run. Any subsequent state functions that are called within the same state run will maintain the root token in memory to enable provisioning and configuring additional backends, such as the EC2 authentication backend. Once the state run is completed the root token and sealing keys are no longer maintained in memory so subsequent interaction with the Vault requires a properly configured minion.

To configure a minion to communicate with Vault the following parameters can be set either via the minion config or pillar data:

```salt
vault.url: https://some.host.com:8200  # Required
vault.verify: False  # Optional - Whether to validate the TLS certificate used by the vault server
vault.token: yv2zS6UKCM+DtiroHcTmo/oYe9TKuw2PyLl1wK0RhC4=  # Required
vault.proxies: None  # Optional
vault.timeout: 30  # Optional
vault.allow_redirects: True  # Optional
vault.session: None  # Optional
```

## Why This Is Useful
This is useful for a number of reasons, not least of which is the ability to spin up a brand new operating environment with a robust secrets management capability from scratch. For our purposes, having an easily automatable deployment and configuration of Vault allows us to have:
- Internal PKI infrastructure:

  The Vault server can act as a CA and generate short-lived SSL certificates to minions for enabling encrypted peer communications in clustered services (e.g. MongoDB), certificate authentication (e.g. for FluentD secure_forward plugin), and certificate signing.

- Disposable Salt master:

  The master server can store the GPG key and SSH keys that it uses for decrypting data and bootstrapping minions in the Vault to be retrieved when it is first deployed. The Vault CA will also be used to sign the master key as it is provisioned. By distributing the public CA certificate to minions they can then verify that the signed master key can be trusted and accept it without requiring any manual intervention.

- Automatic credential generation:

  Vault can be used to generate new credentials for backends such as databases (e.g. MongoDB, MySQL, and PostGreSQL), AWS (e.g. IAM credentials) and SSH. By creating these credentials dynamically there is decreased risk of old passwords being leaked because they are never processed by a human.
