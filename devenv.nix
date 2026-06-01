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
        # Based on https://github.com/JulGvoz/nfa-propagator-explanations/blob/main/experiments/gen_nonogram.sh
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
    "scripts/generate_regular_counting.sh" = {
    
      text = ''
        #!/bin/sh
        # Inspired by https://github.com/JulGvoz/nfa-propagator-explanations/blob/main/experiments/gen_nonogram.sh
        set -eux

        create() {
          while read states alphabet sequence; do
            read -a k
            for i in $(seq 5); do
              uv run ${config.git.root}/scripts/problem_generators/regular_counting.py --num-states "$states" --alphabet-size "$alphabet" --sequence-length "$sequence" --k "${"$" + "{k[@]}"}" --seed "$i" --data-dir "${config.git.root}/problems/regular_counting/data"
            done
          done
        }

        # small alphabet, small count
        create << EOF
        2 2 6
        1 2
        3 2 9
        1 2
        4 2 12
        1 2
        5 2 15
        1 2
        EOF

        # small alphabet, medium count
        create << EOF
        2 2 10
        1 4
        3 2 15
        1 4
        4 2 20
        1 4
        5 2 25
        1 4
        EOF

        # small alphabet, large count
        create << EOF
        2 2 18
        1 8
        3 2 27
        1 8
        4 2 36
        1 8
        5 2 45
        1 8
        EOF

        # medium alphabet, small count
        create << EOF
        2 3 6
        1 2
        3 3 9
        1 2
        4 3 12
        1 2
        5 3 15
        1 2
        EOF

        # medium alphabet, medium count
        create << EOF
        2 3 10
        1 4
        3 3 15
        1 4
        4 3 20
        1 4
        5 3 25
        1 4
        EOF

        # medium alphabet, large count
        create << EOF
        2 3 18
        1 8
        3 3 27
        1 8
        4 3 36
        1 8
        5 3 45
        1 8
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
