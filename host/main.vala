/*
 * Copyright ⓒ 2020 Sergei A. Trusov <sergei.a.trusov@ya.ru>
 *
 * The code is loosely based on the Plasma Browser Integration plugin host.
 * https://invent.kde.org/plasma/plasma-browser-integration/host

   Copyright (C) 2017 by Kai Uwe Broulik <kde@privat.broulik.de>
   Copyright (C) 2017 by David Edmundson <davidedmundson@kde.org>

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
*/

const string host_version_string = version_string + "-GLib";


// Log.writer_journald() journals just everithing.
// To filter out a lot of debug events we partially simulate ducumented
// behaviour of g_log_writer_default() with G_MESSAGES_DEBUG,
// checking if this environment variable is not set to 'all'.
//
// Please note that original msgHandler() sends its output to the browser.
LogWriterOutput log_writer(LogLevelFlags ll, LogField[] msg)
{
    if (ll == LogLevelFlags.LEVEL_DEBUG || ll == LogLevelFlags.LEVEL_INFO) {
        var allowed = Environment.get_variable("G_MESSAGES_DEBUG");
        if (allowed == null || allowed != "all")
            return LogWriterOutput.HANDLED;
    }
    if (Log.writer_journald(ll, msg) == LogWriterOutput.HANDLED)
        return LogWriterOutput.HANDLED;
    return Log.writer_standard_streams(ll, msg);
}


int main(string[] args)
{
    Log.set_writer_func(log_writer);

    PluginManager.add_plugin(new Settings());
    PluginManager.add_plugin(new Mpris());

    new MainLoop().run();

    return 0;
}




