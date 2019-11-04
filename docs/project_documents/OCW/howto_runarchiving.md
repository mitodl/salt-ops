# Open CourseWare

[Table of Contents](index.md) > [HOWTO](howto.md)

## How to Run the Archiving Engine

The [engine server](engines.md)'s engines.py script must be run manally as the `ocwuser` user to perform the archiving process, as follows:

```
python engines.py 3
```

In this case, `3` is the code for the Archiving engine.

Note that there is no "run" button for the Archiving engine in <https://ocwcms.mit.edu/manage-engines> as there is for other engines. It is not clear why this is the case.
