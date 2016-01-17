[buildbadge]: https://travis-ci.org/jasonwhite/bbdeps.svg?branch=master
[buildstatus]: https://travis-ci.org/jasonwhite/bbdeps

# Implicit Dependency Detection [![Build Status][buildbadge]][buildstatus]

[Brilliant Build]: https://github.com/jasonwhite/brilliant-build

A tool that wraps commands in order to figure out file dependencies in an ad-hoc
manner. If running under [Brilliant Build][], dependencies are reported to the
parent build system.

## Example

Suppose we have a D source file `foo.d`:
```d
module foo;
import bar;
```
and a source file `bar.d`:
```d
module bar;
import baz;
```

Note that `foo.d` imports `bar.d` and `bar.d` imports `baz.d`.

In order to compile `foo.d`, we run:

    bbdeps dmd -c foo.d

Here, `bbdeps` will use some tricks to figure out the transitive closure of
dependencies that `dmd -c foo.d` has. In this case, `bbdeps` will report
`foo.d`, `bar.d`, and `baz.d` as dependencies to Brilliant Build.

## Building it

 1. Get the dependencies:

     * [A D compiler][DMD]. Only DMD is ensured to work.
     * [DUB][]: A package manager for D.

 2. Get the source:

    ```bash
    git clone https://github.com/jasonwhite/bbdeps.git
    ```

 3. Build it:

    ```bash
    dub build
    ```

## License

[MIT License](/LICENSE.md)
