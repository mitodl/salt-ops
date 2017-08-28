#!/bin/sh
#
# Use this pre-commit hook to fix up OLX that is exported from edX without any run information
#
# It assumes that there is a commit already in the repo with a comment of the form:
#
#     initial commit of course.xml with term "{run name}"
#
# The script extracts the run from the commit message and then uses it to fix up all the places that need it

# find the course term
commit_msg=$(git log -1 --grep='initial commit of course.xml with term' --oneline)
run=$(echo $commit_msg| cut -d'"' -f 2)
# abort if we can't find the run
if [ -z $run ]
then
    echo "could not find run. proceed with commit"
    exit 0
else
    echo "Course run is $run"
fi

# update the /course.xml
if [ -e course.xml ]
then
    echo "replacing url_name in course.xml"
    sed -i "s/url_name=\"course\"/url_name=\"$run\"/" course.xml
    git add course.xml
fi

# mv /course/course.xml
if [ -e course/course.xml ]
then
    echo "git mv course/course.xml course/$run.xml"
    git mv -f course/course.xml course/$run.xml
fi

# edit polices/course/policy.json
if [ -e policies/course/policy.json ]
then
    echo "changing course key in policy.json"
    sed -i "s+\"course/course\":+\"course/$run\":+" policies/course/policy.json
    git add policies/course/policy.json
fi

# move /policies/course/
if [ -d policies/course/ ]
then
    echo "git mv policies/course/ policies/$run/"
    git rm -r policies/$run
    git mv -f policies/course/ policies/$run
fi

exit 0
