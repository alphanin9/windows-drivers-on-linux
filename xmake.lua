add_repositories("local-wdk-repo .", {rootdir = os.scriptdir()})

-- xmake 3.0.9+ provides clang-cl[llvm] for Linux-hosted LLVM mode.
-- This fallback keeps the proof-of-concept usable on older xmake releases
-- that have clang-cl but still bind the built-in clang-cl toolchain to a
-- Visual Studio environment.
toolchain("wdk-clang-cl")
    set_kind("standalone")
    on_load(function (toolchain)
        local function find_program(name)
            for _, dir in ipairs(path.splitenv(os.getenv("PATH") or "")) do
                local program = path.join(dir, name)
                if os.isfile(program) then
                    return program
                end
            end
        end

        local clang_cl = assert(find_program("clang-cl"), "clang-cl not found in PATH")
        local lld_link = assert(find_program("lld-link"), "lld-link not found in PATH")
        toolchain:set("toolset", "cc", clang_cl)
        toolchain:set("toolset", "cxx", clang_cl)
        toolchain:set("toolset", "ld", lld_link)
        toolchain:set("toolset", "sh", lld_link)
        toolchain:set("toolset", "ar", find_program("llvm-lib") or find_program("llvm-ar") or lld_link)
        toolchain:set("toolset", "mrc", find_program("llvm-rc") or "llvm-rc")
    end)
    on_check(function (toolchain)
        for _, name in ipairs({"clang-cl", "lld-link"}) do
            local found = false
            for _, dir in ipairs(path.splitenv(os.getenv("PATH") or "")) do
                if os.isfile(path.join(dir, name)) then
                    found = true
                    break
                end
            end
            if not found then
                return false
            end
        end
        return true
    end)
toolchain_end()

set_project("linux_wdk_driver_poc")
set_version("0.1.0")
set_languages("c17")
set_plat("windows")
set_arch("x64")
if xmake.version():ge("3.0.9") then
    set_toolchains("clang-cl[llvm]")
else
    set_toolchains("wdk-clang-cl")
end

includes("rules/*.lua")

add_requires("windows-sdk-cpp 10.0.26100.4204")
add_requires("windows-wdk-x64 10.0.26100.4204")

target("hello_driver")
    add_rules("wdk.raw_driver", "wdk.testsign")
    add_packages("windows-sdk-cpp", "windows-wdk-x64")
    add_files("src/*.c")
