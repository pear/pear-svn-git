#! /bin/bash

if [ -z $1 ] ; then
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
if [ $? -ne 0 ] ; then
    echo "ERROR: svn must be installed and in your PATH."
    exit 1
fi


svn rm $svn_repo/$package \
    -m "$package moved to https://github.com/pear/$package"
if [ $? -ne 0 ] ; then
    echo "ERROR: could not remove $package from svn.php.net."
    exit 1
fi


if [ $svn_repo = $pear_package_repo ] ; then
    if [ -d packages-all ] ; then
        svn up packages-all --depth empty
    else
        svn checkout https://svn.php.net/repository/pear/packages-all --depth empty
    fi
    if [ $? -ne 0 ] ; then
        echo "ERROR: could not checkout package-all."
        exit 1
    fi

    svn propget svn:externals packages-all > propget.txt
    if [ $? -ne 0 ] ; then
        echo "ERROR: could not get properties of package-all."
        rm -f propget.txt
        exit 1
    fi

    sed "/$package$/d" propget.txt > propset.txt
    if [ $? -ne 0 ] ; then
        echo "ERROR: could not modify propget.txt."
        rm -f propget.txt propset.txt
        exit 1
    fi

    svn propset svn:externals packages-all -F propset.txt
    if [ $? -ne 0 ] ; then
        echo ""
        echo "ERROR: could not set properties of package-all."
        echo "Examine the propget.txt file, then run:"
        echo "svn propset svn:externals packages-all -F propset.txt"
        echo ""
        rm -f propget.txt
        exit 1
    fi

    rm -f propget.txt propset.txt

    svn commit -m "$package moved to https://github.com/pear/$package" packages-all
    if [ $? -ne 0 ] ; then
        echo "ERROR: could not commit package-all."
        exit 1
    fi
fi


# Voila!

echo ""
echo "------ PEAR MIGRATION RESULT ------"
echo "Congratulations!  The package migration process is complete."
echo ""
