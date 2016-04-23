/**
 * Copyright: Copyright Jason White, 2016
 * License:   MIT
 * Authors:   Jason White
 *
 * Description:
 * Standalone tool that wraps various programs to efficiently capture their
 * inputs and outputs. The lists of inputs and outputs are then sent to the
 * build system, if any.
 *
 * TODO: Add option to override the tool.
 */
module deps.app;

import std.algorithm : sort;

import deps.logger;
import deps.tools;

import io;

alias Tool = int function(DepsLogger, string[]);

immutable Tool[string] tools;
shared static this()
{
    /**
     * List of tools.
     */
    tools = [
        "bb":     &passthrough,
        "bbdeps": &passthrough,
        "bblua":  &passthrough,
        "dmd":    &dmd,
    ];
}

version (unittest)
{
    // Dummy main for unit testing.
    void main() {}
}
else
{
    immutable usage = "Usage: bbdeps [--json FILE] -- program [arg...]";

    int main(string[] args)
    {
        import std.range : SortedRange;
        import std.range : popFront, empty, front;

        args.popFront();

        string json;

        if (!args.empty && args.front == "--json")
        {
            args.popFront();
            if (args.empty)
            {
                stderr.println(usage);
                stderr.println("Error: Expected string for option '--json'");
                return 1;
            }

            json = args.front;
            args.popFront();
        }

        if (!args.empty && args.front == "--")
            args.popFront();

        if (args.empty)
        {
            stderr.println(usage);
            return 1;
        }

        auto tool = args.front in tools;

        // Early exit to avoid constructing the logger.
        if (tool !is null && *tool == &passthrough)
            return passthrough(null, args);

        DepsLogger logger;

        if (json !is null)
            logger = new JSONLogger(File(json, FileFlags.writeEmpty));
        else
            logger = new BrilliantBuildLogger();

        scope (success)
            logger.finish();

        if (tool is null)
            return trace(logger, args);

        return (*tool)(logger, args);
    }
}
