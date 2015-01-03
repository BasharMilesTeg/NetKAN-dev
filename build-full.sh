#!/bin/bash
set -x
set -e

echo Fetching latest ckan.exe

# fetch latest ckan.exe
wget --quiet http://ci.ksp-ckan.org:8080/job/CKAN/lastSuccessfulBuild/artifact/ckan.exe -O ckan.exe

echo Creating a dummy KSP install

# create a dummy KSP install
mkdir dummy_ksp
echo Version 0.90.0 > dummy_ksp/readme.txt
mkdir dummy_ksp/GameData
mkdir dummy_ksp/Ships/
mkdir dummy_ksp/Ships/VAB
mkdir dummy_ksp/Ships/SPH

mono --debug ckan.exe ksp add ${ghprbActualCommit} "`pwd`/dummy_ksp"
mono --debug ckan.exe ksp default ${ghprbActualCommit}

echo Running ckan update
mono --debug ckan.exe update

echo Commit hash: ${ghprbActualCommit}
export COMMIT_CHANGES="`git diff --diff-filter=AM --name-only --stat origin/master`"

echo Running jsonlint on the changed files
echo If you get an error below you should look for syntax errors in the metadata

jsonlint -s -v ${COMMIT_CHANGES}

echo Fetching latest netkan.exe

# fetch latest netkan.exe
wget --quiet http://ci.ksp-ckan.org:8080/job/NetKAN/lastSuccessfulBuild/artifact/netkan.exe -O netkan.exe

mkdir built

for f in ${COMMIT_CHANGES}
do
	echo Running NetKAN for $f
	mono --debug netkan.exe $f --cachedir="dummy_ksp/CKAN/downloads" --outputdir="built"
done

for f in built/*.ckan
do
	echo ----------------------------------------------
	echo 
	cat $f | python -m json.tool
	echo ----------------------------------------------
	echo 
	echo Running ckan install -c $f
	mono --debug ckan.exe install -c $f --headless
done
