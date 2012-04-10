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
    $enlistments[] = $enlistment->url;
}

$github = array();
$result = file_get_contents('https://api.github.com/orgs/pear/repos');
$result = json_decode($result);
foreach ($result as $item) {
    $github[] = 'git://github.com/pear/' . $item->name . ".git";
}

print "Things not counted on Ohloh, Oh no!\n:";
print_r(array_diff($github, $enlistments));
