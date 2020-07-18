#!/bin/bash

lang="$1"
validLanguages="en"
htmlDest="cuisHtml"
infoDest="cuisInfo"
docbookDest="cuisDocbook"
masterDoc="TheCuisBook.texinfo"
parts="B-BasicCuis C-SystemClasses D-AdvancedCuis"

function collateChapters {
    chapters="A-Preface E-Exercises"
    for part in $parts
    do
	for file in `ls -1 $lang/$part`
	do
	    if [[ $file != "img" && $file != "contents.texinfo" ]]; then
		chapters="$chapters $part/$file"
	    fi
	done
    done	     

    imgPath="./img"
    for chapter in $chapters
    do
	imgPath="$imgPath:./$chapter/img"
    done
}

function doPdf {
    cd $lang
    makeinfo -I $imgPath --pdf $masterDoc
    cd -
    clean_all
}

function doDocbook {
    cleanupDestination $docbookDest
    cd $lang
    texi2any --output=$docbookDest/ --transliterate-file-names --split=node \
	     --no-number-sections --docbook $masterDoc 
    cd -
}

function doInfo {
    prepareDestination $infoDest
    cd $lang
    makeinfo -I $imgPath --output=$infoDest/ $masterDoc
    cd -
}

function doHtml {
    prepareDestination $htmlDest
    cp style.css $lang/$htmlDest
    cd $lang
    texi2any -I $imgPath --output=$htmlDest/ --html --css-ref=style.css $masterDoc
    cd -
    # copy to docs for git hub publishing
    cp -a $lang/$htmlDest/* docs/
}

function cleanupDestination {
    # Clean up dest $1
    cd $lang
    rm -rf "$1"
    mkdir "$1"
    cd -
}
function prepareDestination {
    # Clean up dest $1 and copy all bitmaps there
    cleanupDestination "$1"
    cd $lang
    for dir in $chapters
    do
	if [ -d $dir/img ]; then
	    cp $dir/img/*.png "$1"
   	    cp $dir/img/*.jpg "$1"
	fi
    done
    cp ./img/*.png "$1"
    cp ./img/*.jpg "$1"
    cd -
}

function package_html {
    doHtml
    cd $lang/$cuisHtml
    tar cfz ../cuis-html-$lang.tgz *
    cd -
}

function clean_all {
    cd $lang
    rm   *.log *.toc  *.aux  *.cp *.cps *.fn *.ky *.tp *.vr *.fns *.pg
    cd -
}

function checkForValidLanguage
{
okLang="0"
for valid in $validLanguages; do
    if [[ $lang = $valid ]]; then
	okLang="1"
    fi
done

if [[ $okLang = "0" ]]; then
    usage
    exit
fi
}


function usage {
    echo "Usage: $0 ($validLanguages) (docbook|html|pdf|package|clean)"
}

checkForValidLanguage
collateChapters

case "$2" in 
    docbook)
	echo "Build documentation in docbook."
	doDocbook
	;;
    html) 
	echo 'Build documentation in html.'
	doHtml
	;;
    pdf)
	echo 'Build documentation in PDF.'
	doPdf
	;;
    info)
	echo 'Build documentation for Texinfo.'
	doInfo
	;;
    package)
	echo 'Build html documentation and archive it.'
	doHtml
	package_html
	;;
    clean)
	echo "Delete all the intermediate files."
	clean_all
	;;
    *)
	usage
	exit
esac
