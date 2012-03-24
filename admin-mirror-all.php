<?php
$result = `svn list https://svn.php.net/repository/pear/packages`;
$result = trim($result);
$result = str_replace('/', '', $result);
$packages = preg_split('/[\r\n]+/', $result);

foreach ($packages as $package) {
   $workbench = $package . "-workbench";
   if (!file_exists($workbench)) {
       print "mkdir ". $workbench . "\n";
       print "cd " . $workbench . "\n";
       print "git-svn-mirror init --authors=../authors.txt --from=http://svn.php.net/repository/pear/packages/" . $package . "/ --to=git@github.com:pear/" . $package . ".git\n";
       print "cd ..\n";
   } else  {
       print "cd " . $workbench . "\n";
       print "git-svn-mirror update \n";
       print "cd ..\n";
   }
}
