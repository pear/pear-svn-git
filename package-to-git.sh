#!/bin/sh
# move a PEAR package to github
if [ -z "$1" ]; then
    echo "Usage: ./package-to-git.sh package [username]"
    echo "	- package must be a valid PEAR package hosted in PEAR SVN"
    echo "	- username only needs to be specified to utilise the https:// style of github interaction"
    exit 1
fi
package=$1

if [ $2 ]
then
    username=$2
fi


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


firstrev=`svn log -q http://svn.php.net/repository/pear/packages/$package\
 |tail -n2\
 |head -n1\
 |awk '{split($0,a," "); print a[1]}'\
 |sed 's/r//'`
echo "First SVN revision: $firstrev"
git svn clone -s http://svn.php.net/repository/pear/packages/$package/\
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

touch README
echo "This package is http://pear.php.net/package/$package and has been migrated from http://svn.php.net/repository/pear/packages/$package" >> README
echo "" >> README
echo "Please report all new issues via the PEAR bug tracker." >> README
echo "" >> README
echo "If this package is marked as unmaintained and you have fixes, please submit your pull requests and start discussion on the pear-qa mailing list." >> README
echo "" >> README
echo "To test, run either" >> README
echo "$ phpunit tests/" >> README
echo "Or" >> README
echo "$ pear run-tests -r" >> README
echo "" >> README
echo "To build, simply" >> README
echo "$ pear package" >> README
echo "To install from scratch" >> README
echo "$ pear install package.xml" >> README
echo "To upgrade" >> README
echo "$ pear upgrade -f package.xml" >> README

git add README
git commit -m "Added README template for $package."

echo "Visit https://github.com/pear/$package now"
echo "or create it at"
echo " https://github.com/organizations/pear/repositories/new"
echo " + disable issues and wiki"
echo "then run"
echo " $ git push -u origin master"
echo ""
echo "When all went fine, remove it from svn:"
echo " svn rm https://svn.php.net/repository/pear/packages/$package -m '$package moved to https://github.com/pear/$package'"
#echo "Windows users may need to set SVN_EDITOR=notepad.exe"
echo " svn propedit svn:externals https://svn.php.net/repository/pear/packages-all -m '$package moved to https://github.com/pear/$package'"
