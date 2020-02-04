#!/bin/bash

for f in *.dot ; do dot -o "${f%%.dot}.pdf" -T pdf "${f}" & done ; wait
