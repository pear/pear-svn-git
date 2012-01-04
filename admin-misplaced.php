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

// Get orphaned packages, if possible.
$orphan_packages = array();
if (!function_exists('tidy_parse_string')) {
    echo "Skipping orphaned package check because tidy is not installed.\n";
} else {
    $data = file_get_contents('http://pear.php.net/qa/packages_orphan.php');
    $config = array('indent' => TRUE,
                    'output-xhtml' => true,
                    'numeric-entities' => true,
                    'wrap' => 200);

    $tidy = tidy_parse_string($data, $config);
    $tidy->cleanRepair();

    $document = simplexml_load_string((string)$tidy);
    $document->registerXPathNamespace('xhtml', "http://www.w3.org/1999/xhtml");
    $qa_package_links = $document->xpath('//xhtml:tr[2]/xhtml:td[1]/xhtml:ul/xhtml:li/xhtml:a');

    foreach ($qa_package_links as $node) {
        $orphan_packages[] = (string)$node;
    }
}

$jenkins_qa_packages = array();
$document = simplexml_load_file('http://test.pear.php.net:8080/view/Unmaintained%20QA%20packages/rssAll');
$document->registerXPathNamespace('atom', 'http://www.w3.org/2005/Atom');
$links = $document->xpath('//atom:link');

foreach ($links as $link) {
    // Example content:
    // http://test.pear.php.net:8080/job/File_SearchReplace/11/
    list(,,,$jenkins_qa_package) = explode("/", (string)$link["href"]);

    $jenkins_qa_packages[] = $jenkins_qa_package;
}

$jenkins_packages = array();
$document = simplexml_load_file('http://test.pear.php.net:8080/rssAll');
$document->registerXPathNamespace('atom', 'http://www.w3.org/2005/Atom');
$links = $document->xpath('//atom:link');

foreach ($links as $link) {
    // Example content:
    // http://test.pear.php.net:8080/job/File_SearchReplace/11/
    list(,,,$jenkins_package) = explode("/", (string)$link["href"]);

    $jenkins_packages[] = $jenkins_package;
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

$anomalies = array_diff($orphan_packages, $github);
if ($anomalies) {
    echo "---------------\n";
    echo "Orphan packages not on github:\n";
    echo implode("\n", $anomalies);
    echo "\n";
}


$anomalies = array_diff($orphan_packages, $jenkins_qa_packages);
if ($anomalies) {
    echo "---------------\n";
    echo "Orphan packages not on jenkins' unmaintained list:\n";
    echo implode("\n", $anomalies);
    echo "\n";
}

$anomalies = array_diff($github, $jenkins_packages);
if ($anomalies) {
    echo "---------------\n";
    echo "Github packages not on jenkins:\n";
    echo implode("\n", $anomalies);
    echo "\n";
}

$anomalies = array_diff($packages_all, $jenkins_packages);
if ($anomalies) {
    echo "---------------\n";
    echo "PEAR packages not on jenkins:\n";
    echo implode("\n", $anomalies);
    echo "\n";
}
