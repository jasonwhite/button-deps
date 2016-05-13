/**
 * Copyright: Copyright Jason White, 2016
 * License:   MIT
 * Authors:   Jason White
 *
 * Description:
 * Command line argument parsing helper.
 */
module deps.tools.args;

class ArgParseException : Exception
{
    this(string msg, string file=__FILE__, size_t line=__LINE__) pure
    {
        super(msg, file, line);
    }
}
