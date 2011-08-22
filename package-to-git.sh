#!/bin/sh
# move a PEAR package to github
if [ -z "$1" ]; then
    echo pass package name as only parameter
    exit 1
fi
package=$1

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
git remote add origin git@github.com:pear/$package.git
echo "Visit https://github.com/pear/$package now"
echo "or create it at https://github.com/organizations/pear/repositories/new"
echo "then run"
echo "$ git push -u origin master"
