CUR_DIR=$PWD
DEST_DIR="../build/Release-iphoneos/"
DOCSET_NAME="`basename -s .sh $0`.docset"

rm -r "$CUR_DIR/html"
/Applications/Doxygen.app/Contents/Resources/doxygen "${CUR_DIR}/Doxyfile"
make --quiet -C "${CUR_DIR}/html"

rm -r ${DEST_DIR}${DOCSET_NAME}
cp -p Makefile $DEST_DIR
cp -R "html/${DOCSET_NAME}" $DEST_DIR

