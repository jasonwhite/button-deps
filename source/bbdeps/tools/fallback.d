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

import io.file;
import deps.logger;

version (Posix)
{

private struct Strace
{
    /**
     * Bookkeeping struct for individual processes.
     */
    private struct ProcessState
    {
        string cwd;
    }

    /**
     * Paths that start with these fragments are ignored.
     */
    private static immutable ignoredPaths = [
        "/dev/",
        "/etc/",
        "/proc/",
        "/tmp/",
        "/usr/",
    ];

    /**
     * Returns: True if the given path should be ignored, false otherwise.
     */
    private static bool ignorePath(const(char)[] path) pure nothrow
    {
        import std.algorithm.searching : startsWith;

        foreach (ignored; ignoredPaths)
        {
            if (path.startsWith(ignored))
                return true;
        }

        return false;
    }

    private
    {
        import std.array : Appender;

        DepsLogger logger;
        ProcessState[int] processes;

        Appender!(string[]) inputs, outputs;
    }

    this(DepsLogger logger)
    {
        this.logger = logger;

        inputs = Appender!(string[])();
        outputs = Appender!(string[])();
    }

    ~this()
    {
        foreach (input; inputs.data)
            logger.addInput(input);

        foreach (output; outputs.data)
            logger.addOutput(output);
    }

    void parse(File f)
    {
        import io.text;
        import std.conv : parse, ConvException;
        import std.string : munch;
        import std.algorithm.searching : startsWith;
        import std.regex : regex, matchFirst;

        auto re_open   = regex(`open\("([^"]*)", ([^,)]*)`);
        auto re_creat  = regex(`creat\("([^"]*)",`);
        auto re_rename = regex(`rename\("([^"]*)", "([^"]*)"\)`);
        auto re_mkdir  = regex(`mkdir\("([^"]*)", (0[0-7]*)\)`);

        foreach (line; f.byLine)
        {
            int pid;

            try
                pid = line.parse!int();
            catch (ConvException e)
                continue;

            line.munch(" \t");

            if (line.startsWith("open"))
            {
                auto captures = line.matchFirst(re_open);
                if (captures.empty)
                    continue;

                open(pid, captures[1], captures[2]);
            }
            else if (line.startsWith("creat"))
            {
                auto captures = line.matchFirst(re_open);
                if (captures.empty)
                    continue;

                creat(pid, captures[1]);
            }
            else if (line.startsWith("rename"))
            {
                auto captures = line.matchFirst(re_rename);
                if (captures.empty)
                    continue;

                rename(pid, captures[1], captures[2]);
            }
            else if (line.startsWith("mkdir"))
            {
                auto captures = line.matchFirst(re_mkdir);
                if (captures.empty)
                    continue;

                mkdir(pid, captures[1]);
            }
        }
    }

    void open(int pid, const(char)[] path, const(char)[] flags)
    {
        import std.algorithm.iteration : splitter;

        if (ignorePath(path))
            return;

        foreach (mode; splitter(flags, '|'))
        {
            if (mode == "O_WRONLY" || mode == "O_RDWR")
            {
                // Opened in write mode. It's an input.
                logger.addOutput(path.idup);
                break;
            }
            else if (mode == "O_RDONLY")
            {
                // Opened in read-only mode. It's an input.
                logger.addInput(path.idup);
                break;
            }
        }
    }

    void creat(int pid, const(char)[] path)
    {
        if (ignorePath(path))
            return;

        logger.addOutput(path.idup);
    }

    void rename(int pid, const(char)[] from, const(char)[] to)
    {
        if (ignorePath(to))
            return;

        logger.addOutput(to.idup);
    }

    void mkdir(int pid, const(char)[] dir)
    {
        logger.addOutput(dir.idup);
    }
}

int fallback(DepsLogger logger, string[] args)
{
    import std.string : toStringz;
    import std.file : remove;
    import std.process : wait, spawnProcess, ProcessException;

    auto traceLog = tempFile(AutoDelete.no).path;
    scope (exit) remove(traceLog);

    auto traceArgs = [
        "strace",

        // Follow child processes
        "-f",

        // Output to a file to avoid mixing the child's output
        "-o", traceLog,

        // Only trace the sys calls we are interested in
        "-e", "trace=open,rename",
        ] ~ args;

    try
    {
        auto exitCode = wait(spawnProcess(traceArgs));

        if (exitCode != 0)
        {
            // If the command failed, don't bother trying to figure out implicit
            // dependencies. They will be ignored by the build system anyway.
            return exitCode;
        }

        // Parse the trace log to determine dependencies
        auto strace = Strace(logger);
        strace.parse(File(traceLog));
    }
    catch (ProcessException e)
    {
        // We don't have strace. Fallback to just running without it.
        return wait(spawnProcess(args));
    }

    return 0;
}

}
