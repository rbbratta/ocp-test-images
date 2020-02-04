#!/bin/bash

for f in *.dot ; do dot -o "${f%%.dot}.png" -T png "${f}" & done ; wait
