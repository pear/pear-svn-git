<?php

/**
 * Fixes the svn:externals property for the packages-all directory
 *
 * Gets the list of all packages in svn.php.net/repository/pear/packages
 * and uses that to update the svn:externals property of
 * svn.php.net/repository/pear/packages-all.
 *
 * @author Daniel Convissor <danielc@php.net>
 */

// Get svn.php.net packages.
$result = `svn list https://svn.php.net/repository/pear/packages`;
$result = trim($result);
$result = str_replace('/', '', $result);
$packages = preg_split('/[\r\n]+/', $result);

$ignore = array('AllTests.php', 'PEAR', 'installphars');
$packages = array_diff($packages, $ignore);

$out = '';
foreach ($packages as $package) {
    $out .= " https://svn.php.net/repository/pear/packages/$package/trunk $package\n";
}

file_put_contents('./propfix.txt', $out);

echo <<<EOF
Now issue the following commands:
    svn up packages-all --depth empty
    svn propset svn:externals packages-all -F propfix.txt
    svn commit -m 'The latest externals.' packages-all

EOF;
