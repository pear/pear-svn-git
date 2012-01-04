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
    list(,,,,$jenkins_qa_package) = explode("/", (string)$link["href"]);

    $jenkins_qa_packages[] = $jenkins_qa_package;
}
$jenkins_qa_packages = array_unique($jenkins_qa_packages);

$jenkins_packages = array();
$document = simplexml_load_file('http://test.pear.php.net:8080/rssAll');
$document->registerXPathNamespace('atom', 'http://www.w3.org/2005/Atom');
$links = $document->xpath('//atom:link');

foreach ($links as $link) {
    // Example content:
    // http://test.pear.php.net:8080/job/File_SearchReplace/11/
    list(,,,,$jenkins_package) = explode("/", (string)$link["href"]);

    $jenkins_packages[] = $jenkins_package;
}
$jenkins_packages = array_unique($jenkins_packages);
/*
 * Show results.
 */

$anomalies = array_diff(array_intersect($jenkins_packages, $orphan_packages), $jenkins_qa_packages);
if ($anomalies) {
    echo "---------------\n";
    echo "Orphan packages not on jenkins' unmaintained list, but with a build:\n";
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

$anomalies = array_diff($packages, $jenkins_packages);
if ($anomalies) {
    echo "---------------\n";
    echo "PEAR packages not on jenkins:\n";
    echo implode("\n", $anomalies);
    echo "\n";
}
