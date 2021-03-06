#!/bin/bash
# usage: ./genhelp.sh
#
# expects halibut to be installed in $PATH:
# http://www.chiark.greenend.org.uk/~sgtatham/halibut
#
# also requires host CC and lz4 library to be available

halibut --text src/puzzles.but

# preprocess the input

# strip leading whitespace
cat puzzles.txt | awk '{$1=$1; print}' > puzzles.txt.tmp

# cut at "Appendix A"
cat puzzles.txt.tmp | awk 'BEGIN { a=1; } /Appendix A/ { a = 0; } a==1' > puzzles.txt

rm puzzles.txt.tmp

# now split into different files
mkdir -p help

cat puzzles.txt | awk 'BEGIN { file = "none"; }
 /#Chapter/ {
 if($0 !~ / 1:/ && $0 !~ / 2:/)
 {
    if(file != "none")
        print ";" > file;
    file = "help/"tolower($3$4)".c";
    if($3 ~ "Rectangles")
        file = "help/rect.c";
    print "/* auto-generated by genhelp.sh */" > file;
    print "/* DO NOT EDIT! */" > file;
    print "const char help_text[] = " > file; }
 }
 file != "none" {
 gsub(/\\/,"\\\\");
 if($0 !~ /Chapter/ && substr($0, 1, 1) == "#")
     begin = "\\n";
 else begin = "";
 last = substr($0, length($0), 1);
 if(length($0) == 0 || last == "|" || last == "-" || (term == "\\n" && last == "3"))
     term="\\n";
 else term = " ";
 print "\"" begin $0 term "\"" > file;
 }
 END {
     print ";" > file;
 }
'

# now compress
for f in help/*
do
    echo "Compressing: "$f
    gcc compress.c $f -llz4 -o compress -O0
    ./compress > $f.tmp
    mv $f.tmp $f
done

# generate quick help from gamedesc.txt
cat src/gamedesc.txt | awk -F ":" '{print "const char quick_help_text[] = \""$5"\";" >> "help/"$1".c" }'
