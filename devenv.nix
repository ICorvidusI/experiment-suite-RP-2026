{ pkgs, lib, config, inputs, ... }:
let
  buildInputs = with pkgs; [
    stdenv.cc.cc
    libuv
    zlib
  ];
in
{
  # https://devenv.sh/basics/
  env = {
    GREET = "the expiriment environment";
    MZN_SOLVER_PATH = [ (config.git.root + "/Pumpkin/minizinc") ];
    LD_LIBRARY_PATH = "${lib.makeLibraryPath buildInputs}";
  };

  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    minizinc
  ];

  # https://devenv.sh/languages/
  languages = {
    rust = {
      enable = true;
      channel = "nightly";
      components = [ "rustc" "cargo" "clippy" "rustfmt" "rust-analyzer" ];
    };

    python = {
      enable = true;
      uv = {
        enable = true;
        sync.enable = true;
      };
    };
  };

  files = {
    "scripts/generate_nonograms.sh" = {
    
      text = ''
        #!/bin/sh
        set -eux

        while read width height; do
          for i in $(seq 5); do
            uv run ${config.git.root}/scripts/problem_generators/nonogram.py --width "$width" --height "$height" --density 0.5 --seed "$i" --data-dir "${config.git.root}/problems/nonogram/data"
          done
        done << EOF
        20 20
        20 25
        25 25
        25 30
        30 30
        30 35
        35 35
        EOF
      '';
    
      executable = true;
  
    };
  };

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo Welcome to $GREET
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    hello         # Run scripts directly
    git --version # Use packages
    minizinc --version
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
