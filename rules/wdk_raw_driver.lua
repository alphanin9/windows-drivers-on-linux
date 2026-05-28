rule("wdk.raw_driver")
    after_load(function (target)
        assert(is_plat("windows"), "wdk.raw_driver requires -p windows")
        assert(is_arch("x64"), "wdk.raw_driver currently supports x64")

        target:set("kind", "binary")
        target:set("filename", target:name() .. ".sys")
        target:set("prefixname", "")
        target:add("cflags", "/kernel", "/W4", "/clang:--target=x86_64-pc-windows-msvc", {force = true})
        target:add("cxflags", "/kernel", "/W4", "/clang:--target=x86_64-pc-windows-msvc", {force = true})
        target:add("asflags", "--target=x86_64-pc-windows-msvc", {force = true})
        target:add("defines", "_AMD64_=1", "AMD64=1", {public = false})

        local wdk = target:pkg("windows-wdk-x64")
        local sdk = target:pkg("windows-sdk-cpp")
        if not wdk or not sdk then
            return
        end
        local wdkroot = wdk:installdir()
        local sdkroot = sdk:installdir()
        local wdkver = "10.0.26100.0"
        target:add("includedirs",
            path.join(wdkroot, "c", "Include", wdkver, "km"),
            path.join(wdkroot, "c", "Include", wdkver, "km", "crt"),
            path.join(sdkroot, "c", "Include", wdkver, "shared"),
            {public = false})
        target:add("linkdirs", path.join(wdkroot, "c", "Lib", wdkver, "km", "x64"), {public = false})
        target:add("links", "ntoskrnl", "hal", "bufferoverflowfastfailk")
        target:add("ldflags", "/driver", "/dll", "/subsystem:native", "/entry:GsDriverEntry", "/nodefaultlib", "/INTEGRITYCHECK", {force = true})
    end)
rule_end()
