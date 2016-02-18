/**
 * Copyright: Copyright Jason White, 2016
 * License:   MIT
 * Authors:   Jason White
 *
 * Description:
 * Does nothing except run the child process. No dependencies are detected. This
 * is useful for tools where we don't want to detect dependencies (e.g., the
 * build system itself).
 */
module deps.tools.fallthrough;

import deps.logger;

int fallthrough(DepsLogger logger, string[] args)
{
    version (Posix)
    {
        import core.sys.posix.unistd;
        import std.string : toStringz;
        import core.stdc.stdio : stderr, fprintf;
        import core.stdc.string : strerror;
        import core.stdc.errno : errno;

        auto argv = new const(char)*[args.length+1];
        foreach (i; 0 .. args.length)
            argv[i] = toStringz(args[i]);
        argv[$-1] = null;

        execvp(argv[0], argv.ptr);

        // execvp does not exit unless an error occurs.
        fprintf(stderr, "bbdeps: Failed executing process '%s' (%s)\n",
                argv[0], strerror(errno));

        return 1;
    }
    else
    {
        import std.process : wait, spawnProcess;
        return wait(spawnProcess(traceArgs));
    }
}
