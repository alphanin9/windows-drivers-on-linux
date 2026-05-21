package("windows-sdk-cpp-x64")
    set_homepage("https://www.nuget.org/packages/Microsoft.Windows.SDK.CPP.x64")
    set_description("Windows SDK C++ x64 NuGet payload for Linux-hosted clang-cl/lld-link builds")
    set_license("Microsoft SDK License")

    -- NuGet flat-container URLs are content-addressed by package id and version.
    -- Xmake extracts by the local filename extension, so store the NuGet
    -- .nupkg payload as a .zip in the package cache.
    add_urls("https://api.nuget.org/v3-flatcontainer/microsoft.windows.sdk.cpp.x64/$(version)/microsoft.windows.sdk.cpp.x64.$(version).nupkg", {filename = "windows-sdk-cpp-x64.zip"})
    add_versions("10.0.26100.4204", "ea4947d9a8ec715b78be40fb9bf3dcee91518098b7d7dd24b293fe7c021576c7")
    add_resources("10.0.26100.4204", "sdk_headers", "https://api.nuget.org/v3-flatcontainer/microsoft.windows.sdk.cpp/10.0.26100.4204/microsoft.windows.sdk.cpp.10.0.26100.4204.nupkg#sdk-headers-10.0.26100.4204.zip", "0653aa3dab7fc269fa8f3da0493d6bbddbfd79ab83ab94837c2f209a584596eb")

    -- Layout assumption for 10.0.26100.4204:
    --   c/um/x64/*.lib from Microsoft.Windows.SDK.CPP.x64
    --   c/Include/10.0.26100.0/{shared,um,ucrt,...} from
    --   Microsoft.Windows.SDK.CPP, pulled as a resource because the arch-specific
    --   SDK C++ NuGet contains libraries but not the headers WDK headers include.
    -- If Microsoft changes the package layout, adjust these paths instead of
    -- changing consuming rules.

    on_install(function (package)
        import("utils.archive")

        local nupkgs = os.files("*.nupkg")
        if #nupkgs > 0 then
            local extracted = path.join(os.tmpdir(), "windows-sdk-cpp-x64-" .. package:version_str())
            os.tryrm(extracted)
            archive.extract(nupkgs[1], extracted)
            os.cp(path.join(extracted, "*"), package:installdir())
        else
            os.cp("*", package:installdir())
        end

        local headers = package:resourcedir("sdk_headers")
        if headers and os.isdir(path.join(headers, "c", "Include")) then
            os.cp(path.join(headers, "c", "Include"), path.join(package:installdir(), "c"))
        end

        -- The SDK archives are authored for Windows' case-insensitive
        -- filesystem. Keep the workaround local to the package cache.
        local shared = path.join(package:installdir(), "c", "Include", "10.0.26100.0", "shared")
        if os.isfile(path.join(shared, "driverspecs.h")) and not os.isfile(path.join(shared, "DriverSpecs.h")) then
            os.cp(path.join(shared, "driverspecs.h"), path.join(shared, "DriverSpecs.h"))
        end
    end)

    on_test(function (package)
        local root = package:installdir()
        assert(os.isdir(path.join(root, "c", "um", "x64")))
        assert(os.isfile(path.join(root, "c", "Include", "10.0.26100.0", "shared", "specstrings.h")))
    end)
package_end()
