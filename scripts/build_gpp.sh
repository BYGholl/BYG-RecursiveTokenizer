#!/usr/bin/env bash
set -euo pipefail
mkdir -p bin
g++ -std=c++17 -O2 -Wall -Wextra -pedantic src/byg.cpp -o bin/byg
./bin/byg --version
