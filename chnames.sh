#!/bin/bash

# chnames.sh = Change file names by replacing undesirable characters.
# 
# Copyright (C) 2005-2007 Conny Faber <conny@supple-pixels.net>
# The latest version, a small example archive containing weird but possible
# file names and the German version of this script are available on
# http://www.supple-pixels.net.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details
# (see file COPYING).
# 

# I mainly wrote this script for renaming MP3 files, which often contain not
# only umlauts and accented characters (= problem between different encodings)
# but also several different characters such as parentheses, brackets, braces,
# +, &, spaces (= inconvenient for some programmes), etc.; but can be used to
# automatically check and rename other files as well.
# 
# chnames.sh will only work correctly if it remains UTF-8 encoded and if it
# is executed in a UTF-8 shell, for it contains characters outside of the
# ISO-8859-1 range!
#
# ToDo - later:
# -------------
# -k = keep multiple occurrences, e.g. of --- or ___.
# -s = substitute = specify own substitution patterns, e.g.
#      -s '+|plus' -s '. |.'   (= -s [from|to])



benutzung()
{
HILFE="chnames.sh - Change file names by replacing undesirable characters.

Description:
------------
  chnames.sh is a shell script, that I mainly wrote for renaming MP3 files,
  which often contain spaces, umlauts, accented characters, parentheses, and
  other undesirable characters. chnames.sh is able to rename files and
  directories by automatically performing the following substitutions:
  
  (Hint: You need a terminal which is able to display UTF-8 properly to be
         able to see all the characters below, e.g. urxvt, gnome-terminal,
         konsole.)
  
  Character                          Becomes
  ---------------------------------------------------------------------------
  () [] {} <>                        -
  space                              _
  Ä Ö Ü ä ö ü ß                      Ae Oe Ue ae oe ue ss
  + &                                _and_ (= default), or: _und_ (with -g)
  °                                  _deg_ (= default), or: _Grad_ (with -g)
  : ;                                .
  ,                                  If followed by space: _
                                     Else:                 .
  ' \" \` ´ ? ! ^ # * ¿ ¡ ,            Are removed.
  accented characters                Become characters without accent:
                                     ÀÁÂÃÅ - A        àáâãå - a
                                     Æ     - AE       æ     - ae
                                     ÇĆĈĊČ - C        çćĉċč - c
                                     ÈÉÊË  - E        èéêë  - e
                                     ÌÍÎÏ  - I        ìíîï  - i
                                     Ñ     - N        ñ     - n
                                     ÒÓÔÕØ - O        òóôõø - o
                                     ŚŜŞŠ  - S        śŝşš  - s
                                     ÙÚÛ   - U        ùúû   - u
                                     Ý     - Y        ýÿ    - y
                                     ŹŻŽ   - Z        źżž   - z
  several of: space - _ . ~          Are reduced to one character.
  - at the beginning                 Is removed.


Usage:  chnames.sh <-d [dir]> <-D> <-g> <-r> <--check|--echeck|--no-log|-u>
-----   chnames.sh <-f [file]>... <-g> <--check|--echeck>
        chnames.sh <-h|--usage|--version>
    
  --check       A pure check: Only pretend to rename. Outputs original and
                potentially changed names in the shell. No names are changed
                and no log file produced.
  -d [dir]      Specify path [dir] containing the files to rename.
                (Default = current directory)
  -D            Rename directories, not files.
  --echeck      Extra check: Merely check whether file names or directory
                names contain characters not belonging to the ASCII range.
                Allowed are: 0-9, A-Z, a-z as well as - _ . and ~. The names
                containing undesirable characters are printed in the shell.
                No names are changed. This could, for instance, be used to
                check if after renaming there are still files left which
                names contain characters not taken into account.
  -f [file]     Only rename [file]. Each file must be preceded with -p.
                Note: With -f the result is only printed in the shell. There
                      is no log file and no undo script created.
  -g            Specify German language for substitutions:
                - \"&\" and \"+\" become \"_und_\" (default: \"_and_\")
                - \"°\" becomes \"_Grad_\" (default: \"_deg_\")
  -h, --help    Display this help and exit.
  --no-log      Do not create a log file in the target directory. By default on
                renaming a log file is being generated, containing the original
                names and the changed ones. (chnames_jjmmtt_hhmm.log)
  -r            Operate recursively. Does not work in combination with -f.
  -u            Generate an undo script in the target directory. In combination
                with -r there is still only one script created in the top
                directory. Just execute the undo script to restore the original
                names. (chnundo_jjmmtt_hhmm.sh)
                Note: For files / directories of the same name numbered backups
                      with the suffix ~n~ are made, where n is the number.
                      These backup files are NOT being renamed by the undo
                      script!
  --usage       Output a brief help message and exit.
  --version     Print the version information and exit.

  Note: You may only specify -d (and -D) or -f. If both parameters are
        given, only -f is taken, -d (and -D) are not.


General information:
--------------------
  chnames.sh will only work correctly when run in a UTF-8 shell. The script
  itself contains characters outside of the ISO-8859-1 range, and therefore
  has to remain UTF-8 encoded!
  
  Several checks try to find out whether a file name is encoded in ASCII,
  UTF-8, ISO-8859-1 or differently. Only names encoded in ASCII, UTF-8 and
  ISO-8859-1 are changed. Other ones are only distinguished in the shell but
  not changed. For being able to work on ISO-8859-1 encoded names, iconv has
  to be installed. If iconv is not to be found, file names of this encoding
  will only be distinguished but not renamed.
  
  Names containing German umlauts and only capital letters might need to get
  reviewed, for the umlauts Ä, Ö, Ü are changed to Ae, Oe, Ue.
  
  CAUTION: The function which checks the file name's encoding is not perfect.
           It is not guaranteed that it always functions properly, although in
           my tests up to now everything worked fine.
           Likewise, the substitutions contained in chnames.sh only provide a
           framework which may not be the optimum in every single case. So
           please, enjoy with open eyes :-)


Examples:
---------
  
  chnames.sh
    
    ==> Renames all files in the current directory. A log file is created in
        the same folder.
  
  chnames.sh -d ~/mp3/German_Stuff -g -u -r
    
    ==> Renames recursively all file names in the specified path. Replaces
        \"&\" and \"+\" by the German \"_und_\". One undo script is created
        in the top directory of the specified path, and log files in every
        processed folder.
  
  chnames.sh -D -d Jazz --no-log
    
    ==> Changes only directory names in the path given (Jazz). Does not work
        recursively. Creates no log file.
  
  chnames.sh -f \"~/mp3/Oldies/Comedian Harmonists - Wochenend und \\
  Sonnenschein.mp3\" -f \"~/mp3/Ethnic/04 - Touré Kunda - Aïyayao\"
    
    ==> Renames only the files specified with -f. The results are shown in the
        shell; no log file is created.
  
  chnames.sh -r --check
    
    ==> Pure test: What would the file names look like if they were renamed.
        Checks recursively. Results are shown in the shell.
  
  chnames.sh -r -d ~/mp3/Classic --echeck
    
    ==> This is a handy test e.g. after having renamed files already: Checks
        whether there are still undesirable characters left which were not taken
        care of. Searches recursively. Prints all the names containing spaces
        or characters not belonging to ASCII in the shell.
  

Additional tip:
---------------

  find . -name \"chnames*.log\" -exec cat \"{}\" \";\" -ok rm \"{}\" \";\"
    
    ==> That gives you a quick overview after renaming recursively:
        Finds all log files created by chnames.sh, shows their contents using
        cat, and then asks you whether to delete the log file or not.
"

echo "$HILFE" | less
}


kurzhilfe()
{
USAGE="
Usage:  chnames.sh <-d [dir]> <-D> <-g> <-r> <--check|--echeck|--no-log|-u>
-----   chnames.sh <-f [file]>... <-g> <--check|--echeck>
        chnames.sh <-h|--usage|--version>
    
  --check       A pure check: Only pretends to rename.
  -d [dir]      Specify path [dir].
  -D            Rename directories, not files.
  --echeck      Extra check: Searches for undesirable characters.
  -f [file]     Change single file or directory names; -f before each [file]
  -g            Use German for replacing \"&\", \"+\" and \"°\".
  -h, --help    Display a more detailed help and exit.
  --no-log      Do not create log files.
  -r            Change names recursively.
  -u            Generate an undo script (chnundo_jjmmtt_hhmm.sh).
  --usage       Display this brief help message and exit.
  --version     Print the version information and exit.
"

echo "$USAGE"
}


versinfo()
{
VERSION="
chnames.sh - Change file names by replacing undesirable characters.
Version from 27-Apr-2007
Copyright (C) 2005-2007 Conny Faber <conny@supple-pixels.net>
Homepage: http://www.supple-pixels.net
A German version of this script is available on http://www.supple-pixels.net.

This program is free software. See GNU General Public License for details 
(see COPYING).

Have fun :-)
"

echo "$VERSION"
}


# check encoding
checkenc()
{
NAME="${i##*/}"
ORT="${i%/*}"

# If NAME is empty after deleting all chars from ASC = ASCII
if test -z "${NAME//$ASC}" ; then
 ENC="ASCII"
else
  if test -z "${NAME//$UTF}" ; then
    ENC="UTF-8"
  else
    # If iconv is found: check whether to rename
    if test -n "$ICONVDA" ; then
      NAMECONV=`echo "$NAME" | iconv -f ISO-8859-1 -t UTF-8`
      if test -z "${NAMECONV//$LAT}" ; then
        ENC="ISO-8859-1"
      else
        ENC="unknown"
        # For function umbenennen() - Standart = 1 = rename
        UMB=0
      fi
    # Otherwise also ISO-8859-1 is unknown
    else
      ENC="unknown"
      UMB=0
    fi
  fi
fi
}


# Pure check for undesirable characters
extracheck()
{
# call function
checkenc

# VNAME = comparison name
VNAME="${NAME//$GUTZEI}"

# If there are chars left in VNAME, then they are undesirable chars.
if test -n "$VNAME" ; then
  FOUND=1
  if test "$ORT" == "`pwd`" ; then
    echo "$NAME  ...  Encoding: $ENC"
  else
    echo "${i/`pwd`\/}  ...  Encoding: $ENC"
  fi
fi
}


# Function for renaming
umbenennen()
{
# check encoding
checkenc

# Output original name
if test "$ORT" == "`pwd`" ; then
  echo "Org: $NAME"
else
  # only output relative path
  echo "Org: ${i/`pwd`\/}"
fi


# If encoding unknown: only shell output
if test $UMB -eq 0 ; then
  echo -e "---  no change  ...  encoding ${ENC}\n"

else
  
  if test "$ENC" == "ISO-8859-1" ; then
    x="$NAMECONV"
  else
    x="$NAME"
  fi
  
  # do renaming
  # -----------
  
  # replace several spaces by one
  x="`echo \"$x\" | sed 's/ \{2,\}/ /g'`"
  
  x="`echo \"$x\" | sed 's/ --* /-/g'`"  # space (at least 1x: -) space: -
  x="`echo \"$x\" | sed 's/ __* /_/g'`"  # space (at least 1x: _) space: _
  
  x="${x//. /_}"          # .space becomes _
  x="${x//,[ _]/_}"       # ,space and ,_ becomes _
  x="${x//,/.}"           # , becomes .
  
  x="${x//[\'\"\`´\?\!\^#\*¿¡]}"     # removes ' " ` ´ ? ! ^ # * ¿ ¡
  x="${x// [\[\(\{\<\]\)\}\>] /-}"   # space{[(<}])>space becomes -
  x="${x// [\[\(\{\<\]\)\}\>]/-}"    # space{[(<}])> becomes -
  x="${x//[\[\(\{\<\]\)\}\>] /-}"    # {[(<}])>space becomes -
  x="${x//[\[\(\{\<\]\)\}\>]/-}"     # {[(<}])> becomes -
  
  x="${x// /_}"           # space becomes _
  x="${x//[:\;]/.}"       # : ; becomes .
  
  # umlauts
  x="${x//ä/ae}"
  x="${x//ö/oe}"
  x="${x//ü/ue}"
  x="${x//Ä/Ae}"
  x="${x//Ö/Oe}"
  x="${x//Ü/Ue}"
  x="${x//ß/ss}"
  
  # accented characters
  x="${x//[ÀÁÂÃÅ]/A}"
  x="${x//Æ/AE}"
  x="${x//[ÇĆĈĊČ]/C}"
  x="${x//[ÈÉÊË]/E}"
  x="${x//[ÌÍÎÏ]/I}"
  x="${x//Ñ/N}"
  x="${x//[ÒÓÔÕØ]/O}"
  x="${x//[ŚŜŞŠ]/S}"
  x="${x//[ÙÚÛ]/U}"
  x="${x//Ý/Y}"
  x="${x//[ŹŻŽ]/Z}"
  x="${x//[àáâãå]/a}"
  x="${x//æ/ae}"
  x="${x//[çćĉċč]/c}"
  x="${x//[èéêë]/e}"
  x="${x//[ìíîï]/i}"
  x="${x//ñ/n}"
  x="${x//[òóôõø]/o}"
  x="${x//[śŝşš]/s}"
  x="${x//[ùúû]/u}"
  x="${x//[ýÿ]/y}"
  x="${x//[źżž]/z}"
  
  # replace + and & depending on option (-g = German)
  test $GER -eq 0 && x="${x//[\+&]/_and_}" || x="${x//[\+&]/_und_}"
  # replace ° depending on option (-g = German)
  test $GER -eq 0 && x="${x//°/_deg_}" || x="${x//°/_Grad_}"
  # - as the name's first character
  test "${x:0:1}" == "-" && x="${x/[_-]}"
  
  # reduce several consecutive . - _ ~ to 1 character . - _ ~
  x="`echo \"$x\" | sed 's/\.\{2,\}/./g'`"
  x="`echo \"$x\" | sed 's/-\{2,\}/-/g'`"
  x="`echo \"$x\" | sed 's/_\{2,\}/_/g'`"
  x="`echo \"$x\" | sed 's/~\{2,\}/~/g'`"
  
  # Remove unusual combinations which might be created by chnames.sh itself
  x="${x//-_/-}"       # -_ becomes -
  x="${x//_-/-}"       # _- becomes -
  x="${x//[_\-~]./.}"  # _. -. ~. become .
  x="${x//._/-}"       # ._ becomes - (happens more often in MP3 files)
  x="${x//.-/-}"       # .- becomes -
  x="${x//[_\-]~/~}"   # _~ -~ become ~
  x="${x//~[_\-]/~}"   # ~_ ~- become ~
  
  # There might be double characters again:
  x="`echo \"$x\" | sed 's/\.\{2,\}/./g'`"
  x="`echo \"$x\" | sed 's/-\{2,\}/-/g'`"
  x="`echo \"$x\" | sed 's/~\{2,\}/~/g'`"

  
  # regarding mv and log file
  if test "$i" != "${ORT}/$x" ; then
  
    # for writing the undo script
    CHANGED=1
    
    # renaming
    if test $CHECK -eq 0 ; then
      
      mv -f --backup=numbered "$i" "${ORT}/$x"
      
      # for undo script
      if test $USKRIPT -eq 1 ; then
        Sx="${x//\`/\\\`}"
        Sx="${Sx//\"/\\\"}"
        Si="${i//\`/\\\`}"
        Si="${Si//\"/\\\"}"
        
        SINHALT="$SINHALT
echo \"from: ${ORT}/$Sx\"
echo \"to:   $Si\"
mv -f --backup=numbered \"${ORT}/$Sx\" \"$Si\"
echo
"
      fi
    fi
    
    # output the new name in the shell
    if test "$ORT" == "`pwd`" -o "$ORT" == "." ; then
      echo -e "NEW: ${x}\n"
    else
      echo -e "NEW: ${ORT/`pwd`\/}/${x}\n"
    fi
    
    # Only write changes into the log file
    if test "$DOLOG" == "ja" ; then
      if test "$ENC" == "ISO-8859-1" ; then
        echo "Org:  $NAME (ISO-8859-1)" >> "${ORT}/chnames_${DATUM}.log"
      else
        echo "Org:  $NAME" >> "${ORT}/chnames_${DATUM}.log"
      fi
      echo -e "NEU:  ${x}\n" >> "${ORT}/chnames_${DATUM}.log"
    fi
    
  else
  
    # only shell output
    echo -e "---  no change\n"
    
  fi

fi
}


# START
# =====

# chnames.sh does NOT work correctly with bash version 2.05b.
if test ${BASH_VERSINFO[0]} -lt 3 ; then
  echo
  echo 'chnames.sh - ATTENTION! - bash-Version'
  echo
  echo 'chnames.sh was tested with bash version 2.05b and versions > 3.0.'
  echo 'With version 2.05b mistakes occurred.'
  echo 'Therefore at least version 3.0 is required.'
  echo
  echo 'chnames.sh exited'
  echo
  exit 1
fi

# If chnames.sh dos not run in a UTF-8 terminal ...
if test -z "`locale | grep 'LC_CTYPE=.*UTF-8'`" ; then
  echo
  echo "chnames.sh - ATTENTION! - UTF-8 necessary"
  echo
  echo "chnames.sh needs a UTF-8 terminal to work properly."
  echo "On systems with ISO-8859-1 locale you might, provided that the"
  echo "appropriate locale is installed, start a UTF-8 xterm using"
  echo "something like:"
  echo
  echo "  LC_CTYPE=\"de_DE.UTF-8\" xterm"
  echo
  echo "chnames.sh exited"
  echo
  exit 1
fi

# Give a message in case the script ends in an unnatural way.
trap 'echo "chnames.sh interrupted" ; echo "last position: $i" ; exit 1' 1 2 15


# 0 = default; with -f = 1
NURF=0
# current directory if no other path specified
ORT="`pwd`"
# change file names unless specified differently (d = directory)
TYP="f"
# For replacing "&", "+", and "°" (default = English = 0; German = 1)
GER=0
# create log file: ja = yes = default; nein = no = if -f or --no-log
DOLOG="ja"
# for entry in log file if no change
CHANGED=0
# for tests (--check) (0 = rename; 1 = check)
CHECK=0
# if recursive = 1
REC=0
# generate undo script = 1
USKRIPT=0
# for extra check = 1
ECHECK=0


# check parameters
while test $# -gt 0; do
  case $1 in
    --check ) CHECK=1 ; DOLOG="nein" ; USKRIPT=0 ;;
    -d ) ORT="$2" ; shift ;;
    -D ) TYP="d" ;;
    --echeck) CHECK=1 ; DOLOG="nein" ; USKRIPT=0 ; ECHECK=1
              FOUND=0 ;;
    -f ) 
         if test $NURF -eq 0 ; then
           if test $REC -eq 0 ; then
             NURF=1
             DOLOG="nein"
             USKRIPT=0
             FILES="$2"
           else
             kurzhilfe ; exit 1
           fi
         else
           FILES="${FILES}\n$2"
         fi
         shift ;;
    -g ) GER=1 ;;
    --no-log ) DOLOG="nein" ;;
    -r ) 
         # with -f recursive is not allowed
         if test -$NURF -eq 0 ; then
           REC=1
         else
           kurzhilfe ; exit 1
         fi ;;
    --version ) versinfo ; exit 0 ;;
    -u ) test $NURF -eq 0 && USKRIPT=1 || USKRIPT=0 ;;
    --usage ) kurzhilfe ; exit 0 ;;
    --help | -h ) benutzung ; exit 0 ;;
    * ) kurzhilfe ; exit 1 ;;
  esac
  shift
done

# for undo script
SORT="$ORT"

# use only new line as a delimiter
IFS=$'\n'

echo

# if extra check ...
if test $ECHECK -eq 1 ; then
  echo -e "*** chnames.sh - Starting extra check ***\n"
# if check ...
elif test $CHECK -eq 1 -a $ECHECK -eq 0 ; then
  echo -e "*** chnames.sh - Starting check ***\n"
# for renaming ...
else
  echo -e "*** chnames.sh - Starting to rename ***\n"
fi


# If -f not given ...
if test $NURF -eq 0 ; then
  
  # if not recursive ...
  if test $REC -eq 0 ; then
    OK=0
    # for extra check: test directory permission for rx
    if test $ECHECK -eq 1 ; then
      test -r "$ORT" -a -x "$ORT" && OK=1
    else
      test -r "$ORT" -a -w "$ORT" -a -x "$ORT" && OK=1
    fi
    
    # if previous tests were OK ...
    if test $OK -eq 1 ; then
      FILES=`find "$ORT" -maxdepth 1 -mindepth 1 -type "$TYP" | sort`
    else
      echo "${ORT}:"
      echo "Check your permissions!"
      echo "*** chnames.sh exited ***"
      echo
      exit 1
    fi
  
  # if recursive ...
  else
    # For renaming directories recursively, reverse sorting is needed.
    if test "$TYP" == "d" ; then
      FILES=`find "$ORT" -mindepth 1 -type "$TYP" | sort -r`
    # For renaming files: sort ascending
    else
      FILES=`find "$ORT" -mindepth 1 -type "$TYP" | sort`
    fi
  fi
fi


# If iconv is installed, also file/directory names encoded in ISO-8859-1 can
# be renamed, or with --check their encoding can be determined.
# Note: Actually convmv automatically makes a good job of recoding names; but
# it's output messages would be disturbing here. Instead of iconv, recode
# could be used as well.
ICONVDA=`which iconv`

if test -n "$ICONVDA" ; then
  # LAT = ISO-8859-1 - Not included herein: ¦¨©ª«¬­®¯²³¶·¸¹º»¼½¾
  LAT="[\]\[\!\"#\$%&\'\(\)\*\+,\-.0123456789:\;<=>\?ABCDEFGHIJKLMNOPQRSTUVWXYZ \\\^_\`abcdefghijklmnopqrstuvwxyz\{\|\}~¡¢£¤¥§°±´µ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ]"
  # UTF-8 - contains all alphanumeric characters, spaces, tab, punctuation
  UTF="[[:alnum:][:blank:][:punct:]]"
fi

# ASCII chars for checkenc() - not included here are: / @
ASC="[\]\[\!\"#\$%&\'\(\)\*\+,\-.0123456789:\;<=>\?ABCDEFGHIJKLMNOPQRSTUVWXYZ \\\^_\`abcdefghijklmnopqrstuvwxyz\{\|\}~]"

# for extracheck() - desired characters in names are:
test $ECHECK -eq 1 && \
GUTZEI="[-_~.ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789]"


# for names in log files and undo script
if test "$DOLOG" == "ja" -o $USKRIPT -eq 1 ; then
  DATUM=`date +"%y%m%d_%H%M"`
fi

# prepare undo script
if test $USKRIPT -eq 1 ; then
  
  # With -d only relative paths are used in the undo script. This is used to
  # cd into the directory, where chnames.sh originally was executed.
  CDTO=`pwd`
  
  SDATE=`date +"%c"`
  SINHALT='#!/bin/bash'
  SINHALT="$SINHALT

# chnames.sh undo script
# Generated on $SDATE

echo
echo 'chnames.sh - undo script'
echo

if test \"\$1\" != \"--do\" ; then
  echo 'Invoke \"./chnundo_jjmmtt_hhmm.sh --do\" to start renaming back.'
  echo 'Target files of the same name are overwritten, and a backup file is created.'
  echo
  exit 1
fi

echo \"Change to directory where chnames.sh was executed originally:\"
echo \"cd to ${CDTO}/\"
cd \"$CDTO\"
echo
echo 'Start renaming ...'
echo
"
fi


for i in `echo -e "$FILES"` ; do
  
  # In case problems should arise with directory later:
  WEITER="ja"
  # If there are names in ISO-8859-1: "ja"
  ISTISO="nein"
  # If encoding unknown = 0, otherwise 1 (for function umbenennen())
  UMB=1

  
  # If -f or -r: test directory permissions
  if test $NURF -eq 1 -o $REC -eq 1 ; then
    OK=0
    
    # If extra check, check directory for rx, otherwise rwx
    # (using bash only is much faster than calling dirname)
    if test $ECHECK -eq 1 ; then
      test -r "${i%/*}" -a -x "${i%/*}" && OK=1
    else
      test -r "${i%/*}" -a -w "${i%/*}" -a -x "${i%/*}" && OK=1
    fi
    
    # If previous checks were NOT OK
    if test $OK -eq 0 ; then
      WEITER="nein"
      
      # error message concerning particular directory
      echo "${i}:"
      echo "***  Procedure not possible. Check your permissions!"
      echo
    fi
  fi

  if test "$WEITER" == "ja" ; then
    
    if test $ECHECK -eq 1 ; then
      
      # call function for extra check
      extracheck
    
    else
      
      # Are files resp. directories rw?
      if test -r "$i" -a -w "$i" ; then
        # call function for renaming
        umbenennen
      else
        echo "${i}:"
        echo "***  Renaming not possible. Check your permissions!"
        echo
      fi
    fi
  fi
  
done


# If extra check ...
if test $ECHECK -eq 1 ; then
  if test $FOUND -eq 1 ; then
    echo
    echo "*** The names displayed contain undesirable characters, ***"
    echo "*** or are of a different encoding than UTF-8 or ASCII. ***"
  else
    echo "*** No undesirable names found. ***"
  fi
  echo
  echo "*** chnames.sh - extra check finished ***"
  echo

# if check
elif test $CHECK -eq 1 -a $ECHECK -eq 0 ; then
  echo "*** chnames.sh - check finished ***"
  echo

# if renaming
else
  echo "*** chnames.sh - renaming finished ***"
  echo
fi


# finish writing the undo script and set permissions (rwx------)
if test $USKRIPT -eq 1 -a $CHECK -eq 0 -a $CHANGED -eq 1 ; then
  echo "$SINHALT" > "${SORT}/chnundo_${DATUM}.sh"
  chmod 700 "${SORT}/chnundo_${DATUM}.sh"
fi
