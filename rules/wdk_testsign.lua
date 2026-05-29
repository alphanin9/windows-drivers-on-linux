option("wdk_testsign")
    set_default(true)
    set_showmenu(true)
    set_description("Embed an Authenticode test signature in the built .sys using osslsigncode")
option_end()

option("wdk_sign_cert")
    set_default("")
    set_showmenu(true)
    set_description("Path to a PEM/CRT code-signing certificate for wdk.testsign")
option_end()

option("wdk_sign_key")
    set_default("")
    set_showmenu(true)
    set_description("Path to a PEM private key for wdk.testsign")
option_end()

option("wdk_testsign_org_name")
    set_default("xmake WDK test driver")
    set_showmenu(true)
    set_description("The name of the organization that will be in the test certificate")
option_end()

option("wdk_verbose_codesign")
    set_default(false)
    set_showmenu(true)
    set_description("Output signing programs stdout during signing")
option_end()

rule("wdk.testsign")
    after_build(function (target)
        import("core.project.config")
        import("lib.detect.find_tool")

        if not config.get("wdk_testsign") then
            return
        end

        local osslsigncode = find_tool("osslsigncode")
        assert(osslsigncode, "wdk_testsign=true requires osslsigncode in PATH")
	
	-- Specifying check() seems to be needed on at least Ubuntu 24.04
        local openssl = find_tool("openssl", { check = function(tool) os.run("%s -h", tool) end })
	
        local cert = config.get("wdk_sign_cert")
        local key = config.get("wdk_sign_key")
	local verbose = config.get("wdk_verbose_codesign")
        local org_name = config.get("wdk_testsign_org_name")

	local run_func = verbose and os.execv or os.runv

        if cert == "" or key == "" then
            assert(openssl, "generated test certificates require openssl in PATH")
            local certdir = path.join(os.projectdir(), "certs")
            os.mkdir(certdir)
            cert = path.join(certdir, "test-driver.crt")
            key = path.join(certdir, "test-driver.key")

            if not os.isfile(cert) or not os.isfile(key) then
                run_func(openssl.program, {
                    "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-sha256", "-days", "3650",
                    "-subj", string.format("/CN=%s/", org_name), "-addext", "extendedKeyUsage=codeSigning",
                    "-keyout", key, "-out", cert
                })
            end
        end

        assert(os.isfile(cert), "wdk_sign_cert does not exist: " .. cert)
        assert(os.isfile(key), "wdk_sign_key does not exist: " .. key)
        local unsigned = target:targetfile()
        local signed = path.join(path.directory(unsigned), path.basename(unsigned) .. "-signed.sys")
        os.tryrm(signed)
        run_func(osslsigncode.program, {"sign", "-h", "sha256", "-certs", cert, "-key", key, "-in", unsigned, "-out", signed})
        os.mv(signed, unsigned)
        run_func(osslsigncode.program, {"verify", "-CAfile", cert, "-in", unsigned})
    end)
rule_end()
