#!/bin/sh
# e is for exiting the script automatically if a command fails, u is for exiting if a variable is not set
# x would be for showing the commands before they are executed
set -eu

export GEM_HOME="/usr/local/bundle"
export PATH=$GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH

rancher-deployer
