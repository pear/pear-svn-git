#! /bin/bash

if [ -z "$1" ]; then
    echo "Prepares a PEAR package to be moved from svn.php.net to GitHub."
    echo ""
    echo "Usage:  ./1-from-svn.sh package [username]"
    echo ""
    echo " package:  the PEAR package name"
    echo " username:  the GitHub user name.  Only necessary if when using"
    echo "            GitHub's https:// style interaction"
    echo ""
    exit 1
fi
package=$1

if [ $2 ]
then
    username=$2
fi

svn_repo=http://svn.php.net/repository/pear/packages


# Quietly check:  are the dependencies installed?

tmp=`svn --version`
if [ "$?" -ne "0" ]
then
    echo "ERROR: svn must be installed and in your PATH."
    exit 1
fi

tmp=`git svn --version`
if [ "$?" -ne "0" ]
then
    echo "ERROR: git and git-svn must be installed and in your PATH."
    exit 1
fi


firstrev=`svn log -q $svn_repo/$package\
 |tail -n2\
 |head -n1\
 |awk '{split($0,a," "); print a[1]}'\
 |sed 's/r//'`
echo "First SVN revision: $firstrev"
git svn clone -s $svn_repo/$package/\
 -r $firstrev\
 --authors-file=./authors.txt
cd $package
git svn rebase

if [ $username ]
then
    git remote add origin https://$username@github.com/pear/$package.git
else
    git remote add origin git@github.com:pear/$package.git
fi 


# Create README file if necessary.
if [ -f README ]
then
    touch README
    echo "This package is http://pear.php.net/package/$package and has been migrated from $svn_repo/$package" >> README
    echo "" >> README
    echo "Please report all new issues via the PEAR bug tracker." >> README
    echo "" >> README
    echo "If this package is marked as unmaintained and you have fixes, please submit your pull requests and start discussion on the pear-qa mailing list." >> README
    echo "" >> README
    echo "To test, run either" >> README
    echo "$ phpunit tests/" >> README
    echo "  or" >> README
    echo "$ pear run-tests -r" >> README
    echo "" >> README
    echo "To build, simply" >> README
    echo "$ pear package" >> README
    echo "" >> README
    echo "To install from scratch" >> README
    echo "$ pear install package.xml" >> README
    echo "" >> README
    echo "To upgrade" >> README
    echo "$ pear upgrade -f package.xml" >> README

    git add README
    git commit -m "Added README template for $package."
fi


# Voila!

echo ""
echo "------ PEAR MIGRATION RESULT ------"
echo "The package has been converted to git format."
echo ""
echo "The next two steps are..."
echo "1) cd $package"
echo "   look around in there to make sure things look right."
echo "2) Run ../2-to-github.sh $package username password"
echo ""
