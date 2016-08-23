#!/bin/sh
#
# Update Mediawiki (git) installation to lastests wmf version.
#
#
# Register new submodules:
# cd extensions
# git submodule init Nuke
#
# Remove submodules
# cd extensions
# git submodule deinit Nuke
#
# If you dont have mediawiki yet:
# mkdir mediawiki
# git clone https://gerrit.wikimedia.org/r/p/mediawiki/core.git mediawiki
# cd mediawiki
# git submodule init vendor skins
# git submodule init extensions/ParserFunctions
# run this script
#
# I usually also install following extensions which aren't listed to submodules
# git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions/YouTube.git
# git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions/LoopFunctions.git


UPDATER=`pwd`
BACKUPTIME=$(date +"%Y%m%d-%H%M")

cd .. ; cd `git rev-parse --show-toplevel`
if [ -f LocalSettings.php ]; then
	echo "LocalSettings.php found, all good"
else
	echo "LocalSettings.php not found, is this right folder?"
	exit 1
fi

if [ `stat -c '%U' index.php` != $USER ]; then
	echo "index.php owner mismatch to current user. Update will fail. Aborting\nYou probably want to run this like: sudo -u `stat -c '%U' LocalSettings.php` ./update.sh\n"
	exit 1
fi

# Making simple backup, no images or things, just content
mkdir -p $UPDATER/backup
echo "causing error 500" > $UPDATER/backup/.htaccess
php maintenance/dumpBackup.php --full > $UPDATER/backup/$BACKUPTIME.xml

# Starting update
git fetch
BRANCH=`git for-each-ref --shell --format='%(refname)' refs/remotes/origin/wmf|sort -V|tail -n1|xargs`
git checkout $BRANCH
git submodule update --recursive

# Updating non-submodule extensions
find extensions -maxdepth 1 -type d -print -execdir git --git-dir=extensions/{}/.git --work-tree=$PWD/{} pull 2>/dev/null \;
# Updating non-submodule skins
find skins -maxdepth 1 -type d -print -execdir git --git-dir=skins/{}/.git --work-tree=$PWD/{} pull 2>/dev/null \;


echo "\n\n"


php maintenance/update.php 2> /tmp/errormsg
if grep -q composer.lock </tmp/errormsg;
then
	composer update
	php maintenance/update.php	# retry
fi
rm /tmp/errormsg
