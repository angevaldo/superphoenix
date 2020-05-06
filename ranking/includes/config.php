<?php

// CONNECTION

require_once("setup.php");

error_reporting(E_ERROR | E_PARSE);

$dbh;

try {

    $dbh = new PDO("mysql:host=$DB_HOST;dbname=$DB_NAME;port=$DB_PORT", $DB_USERNAME, $DB_PASSWORD);
    if (!$dbh) {
        throw new Exception('edbcon');
    } 

} catch (Exception $e) {
    //$e->getMessage()
    
    $arrRetorno = array('e' => 'edbcon');
    $json = json_encode($arrRetorno);
    echo $json;
    die('');
}

?>