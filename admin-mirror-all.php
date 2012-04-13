<?php
$result = `svn list https://svn.php.net/repository/pear/packages`;
$result = trim($result);
$result = str_replace('/', '', $result);
$packages = preg_split('/[\r\n]+/', $result);

foreach ($packages as $package) {
    if  ($package == 'installphars') { continue; }
    if  ($package == 'AllTests.php') { continue; }

   $workbench = $package . "-workbench";
   if (!file_exists($workbench)) {
        $paths = array();
        $paths[] = "mkdir ". $workbench;
        $paths[] = "cd " . $workbench;
        $paths[] = "git-svn-mirror init --authors=../authors.txt --from=http://svn.php.net/repository/pear/packages/" . $package . "/ --to=git@github.com:pear/" . $package . ".git";
        $paths[] = "cd ..";
        shell_exec(implode("&&", $paths));

   }
}

foreach ($packages as $package) {
    if  ($package == 'installphars') { continue; }
    if  ($package == 'AllTests.php') { continue; }

   $workbench = $package . "-workbench";
   if (file_exists($workbench)) {
       shell_exec("git-svn-mirror update $workbench");
   }
}
