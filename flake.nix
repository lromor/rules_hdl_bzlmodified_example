{
  description = "fpga-assembler";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/2c8d3f48d33929642c1c12cd243df4cc7d2ce434";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
      self,
      nixpkgs,
      flake-utils,
    } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        bazelOverride = pkgs.bazel_7.overrideAttrs (
          previousAttrs: {
            # Provide our own hack, latest enableNixHacks introduces repo issues.
            patches = previousAttrs.patches ++ [
              ./nix/bazel.patch
            ];
          });

        bazelBinExtra = with pkgs; [
          git      # fetching openroad
          perl     # uses in build of iverilog
          ncurses  # something is using tools from there to query terminal
          gcc14    # `ar` for z3; `cpp` for net_invisible_island_ncurses//:lib_gen_c
          clang
        ];
        bazelExtraBinPath = pkgs.lib.makeBinPath bazelBinExtra;

        # Required for toolchains_llvm
        bazelRunLibs = with pkgs; [
          stdenv.cc.cc
          zlib
          zstd
          ncurses  # libtinfo, really
          libxml2
          expat
        ];

        # TODO: this is a hack of sorts. Ideally, we'd just like to add all these
        # binaries to what is referred to in the bazel package as `defaultShellUtils`
        #
        # If we can do that, they are 'baked into' the bazel installation, and
        # we can remove adding PATH to the excemption environment variables in
        # nix/bazel.patch
        wrappedBazel = pkgs.writeShellScriptBin "bazel" ''
        # Invoking bazel with the extra PATH to tools required by XLS compilation.
        export PATH=${bazelExtraBinPath}
        exec ${bazelOverride}/bin/bazel "$@"
        '';
      in {
        devShells.default =
          let
            # There is too much volatility between even micro-versions of
            # newer clang-format. Use slightly older version for now.
            clang_for_formatting = pkgs.llvmPackages_17.clang-tools;

            # clang tidy: use latest.
            clang_for_tidy = pkgs.llvmPackages_18.clang-tools;
          in
          with pkgs;
          pkgs.mkShell {
            packages = with pkgs; [
              git
              wrappedBazel
              jdk
              bash
              gdb

              # For clang-tidy and clang-format.
              clang_for_formatting
              clang_for_tidy

              # For buildifier, buildozer.
              bazel-buildtools
              bant

              # Profiling and sanitizers.
              linuxPackages_latest.perf
              pprof
              perf_data_converter
              valgrind

              # FPGA utils.
              openfpgaloader
              klayout
              yosys
              netlistsvg
            ];

            CLANG_TIDY = "${clang_for_tidy}/bin/clang-tidy";
            CLANG_FORMAT = "${clang_for_formatting}/bin/clang-format";
            NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath bazelRunLibs;
            CPATH = pkgs.lib.makeLibraryPath bazelRunLibs;

            # Override .bazelversion. We only care about our bazel we created.
            #USE_BAZEL_VERSION = "${bazel_7.version}";
            shellHook = ''
              exec bash
            '';
          };
      }
    );
}

