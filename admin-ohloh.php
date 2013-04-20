<?php
/**
 * Ohloh API client
 *
 * To quickly obtain
 * $ git clone git://github.com/CloCkWeRX/Ohloh.git && cd Ohloh && pear install package.xml
 *
 * @see https://github.com/CloCkWeRX/Ohloh
 */
require_once 'Ohloh.php';

$apikey = trim(file_get_contents('ohloh.key')); // @see https://www.ohloh.net/accounts/username/api_keys

$client = new Ohloh($apikey, 'pear');
$document = $client->getAll(array($client, 'getProjectEnlistments'));

$enlistments = array();
foreach ($document->result->enlistment as $enlistment) {
    $enlistments[] = trim((string)$enlistment->repository->url);
}

$github = array();
$result = file_get_contents('https://api.github.com/orgs/pear/repos');
$result = json_decode($result);
foreach ($result as $item) {
    $github[] = trim('git://github.com/pear/' . trim($item->name) . ".git");
}

print "Things not counted on Ohloh, Oh no!\n";
foreach ($github as $gh) {
    if (!in_array($gh, $enlistments)) {
        print $gh . "\n";
    }
}

