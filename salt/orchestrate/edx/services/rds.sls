create_edx_rds_db_subnet_group:
  boto_rds.subnet_group_present:
    - name: edx_db_subnet_group-mitx-qa
    - subnet_names:
        - private_db_subnet-mitx-qa
    - tags:
        Name: edx_db_subnet_group-mitx-qa

create_edx_rds_store:
  boto_rds.present:
    - name: edx_db-mitx-qa
    - allocated_storage: 100
    - db_instance_class: db.t2.medium
    - master_username: {{ salt.pillar.get('rds:mitx_qa:master_username', 'admin') }}
    - master_user_password: {{ salt.pillar.get('rds:mitx_qa:master_password', 'Th!s1sN0tS3cure') }}
    - vpc_security_group_ids:
        - {{ salt.boto_secgroup.get_group_id('rds-mitx_qa') }}
        - {{ salt.boto_secgroup.get_group_id('default', vpc_name='MITx QA') }}
    - db_subnet_group_name: edx_db_subnet_group-mitx-qa
    - tags:
        Name: edx_db-mitx-qa
    - require:
        - bot_rds: create_edx_rds_db_subnet_group
