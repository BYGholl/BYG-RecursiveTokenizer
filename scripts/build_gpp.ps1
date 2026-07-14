$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force bin | Out-Null
g++ -std=c++17 -O2 -Wall -Wextra -pedantic src/byg.cpp -o bin/byg.exe
& .inyg.exe --version
