Sometimes an error will crop up where a user is unable to enroll in a course. This is generally due to duplicate roles
being created during the course creation. To solve the issue, replicate the following session on the affected
environment:

```bash
sudo su - edxapp -s /bin/bash
source edxapp_env
cd edx-platform
python manage.py lms shell --settings=aws
```

```python
>>> from opaque_keys.edx.locator import CourseLocator
>>> from django_comment_common.models import Role
>>> course = CourseLocator.from_string('course-v1:MITx+8.051r_1+2019_Spring')
>>> roles = Role.objects.filter(course_id=course)
>>> roles
[<Role: Administrator for MITx/6.041r_3/2016_Spring>, <Role: Moderator for MITx/6.041r_3/2016_Spring>, <Role: Community TA for MITx/6.041r_3/2016_Spring>, <Role: Student for MITx/6.041r_3/2016_Spring>, <Role: Administrator for MITx/6.041r_3/2016_Spring>, <Role: Moderator for MITx/6.041r_3/2016_Spring>, <Role: Community TA for MITx/6.041r_3/2016_Spring>, <Role: Student for MITx/6.041r_3/2016_Spring>]
>>> dup = roles[len(roles)/2:]
>>> dup
[<Role: Administrator for MITx/6.041r_3/2016_Spring>, <Role: Moderator for MITx/6.041r_3/2016_Spring>, <Role: Community TA for MITx/6.041r_3/2016_Spring>, <Role: Student for MITx/6.041r_3/2016_Spring>]
>>> for r in dup:
... r.delete()
...
>>>
```

More recent courses appear to have an extra role, so it is worth double checking the total number of roles before deleting them to ensure that you are only deleting the second half of the roles.

For copy-paste:
```python
coursename = ENTER_COURSE_NAME_HERE (e.g. course-v1:MITx+8.051r_1+2019_Spring)
from opaque_keys.edx.locator import CourseLocator
from django_comment_common.models import Role
course = CourseLocator.from_string(coursename)
roles = Role.objects.filter(course_id=course)
dup = roles[len(roles)/2:]
for r in dup:
    r.delete()
```
