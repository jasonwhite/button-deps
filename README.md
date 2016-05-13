[buildbadge]: https://travis-ci.org/jasonwhite/button-deps.svg?branch=master
[buildstatus]: https://travis-ci.org/jasonwhite/button-deps

# Implicit Dependency Detection [![Build Status][buildbadge]][buildstatus]

[Button]: https://github.com/jasonwhite/button

A tool that wraps commands in order to figure out file dependencies in an ad hoc
manner. If running under [Button][], dependencies are reported to the
parent build system. Dependencies can also be output in JSON format for
integration with other tools.

## Examples

### D

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

    button-deps dmd -c foo.d

Here, `button-deps` will use some tricks to figure out the transitive closure of
dependencies that `dmd -c foo.d` has. In this case, `button-deps` will report
`foo.d`, `bar.d`, and `baz.d` as dependencies.

### General

For tools that are not yet fully supported or cannot be supported, `strace` is
used to determine dependencies by analysing how files are opened. While slower
than ad hoc support for other tools, `strace` provides accurate dependency
tracking.

For example, suppose we have a shell script `test.sh`:

```bash
cat foo
echo "Hello world!" > bar
cp bar baz
```

If we run this shell script, like so:

    $ button-deps bash test.sh

`test.sh` and `foo` will be reported as inputs, while `bar` and `baz` will be
reported as outputs.

## Building it

 1. Get the dependencies:

     * [DMD][]. The standard D compiler.
     * [DUB][]: A package manager for D.

 2. Get the source:

    ```bash
    git clone https://github.com/jasonwhite/button-deps.git
    ```

 3. Build it:

    ```bash
    dub build
    ```

[DMD]: http://dlang.org/download.html
[DUB]: http://code.dlang.org/download

## License

[MIT License](/LICENSE.md)
