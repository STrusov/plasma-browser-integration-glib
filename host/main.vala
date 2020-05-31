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

const string host_version_string = "0.10-GLib";

int main(string[] args)
{
    Log.set_writer_func(Log.writer_journald);

    PluginManager.add_plugin(new Settings());
    PluginManager.add_plugin(new Mpris());

    new MainLoop().run();

    return 0;
}



