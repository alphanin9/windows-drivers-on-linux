package("windows-wdk-x64")
    set_homepage("https://www.nuget.org/packages/Microsoft.Windows.WDK.x64")
    set_description("Windows WDK x64 NuGet payload for Linux-hosted raw kernel-driver builds")
    set_license("Microsoft WDK License")

    local nugetver = "10.0.26100.4204"

    add_deps("windows-sdk-cpp " .. nugetver)

    -- NuGet flat-container URLs are content-addressed by package id and version.
    -- Xmake extracts by the local filename extension, so store the NuGet
    -- .nupkg payload as a .zip in the package cache.
    add_urls("https://api.nuget.org/v3-flatcontainer/microsoft.windows.wdk.x64/$(version)/microsoft.windows.wdk.x64.$(version).nupkg", {filename = "windows-wdk-x64.zip"})
    add_versions(nugetver, "829fcd80aff6850e72193d56ef5d9c59414c8aa32aa4cb366419b146f4b6cf6a")

    -- Layout assumption for 10.0.26100.4204:
    --   c/Include/10.0.26100.0/{km,shared,um}
    --   c/Lib/10.0.26100.0/km/x64
    --   c/Lib/10.0.26100.0/um/x64
    -- Keep these assumptions local to the package recipe so target rules remain
    -- stable if a future NuGet package moves the payload.
    local wdkver = "10.0.26100.0"

    on_install(function (package)
        import("utils.archive")

        local nupkgs = os.files("*.nupkg")
        if #nupkgs > 0 then
            local extracted = path.join(os.tmpdir(), "windows-wdk-x64-" .. package:version_str())
            os.tryrm(extracted)
            archive.extract(nupkgs[1], extracted)
            os.cp(path.join(extracted, "*"), package:installdir())
        else
            os.cp("*", package:installdir())
        end
    end)

    on_test(function (package)
        local root = package:installdir()
        assert(os.isfile(path.join(root, "c", "Include", wdkver, "km", "ntddk.h")))
        assert(os.isdir(path.join(root, "c", "Lib", wdkver, "km", "x64")))
    end)
package_end()
