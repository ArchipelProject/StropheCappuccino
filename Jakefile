/*
 * Jakefile
 *
 * Copyright (C) 2010  Antoine Mercadal <antoine.mercadal@inframonde.eu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3.0 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

require("./common.jake")

var ENV = require("system").env,
    FILE = require("file"),
	OS = require("os"),
	JAKE = require("jake"),
    task = JAKE.task,
    CLEAN = require("jake/clean").CLEAN,
    FileList = JAKE.FileList,
    stream = require("narwhal/term").stream,
    framework = require("cappuccino/jake").framework,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Release";

$DOCUMENTATION_BUILD = FILE.join("Build", "Documentation");

framework ("StropheCappuccino", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "StropheCappuccino.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("StropheCappuccino");
    task.setIdentifier("org.archipelproject.strophecappuccino");
    task.setVersion("1.0");
    task.setAuthor("Antoine Mercadal");
    task.setEmail("antoine.mercadal @nospam@ inframonde.eu");
    task.setSummary("StropheCappuccino");
    task.setSources(new FileList("*.j", "MUC/*.j", "PubSub/*.j"));
    task.setResources(new FileList("Resources/*"));
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task("build", ["StropheCappuccino"]);

task("debug", ["build-strophe-debug"], function()
{
    ENV["CONFIG"] = "Debug"
    JAKE.subjake(["."], "build", ENV);
});

task("release", ["build-strophe-release"], function()
{
    ENV["CONFIG"] = "Release"
    JAKE.subjake(["."], "build", ENV);
});

task ("documentation", function()
{
    // try to find a doxygen executable in the PATH;
    var doxygen = executableExists("doxygen");

    // If the Doxygen application is installed on Mac OS X, use that
    if (!doxygen && executableExists("mdfind"))
    {
        var p = OS.popen(["mdfind", "kMDItemContentType == 'com.apple.application-bundle' && kMDItemCFBundleIdentifier == 'org.doxygen'"]);
        if (p.wait() === 0)
        {
            var doxygenApps = p.stdout.read().split("\n");
            if (doxygenApps[0])
                doxygen = FILE.join(doxygenApps[0], "Contents/Resources/doxygen");
        }
    }

    if (doxygen && FILE.exists(doxygen))
    {
        stream.print("\0green(Using " + doxygen + " for doxygen binary.\0)");

        var documentationDir = FILE.join("Doxygen");

        if (OS.system([FILE.join(documentationDir, "make_headers.sh")]))
            OS.exit(1); //rake abort if ($? != 0)

        if (!OS.system([doxygen, FILE.join(documentationDir, "StropheCappuccino.doxygen")]))
        {
            rm_rf($DOCUMENTATION_BUILD);
            // mv("debug.txt", FILE.join("Documentation", "debug.txt"));
            mv("Documentation", $DOCUMENTATION_BUILD);
        }

        OS.system(["ruby", FILE.join(documentationDir, "cleanup_headers")]);
    }
    else
        stream.print("\0yellow(Doxygen not installed, skipping documentation generation.\0)");
});

task("test", function()
{
    var tests = new FileList('Test/*Test.j');
    var cmd = ["ojtest"].concat(tests.items());
    var cmdString = cmd.map(OS.enquote).join(" ");
    
    var code = OS.system(cmdString);
    if (code !== 0)
        OS.exit(code);
});

task("build-strophe", function()
{
    var cmdString = "cd strophejs && make normal && mv strophe.js ../ && cd ../";
    var code = OS.system(cmdString);
    if (code !== 0)
        OS.exit(code);
});

task("build-strophe-release", ["build-strophe"], function()
{
    var miniInput   = FILE.read(FILE.join("strophe.js"), { charset:"UTF-8" });
    var minified    = require("minify/shrinksafe").compress(miniInput, { charset : "UTF-8", useServer : true });
    FILE.path("Resources/Strophe").absolute().join("strophe.js").write(minified, { charset : "UTF-8" });
});

task("build-strophe-debug", ["build-strophe"], function()
{
    var cmdString = "mv strophe.js Resources/Strophe/strophe.js";
    var code = OS.system(cmdString);
    if (code !== 0)
       OS.exit(code);
});

task ("default", ["release"]);
task ("docs", ["documentation"]);
task ("all", ["release", "debug", "documentation"]);
