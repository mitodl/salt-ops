Sometimes an error will crop up where a user is unable to enroll in a course. This is generally due to duplicate roles
being created during the course creation. To solve the issue, replicate the following session on the affected
environment:

```
sudo su - edxapp -s /bin/bash
source edxapp_env
cd edx-platform
python manage.py lms shell --settings=aws
>>> from opaque_keys.edx.locator import CourseLocator
>>> from django_comment_common.models import Role
>>> course = CourseLocator.from_string('MITx/6.041r_3/2016_Spring')
>>> roles = Role.objects.filter(course_id=course)
>>> roles
[<Role: Administrator for MITx/6.041r_3/2016_Spring>, <Role: Moderator for MITx/6.041r_3/2016_Spring>, <Role: Community TA for MITx/6.041r_3/2016_Spring>, <Role: Student for MITx/6.041r_3/2016_Spring>, <Role: Administrator for MITx/6.041r_3/2016_Spring>, <Role: Moderator for MITx/6.041r_3/2016_Spring>, <Role: Community TA for MITx/6.041r_3/2016_Spring>, <Role: Student for MITx/6.041r_3/2016_Spring>]
>>> dup = roles[4:]
>>> dup
[<Role: Administrator for MITx/6.041r_3/2016_Spring>, <Role: Moderator for MITx/6.041r_3/2016_Spring>, <Role: Community TA for MITx/6.041r_3/2016_Spring>, <Role: Student for MITx/6.041r_3/2016_Spring>]
>>> for r in dup:
... r.delete()
...
>>>
```
