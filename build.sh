#!/bin/bash
mkdir -p output/
echo "Clearing out old build..."
rm -rf output/*

echo "Copy files to output folder..."
cp alfred/info.plist.xml output/info.plist
cp alfred/calendar.png output/icon.png
cp cal_to_md.swift output/

curVersion=$(cat VERSION)
echo "Current version: $curVersion"
sed -i 's/{{version}}/'${curVersion}'/' output/info.plist

readme='README.md'
echo "Copy $readme into the info.plist..."
sed -i -e "/{{readme}}/{r ${readme}" -e 'd' -e '}' output/info.plist

echo "Zipping up version ${curVersion}..."
cd output
zip -Z deflate -rq9 Agenda.to.Markdown.alfredworkflow * -x etc
cd -
