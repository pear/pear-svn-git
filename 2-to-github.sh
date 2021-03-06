#! /bin/bash

if [ -z $2 ] ; then
    echo "Creates a repository on GitHub and pushes the PEAR package to it."
    echo ""
    echo "cd into the package's directory, then call this script."
    echo ""
    echo "Usage:  ../2-to-github.sh package username [password]"
    echo ""
    echo " package:  the PEAR package name"
    echo " username:  your GitHub user name"
    echo " password:  your GitHub website password (optional). If omitted,"
    echo "            you will be prompted for it if actions require it."
    echo ""
    exit 1
fi

package=$1
user=$2
api=https://api.github.com


# Quietly check:  are the dependencies installed?

tmp=`curl --version`
if [ $? -ne 0 ] ; then
    echo "ERROR: curl must be installed and in your PATH."
    exit 1
fi

tmp=`svn --version`
if [ $? -ne 0 ] ; then
    echo "ERROR: svn must be installed and in your PATH."
    exit 1
fi

tmp=`git --version`
if [ $? -ne 0 ] ; then
    echo "ERROR: git must be installed and in your PATH."
    exit 1
fi


# Is this script being called from a valid location?

if [[ `basename "$PWD"` != $package ]] ; then
    echo "ERROR: cd to the $package directory before calling this script."
    exit 1
fi

if [ ! -d .git ] ; then
    echo "ERROR: the $package directory is not a git repository."
    exit 1
fi


# Obtain the GitHub website password.

if [ $3 ] ; then
    pass=$3
    echo ""
    echo "NOTICE: password is now optional."
    echo "This script will ask for it interactively, if it is required."
    echo ""
else
    echo ""
    echo -n "What is your GitHub website password? "
    read -e -s pass
    echo ""
fi

if [ -z $pass ] ; then
    echo "ERROR: actions taken require a password, but none was provided."
    exit 1
fi


# Workaround for some curl installs not acknowledging proxy.

if [ $HTTPS_PROXY ] ; then
    curl_args="--proxy $HTTPS_PROXY"
elif [ $http_proxy ] ; then
    curl_args="--proxy $http_proxy"
else
    curl_args=
fi


# Does the repository exist on GitHub?

response=`curl $curl_args -s -S $api/repos/pear/$package`
if [ $? -ne 0 ] ; then
    echo "ERROR: curl had problem calling GitHub search API."
    exit 1
elif [[ $response == *'"Not Found"'* ]] ; then
    # Repository not there yet; create it in the pear-dev team.

    post="{\"name\":\"$package\", \"homepage\":\"http://pear.php.net/package/$package\", \"team_id\":83068, \"has_issues\":false, \"has_wiki\":false}"
    response=`curl $curl_args -s -S -u "$user:$pass" -d "$post" $api/orgs/pear/repos`
    if [ $? -ne 0 ] ; then
        echo "ERROR: curl had problem calling GitHub create API."
        exit 1
    elif [[ $response == *'"message"'* ]] ; then
        # The API returned some other error.
        echo "GitHub API create ERROR: $response"
        exit 1
    fi
elif [[ $response == *'"message"'* ]] ; then
    # The API returned some other error.
    echo "GitHub API search ERROR: $response"
    exit 1
fi


# Create hooks.

post="{\"name\":\"email\", \"config\":{\"address\":\"pear-cvs@lists.php.net\", \"send_from_author\":true}}"
response=`curl $curl_args -s -S -u "$user:$pass" -d "$post" $api/repos/pear/$package/hooks`
if [ $? -ne 0 ] ; then
    echo "ERROR: curl had problem calling GitHub email hooks API."
    exit 1
elif [[ $response == *'"errors"'* ]] ; then
    # The API returned some other error.
    echo "GitHub API hooks ERROR: $response"
    exit 1
fi

post="{\"name\":\"web\", \"config\":{\"url\":\"http://test.pear.php.net:8080/github-webhook/\"}}"
response=`curl $curl_args -s -S -u "$user:$pass" -d "$post" $api/repos/pear/$package/hooks`
if [ $? -ne 0 ] ; then
    echo "ERROR: curl had problem calling GitHub web hooks API."
    exit 1
elif [[ $response == *'"errors"'* ]] ; then
    # The API returned some other error.
    echo "GitHub API hooks ERROR: $response"
    exit 1
fi


# Everything is ready.  Push the package up.

git push -u origin master
if [ $? -ne 0 ] ; then
    echo "ERROR: problem pushing $package to GitHub."
    exit 1
fi


# Voila!

echo ""
echo "------ PEAR MIGRATION RESULT ------"
echo "The package has been pushed to GitHub."
echo ""
echo "There are three things left to do..."
echo "1) Check that everything looks right on the GitHub website:"
echo "   https://github.com/pear/$package"
echo ""
echo "2) Edit the package's \"Web version control URI\" at"
echo "   https://pear.php.net/package/$package/"
echo "   Set it to:  https://github.com/pear/$package"
echo ""
echo "3) Edit the package's settings in Jenkins:"
echo "   Go to http://test.pear.php.net:8080/job/$package/ ."
echo "   Log in with your standard PEAR username and password."
echo "   Click \"Configure\", scroll to the \"Source Code Management\" section."
echo "   Click the \"Git\" radio button."
echo "   Put the following in the \"Repository URL\":"
echo "   \"https://github.com/pear/$package.git\" ."
echo ""
echo "4) cd .."
echo ""
echo "5) Run ./3-svn-remove.sh $package"
echo ""
