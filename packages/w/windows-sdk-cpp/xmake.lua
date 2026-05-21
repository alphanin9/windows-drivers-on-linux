package("windows-sdk-cpp")
    set_homepage("https://www.nuget.org/packages/Microsoft.Windows.SDK.CPP")
    set_description("Windows SDK C++ NuGet headers needed by WDK kernel headers")
    set_license("Microsoft SDK License")

    local nugetver = "10.0.26100.4204"
    local sdkver = "10.0.26100.0"

    -- NuGet flat-container URLs are content-addressed by package id and version.
    -- Xmake extracts by the local filename extension, so store the NuGet
    -- .nupkg payload as a .zip in the package cache.
    add_urls("https://api.nuget.org/v3-flatcontainer/microsoft.windows.sdk.cpp/$(version)/microsoft.windows.sdk.cpp.$(version).nupkg", {filename = "windows-sdk-cpp.zip"})
    add_versions(nugetver, "0653aa3dab7fc269fa8f3da0493d6bbddbfd79ab83ab94837c2f209a584596eb")

    -- Layout assumption for 10.0.26100.4204:
    --   c/Include/10.0.26100.0/shared
    -- WDK km headers include shared SDK headers such as ntdef.h, guiddef.h,
    -- specstrings.h, and packing headers. The raw-driver pipeline does not use
    -- SDK tools, UM libraries, or the arch-specific SDK C++ library package.
    on_install(function (package)
        os.cp("*", package:installdir())

        -- The SDK archive is authored for Windows' case-insensitive filesystem.
        -- WDK headers include <DriverSpecs.h>, while the SDK archive stores
        -- driverspecs.h. Keep the workaround local to the package cache.
        local shared = path.join(package:installdir(), "c", "Include", sdkver, "shared")
        if os.isfile(path.join(shared, "driverspecs.h")) and not os.isfile(path.join(shared, "DriverSpecs.h")) then
            os.cp(path.join(shared, "driverspecs.h"), path.join(shared, "DriverSpecs.h"))
        end
    end)

    on_test(function (package)
        local shared = path.join(package:installdir(), "c", "Include", sdkver, "shared")
        assert(os.isfile(path.join(shared, "ntdef.h")))
        assert(os.isfile(path.join(shared, "specstrings.h")))
        assert(os.isfile(path.join(shared, "DriverSpecs.h")))
    end)
package_end()
