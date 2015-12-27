#!/bin/sh
wget -mkE http://doc.perl6.org --restrict-file-names=nocontrol
mkdir Perl6.docset/Contents/Resources
mv doc.perl6.org Perl6.docset/Contents/Resources/Documents
cd Perl6.docset/Content
perl6 fillTable.pl
cd ../..
rm Perl6.docset/Contents/Resources/Documents/css/style.css
cp style.css Perl6.docset/Contents/Resources/Documents/css/style.css
rm Perl6.docset/Contents/Resources/Documents/js/main.js
cp main.js Perl6.docset/Contents/Resources/Documents/js/main.js
rm Perl6.docset/Contents/Resources/Documents/js/search.js
cp search.js Perl6.docset/Contents/Resources/Documents/js/search.js
