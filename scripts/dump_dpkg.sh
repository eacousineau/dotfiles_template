#!/bin/bash

dpkg-query -f='${PackageSpec;-60}\t${Architecture;-10}\t${Version;-30}\t${Source}\n' -W "*"

