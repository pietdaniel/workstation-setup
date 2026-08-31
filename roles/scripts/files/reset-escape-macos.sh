#!/usr/bin/env bash

# Clear the active hidutil remap, restoring the default Caps Lock and Escape keys.
hidutil property --set '{"UserKeyMapping":[]}'
