#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
xattr -dr com.apple.quarantine "$DIR/가계부.app"
open "$DIR/가계부.app"
