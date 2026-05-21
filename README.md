# Linux WDK Driver Proof of Concept

This is a small xmake proof-of-concept for building a raw Windows kernel driver from Linux with LLVM tools:

- `clang-cl` for MSVC/WDK-compatible compiler flags
- `lld-link` for PE driver linking
- local xmake package recipes for WDK/SDK NuGet payloads
- optional Linux-native embedded Authenticode test-signing with OpenSSL and `osslsigncode`

The initial target is x64, simple WDM/raw NT drivers, and a single `.sys` output.

## Prerequisites

Install:

- xmake with LLVM toolchain mode support, preferably xmake 3.0.9 or newer
- LLVM/Clang tools providing `clang-cl` and `lld-link`
- optional for signing: `openssl` and `osslsigncode`

No Wine, `signtool.exe`, Visual Studio, or Windows-hosted build tools are used.

## Packages

The local package repository under `packages/` pins these NuGet packages:

- `Microsoft.Windows.SDK.CPP` version `10.0.26100.4204`
- `Microsoft.Windows.WDK.x64` version `10.0.26100.4204`

The WDK package explicitly depends on the SDK C++ package because xmake does not consume NuGet dependency metadata for these local recipes.

The recipes use `add_urls`, `add_versions`, and SHA-256 checksums. They assume the current NuGet layout documented in the package files, for example:

- WDK includes: `c/Include/10.0.26100.0/km` and `c/Include/10.0.26100.0/km/crt`
- WDK libs: `c/Lib/10.0.26100.0/km/x64`
- SDK shared headers: `c/Include/10.0.26100.0/shared`

If Microsoft changes the NuGet layout, adjust the paths in the package recipe rather than hardcoding paths in targets.

## Build

Unsigned build:

```sh
xmake f -p windows -a x64 -c
xmake
```

The `wdk.raw_driver` rule transforms the normal xmake binary target into a raw kernel driver:

- output file extension is `.sys`
- compiler uses `clang-cl /kernel`
- linker uses `/driver /subsystem:native /entry:DriverEntry /nodefaultlib`
- default kernel import library is `ntoskrnl`

`/kernel` is intentionally applied to `clang-cl`. `lld-link /kernel` is not used because it is only a compatibility spelling and is not the meaningful kernel-mode diagnostic switch.

## Optional embedded test-signing

Generated self-signed test certificate:

```sh
xmake f -p windows -a x64 --wdk_testsign=true -c
xmake
```

The signing rule generates `certs/test-driver.crt` and `certs/test-driver.key` if no certificate is provided. The certificate includes the Code Signing EKU `1.3.6.1.5.5.7.3.3`, uses SHA-256, signs the `.sys` with `osslsigncode`, then runs syntactic Authenticode verification. For generated self-signed certificates the rule passes the generated certificate as the verification trust anchor:

```sh
osslsigncode verify -CAfile certs/test-driver.crt -in driver.sys
```

User-provided certificate and key:

```sh
xmake f -p windows -a x64 \
  --wdk_testsign=true \
  --wdk_sign_cert=/path/to/test-driver.crt \
  --wdk_sign_key=/path/to/test-driver.key \
  -c
xmake
```

Private keys are ignored by `.gitignore`.

## Windows test VM notes

To load a test-signed raw `.sys`, the target Windows VM generally needs test-signing mode enabled:

```cmd
bcdedit /set TESTSIGNING ON
```

Reboot after changing this setting.

Secure Boot may prevent enabling test mode. Disable Secure Boot in the VM firmware settings if Windows refuses to enter test-signing mode.

HVCI / Memory Integrity may require a signed image even in test scenarios. Use `--wdk_testsign=true` when testing on systems with code-integrity features enabled.

Certificate import into Windows trusted stores is usually not required for raw `.sys` loading under test-signing mode. Importing the test certificate can still be useful for tooling, package-trust UX, or workflows that inspect signer trust outside the kernel test-signing path.

## Out of scope

This proof-of-concept intentionally does not implement:

- catalog signing
- INF processing
- `Inf2Cat`
- CAB generation
- WHQL / HLK
- Microsoft attestation signing
- Windows Dev Portal submission
- production driver package signing

A Windows VM is still required later to load and exercise the built driver.
