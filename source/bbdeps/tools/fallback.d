/**
 * Copyright: Copyright Jason White, 2016
 * License:   MIT
 * Authors:   Jason White
 *
 * Description:
 * The fallback for what to do when no other tool can handle dependency
 * detection.
 */
module deps.tools.fallback;

version (Posix)
int fallback(string[] args)
{
    import core.sys.posix.unistd;
    import core.sys.posix.stdio : perror;
    import std.string : toStringz;

    // Convert D command argument list to a null-terminated argument list.
    auto argv = new const(char)*[args.length+1];
    foreach (i; 0 .. args.length)
        argv[i] = toStringz(args[i]);
    argv[$-1] = null;

    execvp(argv[0], argv.ptr);
    perror("execvp");

    return 1;
}
