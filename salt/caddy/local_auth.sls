#!pyobjects
import json
from uuid import uuid4
from datetime import datetime

caddy_users = {
  "revision": 1,
  "users": []
}
for user in salt.pillar.get('caddy:auth:local_users', []):
    caddy_users['users'].append({
        'id': str(uuid4()),
        'username': user['username'],
        'email_addresses': [
            {
                'address': user['email']
            }
        ],
        'passwords': [
            {
                'purpose': 'generic',
                'type': 'bcrypt',
                'hash': user['password_hash'],
                'cost': 10,
                'expired_at': "0001-01-01T00:00:00Z",
                'disabled_at': "0001-01-01T00:00:00Z",
                'created_at': datetime.utcnow().isoformat() + 'Z'
            }
        ],
        'created': datetime.utcnow().isoformat() + 'Z',
        'last_modified': datetime.utcnow().isoformat() + 'Z',
        'roles': [{'name': role} for role in user['roles']]
    })

File.managed(
    'create_caddy_local_auth_database_file',
    name='/var/lib/caddy/auth/users.json',
    contents=json.dumps(caddy_users, indent=2, sort_keys=True),
    user='caddy',
    group='caddy',
    makedirs=True,
    recurse=['user', 'group']
)
