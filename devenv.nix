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
    GREET = "the experiment environment";
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
            for i in $(seq 10); do
              uv run ${config.git.root}/scripts/problem_generators/regular_counting.py --num-states "$states" --alphabet-size "$alphabet" --sequence-length "$sequence" --k "${"$" + "{k[@]}"}" --seed "$i" --data-dir "${config.git.root}/problems/regular_counting/data"
            done
          done
        }

        # small alphabet, small count
        create << EOF
        3 3 9
        1 2
        5 3 15
        1 2
        7 3 21
        1 2
        9 3 27
        1 2
        EOF

        # small alphabet, medium count
        create << EOF
        3 3 15
        1 4
        5 3 25
        1 4
        7 3 35
        1 4
        9 3 45
        1 4
        EOF

        # small alphabet, large count
        create << EOF
        3 3 27
        1 8
        5 3 45
        1 8
        7 3 63
        1 8
        9 3 81
        1 8
        EOF

        # small alphabet, huge count
        create << EOF
        3 3 51
        1 16
        5 3 85
        1 16
        7 3 119
        1 16
        9 3 153
        1 16
        EOF

        # medium alphabet, small count
        create << EOF
        3 6 9
        1 2
        5 6 15
        1 2
        7 6 21
        1 2
        9 6 27
        1 2
        EOF

        # medium alphabet, medium count
        create << EOF
        3 6 15
        1 4
        5 6 25
        1 4
        7 6 35
        1 4
        9 6 45
        1 4
        EOF

        # medium alphabet, large count
        create << EOF
        3 6 27
        1 8
        5 6 45
        1 8
        7 6 63
        1 8
        9 6 81
        1 8
        EOF

        # medium alphabet, huge count
        create << EOF
        3 6 51
        1 16
        5 6 85
        1 16
        7 6 119
        1 16
        9 6 153
        1 16
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
  tasks = {
    "pumpkin:build" = {
      exec = "cargo build --release";
      execIfModified = [
        "Pumpkin/**/*.rs"          # All rs files in ./Pumpkin
      ];
      # Run the build in ./Pumpkin
      cwd = "./Pumpkin";
    };
    "devenv:enterShell".after = [ "pumpkin:build" ];
  };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
