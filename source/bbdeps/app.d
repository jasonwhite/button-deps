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
static import deps.tools;

import io;

alias Tool = int function(DepsLogger, string[]);

immutable Tool[string] tools;
shared static this()
{
    /**
     * List of tools.
     */
    tools = [
        "dmd": &deps.tools.dmd.dmd,
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

        DepsLogger logger;

        if (json !is null)
            logger = new JSONLogger(File(json, FileFlags.writeEmpty));
        else
            logger = new BrilliantBuildLogger();

        scope (success)
            logger.finish();

        auto tool = args.front in tools;

        if (tool is null)
            return deps.tools.fallback.fallback(logger, args);

        return (*tool)(logger, args);
    }
}
