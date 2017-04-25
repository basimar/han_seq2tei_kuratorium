#!/bin/bash

# make-seq2ead.sh
#   Export-Skript für DSV05-Daten nach Kalliope im ead-Format
# 
# author:   
#   basil.marti@unibas.ch
#
# history:

DO_TRANSFORM=0
DO_SPLIT=1
DO_FINISH=1

HOME=/home/basil/catmandu/han_seq2tei_kuratorium/
FILES=tmp/split/*

LINE='------------------------------------------------'

echo $LINE
echo "Exporting DSV05 data for TEI"
echo "START:  $(date)"
echo $LINE
echo $LINE

cd $HOME

if [ "$DO_TRANSFORM" == "1" ]; then
    echo $LINE
    echo "*Transforming DSV05 data to tei"
    echo $LINE
    perl seq2tei.pl input/dsv05.seq tmp/tei.xml
fi


if [ "$DO_SPLIT" == "1" ]; then
    echo $LINE
    echo "*Splitting tei-file"
    echo $LINE
    cd tmp/split
    find . -name "*.xml" -print0 | xargs -0 rm
    cd $HOME

    cd output/
    rm validation_errors.txt
    rm validation_ok.txt
    cd $HOME

    cd output/validation
    find . -name "*.xml" -print0 | xargs -0 rm
    cd $HOME

    cd output/no_validation
    find . -name "*.xml" -print0 | xargs -0 rm
    cd $HOME

    perl split.pl tmp/tei.xml tmp/split 
fi

if [ "$DO_FINISH" == "1" ]; then
    echo $LINE
    echo "*Finishing tei-files"
    echo $LINE

    for f in $FILES
    do
        echo "Finishing file $f"
        xsltproc sanitise.xsl $f > $f.san
        xmllint --format $f.san > $f
        rm $f.san
        sed 's/<TEI>/<TEI xmlns="http:\/\/www.tei-c.org\/ns\/1.0" version="5.0">/g' $f > $f.valid
        mv $f.valid $f
        #output="$(xmllint --noout --schema tei_all.xsd $f 2>&1)"
        output="$(xmllint --noout $f 2>&1)"
    
        if [[ $output =~ fails.to.validate ]];
            then 
                cp $f output/no_validation/
                echo $output >> output/validation_errors.txt;
            else
                cp $f output/validation/
                echo $output >> output/validation_ok.txt;
        fi 
    done
fi
echo "END:  $(date)"
