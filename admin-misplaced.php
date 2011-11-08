<?php

/**
 * Finds misplaced packages in PEAR's svn.php.net and github.com repositories
 *
 * @author Daniel Convissor <danielc@php.net>
 */

// Get github.com packages.
$github = array();
$github_not_pushed = array();
$result = file_get_contents('https://api.github.com/orgs/pear/repos');
$result = json_decode($result);
foreach ($result as $item) {
    if ($item->pushed_at) {
        $github[] = $item->name;
    } else {
        $github_not_pushed[] = $item->name;
    }
}

// Get svn.php.net packages.
$result = `svn list https://svn.php.net/repository/pear/packages`;
$result = trim($result);
$result = str_replace('/', '', $result);
$packages = preg_split('/[\r\n]+/', $result);

// Get svn.php.net packages-all.
$packages_all = array();
$result = `svn propget svn:externals https://svn.php.net/repository/pear/packages-all`;
$result = trim($result);
$result = preg_split('/[\r\n]+/', $result);
foreach ($result as $item) {
    if (preg_match('/^.* ([a-z0-9_]+)$/i', $item, $atom)) {
        $packages_all[] = $atom[1];
    }
}


/*
 * Show results.
 */

$anomalies = array_intersect($github_not_pushed, $packages);
if ($anomalies) {
    echo "---------------\n";
    echo "Packages on github that have not had code copied from php.net:\n";
    echo implode("\n", $anomalies);
    echo "\n";
}

$anomalies = array_intersect($github, $packages);
if ($anomalies) {
    echo "---------------\n";
    echo "Packages on github that are still in php.net packages:\n";
    echo implode("\n", $anomalies);
    echo "\n";
}

$anomalies = array_intersect($github, $packages_all);
if ($anomalies) {
    echo "---------------\n";
    echo "Packages on github that are still in php.net packages-all:\n";
    echo implode("\n", $anomalies);
    echo "\n";
}

$anomalies = array_diff($packages, $packages_all);
if ($anomalies) {
    echo "---------------\n";
    echo "Packages on php.net in packages but not in packages-all:\n";
    echo implode("\n", $anomalies);
    echo "\n";
}

$anomalies = array_diff($packages_all, $packages);
if ($anomalies) {
    echo "---------------\n";
    echo "Packages on php.net in packages-all but not in packages:\n";
    echo implode("\n", $anomalies);
    echo "\n";
}
