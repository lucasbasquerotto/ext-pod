#!/bin/bash

# shellcheck disable=SC1083
param_value={{ params.value | quote }}

# shellcheck disable=SC2154
echo "[template] param value = $param_value"