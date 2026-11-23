#!/bin/sh
# Compiles the pure Domain + Data layers with the checks and runs them (no simulator needed).
set -e
cd "$(dirname "$0")/.."
out=$(mktemp -d)
xcrun swiftc -o "$out/check" Hearthware/Domain/*.swift Hearthware/Data/*.swift Checks/main.swift
"$out/check"
