#! /bin/bash
sourceZip="drs.zip"
sourceFile="tensorflow_template_application-master"

## download the source zip
if ! [ -e $sourceZip  ] 
then 
    if ! type curl &>> /dev/null
    then
        apt-get update
        apt-get install curl
    fi
        curl https://codeload.github.com/tobegit3hub/deep_recommend_system/zip/master -o $sourceZip \
        1>> /dev/null
fi

## unzip the source files 
if ! [ -d $sourceFile ]
then 
    if ! type unzip &>> /dev/null
    then
        apt-get update
        apt-get install unzip 
    fi
    unzip drs.zip 1>> /dev/null
fi

echo "[INFO] $sourceFile downloaded and extracted successfully"

