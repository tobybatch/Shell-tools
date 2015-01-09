#!/bin/bash

function ntdr_aliasname {
    aliasname=$(echo $1 | awk -F '.' '{print $1}')
    isnumeric=$(echo $aliasname | grep "[^0-9]")
    if [ -z "$isnumeric" ]; then
      # The first element is a numer, it's probably an IP
      echo $1
    else
      echo $aliasname
    fi
}

function ntdr_bumpUp {
    MAJOR_VERSION=$1
    MINOR_VERSION=$2
    PATCH_VERSION=$3
    BUMP=$4

    until [ "$BUMP" == "patch" ] || [ "$BUMP" == "minor" ] || [ "$BUMP" == "major" ]; do
        echo -n "Bump which version Major|mInor|Patch? [m/i/P]? "
        read a
        case $a in
            M) BUMP=major;;
            m) BUMP=major;;
            I) BUMP=minor;;
            i) BUMP=minor;;
            P) BUMP=patch;;
            p) BUMP=patch;;
        esac
    done
    
    case $BUMP in
        patch) PATCH_VERSION=$(($PATCH_VERSION + 1));;
        minor) MINOR_VERSION=$(($MINOR_VERSION + 1)); PATCH_VERSION=0;;
        major) MAJOR_VERSION=$(($MAJOR_VERSION + 1)); MINOR_VERSION=0; PATCH_VERSION=0;;
    esac            

    export PATCH_VERSION
    export MINOR_VERSION
    export MAJOR_VERSION
}

function ntdr_checkRemoteDirExists {
    RUSER=$1
    RHOST=$2
    RPATH=$3
    set +e
    ssh $RUSER@$RHOST ls -d $RPATH > /dev/null
    if [ "$?" != 0 ]; then
        echo -e $COL_RED"${RUSER}@${RHOST}:${RPATH} does not exist."$COL_REST
        exit 1
    fi
    set -e
}

# check the most common write permission
function ntdr_checkWritePerms {
    if [ ! -w "$DRUPAL_LOCAL_ROOT" ] ; then
        echo -e $COL_RED"Cannot write to ${DRUPAL_LOCAL_ROOT}. Writting change log will fail."$COL_RESET
        echo -e $COL_CYAN"chown $USER:`id -gn $USER` ${DRUPAL_LOCAL_ROOT}"$COL_RESET
        echo -e $COL_CYAN"chown $USER:`id -gn $USER` ${DRUPAL_LOCAL_ROOT}/changelog.txt"$COL_RESET
        exit 1
    fi

    if [ ! -w "$DRUPAL_LOCAL_ROOT/sites/all/drush" ] ; then
        echo -e $COL_RED"Cannot write to ${DRUPAL_LOCAL_ROOT}/sites/all/drush. Writting alias file log will fail."$COL_RESET
        echo -e $COL_CYAN"chown $USER:`id -gn $USER` ${DRUPAL_LOCAL_ROOT}/sites/all/drush"$COL_RESET
        exit 1
    fi

    if [ ! -w "$DRUPAL_LOCAL_ROOT/sites/default" ] ; then
        echo -e $COL_RED"Cannot write to ${DRUPAL_LOCAL_ROOT}/sites/default Writting new settings file log will fail."$COL_RESET
        echo -e $COL_CYAN"chown $USER:`id -gn $USER` ${DRUPAL_LOCAL_ROOT}/sites/default"$COL_RESET
        exit 1
    fi
}

# Check we have required params
function ntdr_checkParams {
    if [ -z $RUSER ]; then
        echo -e $COL_RED"Missing remote user"$COL_RESET
        echo $USAGE
        exit 1
    elif [ -z $RHOST ]; then
        echo -e $COL_RED"Missing remote host"$COL_RESET
        echo $USAGE
        exit 1
    elif [ -z "$DRUPAL_LOCAL_ROOT" ] || [ ! -f "$DRUPAL_LOCAL_ROOT/cron.php" ]; then
        echo -e $COL_RED"The local drupal root ($DRUPAL_LOCAL_ROOT) does not seem to be a drupal site"$COL_RESET
        exit 1
    fi
}

function ntdr_createAlias {
    DRUPAL_LOCAL_ROOT=$1
    RELEASE=$2
    RHOST=$3

    RELEASE_ALIAS=$(ntdr_aliasname $RHOST)
    ALIAS_PATH=$DRUPAL_LOCAL_ROOT/sites/all/drush
    mkdir -p $ALIAS_PATH
    ALIAS_FILE=$ALIAS_PATH/$RELEASE.$RELEASE_ALIAS.alias.drushrc.php
    echo '<?php' > $ALIAS_FILE
    drush -r $DRUPAL_LOCAL_ROOT sa --full --with-db @self >> $ALIAS_FILE
    sed -i "s/'root' => .*/'root' => '\/var\/www\/$RELEASE',/g" $ALIAS_FILE
    sed -i "s/self/${RELEASE}.${RELEASE_ALIAS}/g" $ALIAS_FILE
    sed -i "/#name/a  'remote-host' => '${RHOST}'," $ALIAS_FILE
    sed -i "/#name/a  'remote-user' => '${RUSER}'," $ALIAS_FILE
    sed -i "s/        'database' => .*/      'database' => '$RELEASE',/g" $ALIAS_FILE
    sed -i "s/        'username' => .*/      'username' => '$RELEASE',/g" $ALIAS_FILE
    sed -i "s/        'password' => .*/      'password' => '$RELEASE',/g" $ALIAS_FILE
}

function ntdr_createChangeLog {
    DRUPAL_LOCAL_ROOT=$1
    RELEASE=$2
    
    touch $DRUPAL_LOCAL_ROOT/changelog.txt
    echo "+----- $RELEASE -----+" > $DRUPAL_LOCAL_ROOT/changelog.new
    date +"%y-%m-%d_%H-%M" >> $DRUPAL_LOCAL_ROOT/changelog.new
    set +e
    branches -l -p $DRUPAL_LOCAL_ROOT >> $DRUPAL_LOCAL_ROOT/changelog.new
    if [ "$?" != 0 ]; then
        echo $COL_RED"Git branches are out of sync: 'branches -l -p $DRUPAL_LOCAL_ROOT'"$COL_RESET
    fi
    set -e
    echo -e "\n" >> $DRUPAL_LOCAL_ROOT/changelog.new
    cat $DRUPAL_LOCAL_ROOT/changelog.txt >> $DRUPAL_LOCAL_ROOT/changelog.new
    mv $DRUPAL_LOCAL_ROOT/changelog.new $DRUPAL_LOCAL_ROOT/changelog.txt
}

function ntdr_createRemoteDB {
    RUSER=$1
    RHOST=$2
    RPATH=$3
    PASS=$4
    RELEASE=$5

    set +e
    ssh $RUSER@$RHOST "mysql-checkuser -u ${RELEASE} -m ${PASS}"
    RETVAL=$?
    set -e
    if [ "$RETVAL" != 0 ]; then
        _DUMP_FILE=${RELEASE}-`date +"%y-%m-%d_%H-%M"`.sql
        ntdr_debug "${COL_CYAN}User or DB ${RELEASE} exists, dumping it to ${_DUMP_FILE}${COL_RESET}"
        ntdr_dumpRemoteDB $RUSER $RHOST $RPATH /var/tmp/$_DUMP_FILE
    else
        echo ssh $RUSER@$RHOST "mysql-create-user-and-db -u ${RELEASE} -p ${RELEASE} -m ${PASS}"
        ssh $RUSER@$RHOST "mysql-create-user-and-db -u ${RELEASE} -p ${RELEASE} -m ${PASS}"
    fi
}

function ntdr_createSettingFile {
    DRUPAL_LOCAL_ROOT=$1
    RELEASE=$2
    
    ntdr_debug "${COL_CYAN}Prepare ${RELEASE}_settings.php for release${COL_RESET}"
    LOCAL_SETTINGS_DIR=$DRUPAL_LOCAL_ROOT/sites/default
    LOCAL_SETTINGS=$LOCAL_SETTINGS_DIR/settings.php
    TMP_SETTINGS=$LOCAL_SETTINGS_DIR/${RELEASE}_settings.php
    chmod 755 $LOCAL_SETTINGS_DIR
    if [ -e "$TMP_SETTINGS" ]; then
        chmod 664 $TMP_SETTINGS
    fi
    cp $LOCAL_SETTINGS $TMP_SETTINGS
    sed -i "s/      'database' => .*/      'database' => '$RELEASE',/g" $TMP_SETTINGS
    sed -i "s/      'username' => .*/      'username' => '$RELEASE',/g" $TMP_SETTINGS
    sed -i "s/      'password' => .*/      'password' => '$RELEASE',/g" $TMP_SETTINGS
    chmod 555 $LOCAL_SETTINGS_DIR $TMP_SETTINGS
}

function ntdr_debug {
    if [ ! -z "$VERBOSE" ]; then
        echo -e $1
    fi
}

function ntdr_dumpRemoteDB {
    RUSER=$1
    RHOST=$2
    RPATH=$3
    DUMPFILE=$4
    ssh $RUSER@$RHOST "drush -r $RPATH sql-dump --ordered-dump --structure-tables-key=common > $DUMPFILE"
}

function ntdr_remotePath {
    export RPATH=`ssh $1@$2 realpath $3`
    export CURRENT=`basename $RPATH`

    echo $RPATH
}

function ntdr_usage {
    echo $USAGE
    cat <<EOF

Take a local drupal install and publish it to a remote site.  It wll create a
DB and copy the 'live' site into it. This script needs to have an existing site
in place to operate on and that site must have a functional drush alias. The 
files from the local site will be pushed up to the live site and the current
live site databse will be copied into the new drupal.

Manadtory Parameters
--------------------
remoteuser
  This user MUST have passwordless key based authentication to the remote 
  server. An ssh-agent can be used but the process should be non-interactive
remotehost
  The host to publish the site to.

Optional Parameters
-------------------
-v
  Be verbose
-h
  Print this message
-r remote-drupal-root
  The path to the root of the dir holding the remote drupal root. This is the
  folder that will checked for the latest|testing|rc symlinks. Defualts to
  /var/www
-b <major|minor|bump>]
  Sites are release in a x.y.z format where versions are major.minor.patch
  The script will bump that version by one in the category specified. If
  ommitted the script will ask.
-f release
  If specified this release value will override the m.m.p number
-m mysql-root-pass
  The script expects to find the remote mysql root password in an environment
  variable MYSQL_ROOT_PASSWORD. This parameter can override that.
EOF
}

function ntsl_usage {
    echo $USAGE
    cat <<EOF

Send the site live.  It will:
  * Put the site into maintenance mode
  * Dump the live DB on the server
  * rysnc files folder form latest over test
  * Overwrite the testing db with the live db
  * Copy the latest robots.txt into testing
  * Unlock the test site
  * Swap the sym links

The 'live' site is the latest sym link and thetesting site is the testing
symlink

Optional Parameters
-------------------
-v
  Be verbose
-h
  Print this message
-r remote-drupal-root
  The path to the root of the dir holding the remote drupal root. This is the
  folder that will checked for the latest|testing|rc symlinks. Defualts to
  /var/www
EOF
}

function ntdr_versionElements {
    export BRAND=`echo $1|awk '{split($0,a,"_"); print a[1]}'`
    export NOBC=`echo $1|awk '{split($0,a,"_"); print a[2]}'`
    if [ "$BRAND" == "$1" ]; then
        NOBC=$BRAND
        unset BRAND
    fi
    export MAJOR_VERSION=`echo $NOBC|awk '{split($0,a,"."); print a[1]}'`
    export MINOR_VERSION=`echo $NOBC|awk '{split($0,a,"."); print a[2]}'`
    export PATCH_VERSION=`echo $NOBC|awk '{split($0,a,"."); print a[3]}'`
}

# vim: filetype=sh:ts=4:sw=4:expandtab
