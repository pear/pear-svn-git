#! /bin/bash

if [ -z "$1" ]; then
    echo "Removes a PEAR package from svn.php.net."
    echo ""
    echo "Usage:  ./3-svn-remove.sh package"
    echo ""
    echo " package:  the PEAR package name"
    echo ""
    exit 1
fi

package=$1
svn_repo=https://svn.php.net/repository/pear/packages

# Don't touch this variable!
pear_package_repo=https://svn.php.net/repository/pear/packages


# Quietly check:  are the dependencies installed?

tmp=`svn --version`
if [ "$?" -ne "0" ]
then
    echo "ERROR: svn must be installed and in your PATH."
    exit 1
fi


svn rm $svn_repo/$package \
    -m "$package moved to https://github.com/pear/$package"
if [ "$?" -ne "0" ]
then
    echo "ERROR: could not remove $package from svn.php.net."
    exit 1
fi


if [ $svn_repo = $pear_package_repo ]
then
    echo ""
    echo "When you hit ENTER, an editor will open svn:externals for packages-all."
    echo "Please delete the line referring to $package."
    echo "Then save and close the editor."
    echo "(Press any key to continue.)"
    echo ""
    read -e

    svn propedit svn:externals https://svn.php.net/repository/pear/packages-all \
        -m "$package moved to https://github.com/pear/$package"
    if [ "$?" -ne "0" ]
    then
        echo "ERROR: could not edit properties of package-all."
        exit 1
    fi
fi


# Voila!

echo ""
echo "------ PEAR MIGRATION RESULT ------"
echo "Congratulations!  The package migration process is complete."
echo ""
