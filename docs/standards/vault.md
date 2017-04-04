## Key Paths
In order to be able to support multiple different applications and environments we need to be able to differentiate the credentials and data that are stored for each of those use cases. This is easy to manage for dynamically generated credentials for services such as PostGreSQL and RabbitMQ because they are associated with a specific instance of a backend. For static data it requires establishing a set of conventions for how and where it is stored. To that end, we have established the following standards for dealing with secrets stored in the generic secret backend mounts:

### Mount Points
We have a number of dimensions for our business requirements which necessitates a certain hierarchy of the data used for each use case. The first level of dimensionality is the `Business Unit` which can be thought of as the way in which finances should be allocated for the particular implementation. The high level business units that we are currently (tmacey 2017/03/28) dealing with are:

- Micromasters
- Residential MITx
- Technical Operations (DevOps)
- Professional Education
- Distance Education
- TechTV
- Open CourseWare
- StarTeam

The mountpoints for data that is specific to one of these use cases will be `secret-{{ business_unit }}/` and of type `generic`. For credentials that are non-specific to a given business unit there is a global `secret/` mount point.

### Key Paths
The next level of dimensionality below the business unit is the operational environment. Currently (tmacey 2017/03/28) we have:

- mitx-qa
- mitx-rp
- micromasters
- StarCell Bio (also seen as scb)
- operations

Sometimes a credential is applicable across environment boundaries, in which case the environment name should be `global`.

### Purpose (optional)
For some applications there is the notion of `purpose`, which is primarily relevant for edX deployments. This attribute designates the particular use case for a specific instance, such as the `current` released version for the `residential` business unit with the `live` configuration which is denoted as `current-residential-live`. The currently (tmacey 2017/03/28) defined purposes are:

- current-residential-live
- current-residential-draft
- next-residential-live
- next-residential-draft
- sandbox
- continuous-delivery
- residential-live
- professional-education
- micromasters

### Putting It All Together
Putting all of this together, a keypath can be templated as:

```
secret-{{ business_unit }}/{{ environment || global }}/{{ purpose? }}/{{ app_name }}-{{ key_name }}
```

## Data Conventions
In order to prevent confusion when accessing the data stored at these locations we should have an established convention for how the data is stored. In particular, when setting the values for a particular key path the command is of the form:

```
salt master vault.write secret/operations/salt-master-private-key {{ key }}={{ value }}
```

The name used for the `key` should always be `value` so that when rendering the data in a salt state or template it can be of the form:

```salt
state_id:
  file.managed:
    - name: foo.txt
    - context:
        foo_secret: {{ salt.vault.read('secret/operations/salt-master-private-key').data.value }}
```
