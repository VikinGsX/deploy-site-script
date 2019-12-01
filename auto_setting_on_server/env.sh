#!/bin/bash

# check import config
# colorPath = "./color-config.sh"
if [ -f  "./color-config" ]
then
echo "${CFAILURE}錯誤: 檔案不存在!!!";

else
echo "檔案存在!!!"
source "./color-config"
fi