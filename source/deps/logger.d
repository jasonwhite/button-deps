/**
 * Copyright: Copyright Jason White, 2016
 * License:   MIT
 * Authors:   Jason White
 *
 * Description:
 * Logs dependencies.
 */
module deps.logger;

import std.json;

import io.stream : writeExactly;
import io.file.stream : File, FileFlags;

/**
 * Format for dependencies received from a task over a pipe.
 */
align(4) struct Dependency
{
    /**
     * Timestamp of the resource. If unknown, this should be set to 0. In such a
     * case, the parent build system will compute the value when needed. This is
     * used by the parent build system to determine if the checksum needs to be
     * recomputed.
     *
     * For files and directories, this is its last modification time.
     */
    ulong timestamp;

    /**
     * SHA-256 checksum of the contents of the resource. If unknown or not
     * computed, this should be set to 0. In such a case, the parent build
     * system will compute the value when needed.
     *
     * For files, this is the checksum of the file contents. For directories,
     * this is the checksum of the paths in the sorted directory listing.
     */
    ubyte[32] checksum;

    /**
     * Length of the name.
     */
    uint length;

    /**
     * Name of the resource that can be used to lookup the data. Length is given
     * by the length member.
     *
     * This is usually a file or directory path. The path do not need to be
     * normalized. If a relative path, the build system assumes it is relative
     * to the working directory that the child was spawned in.
     */
    char[0] name;
}

interface DepsLogger
{
    void addInput(string path);
    void addOutput(string path);
    void finish();

    final void addInputs(const(string)[] paths)
    {
        foreach (path; paths)
            addInput(path);
    }

    final void addOutputs(const(string)[] paths)
    {
        foreach (path; paths)
            addOutput(path);
    }
}

/**
 * Outputs dependencies to files.
 */
class JSONLogger : DepsLogger
{
    private
    {
        File file;
        JSONValue root;
    }

    this(File file)
    {
        this.file = file;
        this.root = JSONValue([
            "inputs": cast(string[])[],
            "outputs": cast(string[])[]
        ]);
    }

    void finish()
    {
        file.writeExactly(root.toPrettyString());
    }

    void addInput(string path)
    {
        synchronized
        {
            root["inputs"].array ~= JSONValue(path);
        }
    }

    void addOutput(string path)
    {
        synchronized
        {
            root["outputs"].array ~= JSONValue(path);
        }
    }
}

/**
 * Outputs dependencies for Button.
 */
class ButtonLogger : DepsLogger
{
    private
    {
        File inputs, outputs;
    }

    this()
    {
        import std.process : environment;
        import std.conv : to;

        if (auto inputs = environment.get("BUTTON_INPUTS"))
            this.inputs = File(inputs.to!int);

        if (auto outputs = environment.get("BUTTON_OUTPUTS"))
            this.outputs = File(outputs.to!int);
    }

    void addInput(string path)
    {
        import std.conv : to;

        if (!inputs.refCountedStore.isInitialized || !inputs.isOpen)
            return;

        immutable Dependency dep = {length: path.length.to!uint};

        synchronized
        {
            inputs.writeExactly(dep);
            inputs.writeExactly(path);
        }
    }

    void addOutput(string path)
    {
        import std.conv : to;

        if (!outputs.refCountedStore.isInitialized || !outputs.isOpen)
            return;

        immutable Dependency dep = {length: path.length.to!uint};

        synchronized
        {
            outputs.writeExactly(dep);
            outputs.writeExactly(path);
        }
    }

    void finish()
    {
    }
}
