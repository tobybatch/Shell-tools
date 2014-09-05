#!/bin/bash

LIST=`ls -d /var/www/sites/live/*`

for drupalpath in $LIST; do
    aliaspath=$drupalpath/sites/all/drush
    if [ -d $aliaspath ]; then
        aliasfile=`ls $drupalpath/sites/all/drush | grep -v live | sort | head -n 1`
        aliasname=`basename $aliasfile .alias.drushrc.php`
        # drush -r $drupalpath status
        # drush -r $drupalpath @$aliasname status
        drush -y -r $drupalpath rsync @$aliasname @self
        drush -y -r $drupalpath sql-sync @$aliasname @self
    fi
done
