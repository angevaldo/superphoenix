<?php

header ('Content-type: text/html; charset=UTF-8');

// SYNCHRONIZE SCORE

require_once("includes/config.php");

$userID = openssl_decrypt( $_POST['i'], $CRYPTO_METHOD, $CRYPTO_KEY );
$userName = $_POST['n'];
$country = $_POST['c'];
$numHighScore = openssl_decrypt( $_POST['h'], $CRYPTO_METHOD, $CRYPTO_KEY );
$codHighScoreAssist = $_POST['t'];
$numCurrentScore = openssl_decrypt( $_POST['s'], $CRYPTO_METHOD, $CRYPTO_KEY );;
$codCurrentAssist = $_POST['a'];
$isOnlyProfile = $_POST['p'];
$isForceSync = $_POST['f'];

$arrReturn = array();

try { 
	
	$dbh->beginTransaction();
	
	if ($userID == '0') {
	
	    // CREATING ENTRY PROFILE
	    $stmt = $dbh->prepare(" INSERT INTO t_phoenix_score (num_id, nom_user, cod_country, dat_high_score, num_high_score, cod_assist_high_score, dat_high_score_month, num_high_score_month, cod_assist_high_score_month, dat_high_score_day, num_high_score_day, cod_assist_high_score_day) VALUES (NULL, :userName, :country, current_timestamp(), :numHighScore, :codCurrentAssist, current_timestamp(), :numHighScore, :codCurrentAssist, current_timestamp(), :numHighScore, :codCurrentAssist) ");
	    $stmt->execute(array( ":userName" => $userName, ":country" => $country, ":numHighScore" => $numHighScore, ":codCurrentAssist" => $codCurrentAssist )); 
	    $userID = $dbh->lastInsertId();
	
	
	} elseif ($isOnlyProfile == '1') {
		
	    $stmt = $dbh->prepare("
	        UPDATE t_phoenix_score 
	        SET nom_user = :userName, 
	        	cod_country = :country
	        WHERE num_id = :userID ");
	    $stmt->bindParam(':userID', $userID);
	    $stmt->bindParam(':userName', $userName);
	    $stmt->bindParam(':country', $country);
		$stmt->execute();
		
	} elseif ($isForceSync == '1') {
		
	    $stmt = $dbh->prepare("
	        UPDATE t_phoenix_score 
	        SET nom_user = :userName, 
	        	cod_country = :country,
	        	dat_high_score = current_timestamp(),
	        	num_high_score = :numHighScore, 
	        	cod_assist_high_score = :codHighScoreAssist,
	        	dat_high_score_month = current_timestamp(),
	        	num_high_score_month = :numCurrentScore,
	        	cod_assist_high_score_month = :codCurrentAssist,
	        	dat_high_score_day = current_timestamp(),
	        	num_high_score_day = :numCurrentScore,
	        	cod_assist_high_score_day = :codCurrentAssist
	    	WHERE num_id = :userID ");
	    $stmt->bindParam(':userID', $userID);
	    $stmt->bindParam(':userName', $userName);
	    $stmt->bindParam(':country', $country);
	    $stmt->bindParam(':numHighScore', $numHighScore);
	    $stmt->bindParam(':codHighScoreAssist', $codHighScoreAssist);
	    $stmt->bindParam(':numCurrentScore', $numCurrentScore);
	    $stmt->bindParam(':codCurrentAssist', $codCurrentAssist);
		$stmt->execute();
		
	} else {
		$stmt = $dbh->prepare("
			SELECT num_high_score, 
	        	num_high_score_month,
	        	DATE_FORMAT(dat_high_score_month, '%Y%m'),
	        	DATE_FORMAT(NOW(), '%Y%m'),
	        	num_high_score_day,
	        	DATE_FORMAT(dat_high_score_day, '%Y%m%d'),
	        	DATE_FORMAT(NOW(), '%Y%m%d')
			FROM t_phoenix_score
			WHERE num_id = :userID
	    ");
	    $stmt->bindParam(':userID', $userID);
	    $stmt->execute();
	    $reg = $stmt->fetch();
	    
	    $sqlSet = "";
	    $isUpdateHigh = false;
	    $isUpdateCurrent = false;
	    
	    // SCORE
	    if (intval($numHighScore) > $reg[0]) {
	    	$isUpdateHigh = true;
	        $sqlSet .= ", num_high_score = :numHighScore, dat_high_score = current_timestamp(), cod_assist_high_score = :codHighScoreAssist";
	    }
	    
	    // SCORE MONTH
	    if (intval($numCurrentScore) > $reg[1] || intval($reg[3]) > intval($reg[2])) {
	    	$isUpdateCurrent = true;
	        $sqlSet .= ", num_high_score_month = :numCurrentScore, dat_high_score_month = current_timestamp(), cod_assist_high_score_month = :codCurrentAssist";
	    }
	    
	    // SCORE DAY
	    if (intval($numCurrentScore) > $reg[4] || intval($reg[6]) > intval($reg[5])) {
	    	$isUpdateCurrent = true;
	        $sqlSet .= ", num_high_score_day = :numCurrentScore, dat_high_score_day = current_timestamp(), cod_assist_high_score_day = :codCurrentAssist";
	    }
		
	    $stmt = $dbh->prepare("UPDATE t_phoenix_score SET nom_user = :userName, cod_country = :country" . $sqlSet . " WHERE num_id = :userID ");
	    $stmt->bindParam(':userID', $userID);
	    $stmt->bindParam(':userName', $userName);
	    $stmt->bindParam(':country', $country);
	    if ($isUpdateHigh) {
		    $stmt->bindParam(':numHighScore', $numHighScore);
		    $stmt->bindParam(':codHighScoreAssist', $codHighScoreAssist);
	    }
	    if ($isUpdateCurrent) {
		    $stmt->bindParam(':numCurrentScore', $numCurrentScore);
		    $stmt->bindParam(':codCurrentAssist', $codCurrentAssist);
	    }
		$stmt->execute();
	
	}
    
	$dbh->commit();
	
	$arrReturn = array( 'i' => (openssl_encrypt($userID, $CRYPTO_METHOD, $CRYPTO_KEY)), 'h' => (openssl_encrypt($numHighScore, $CRYPTO_METHOD, $CRYPTO_KEY)), 's' => (openssl_encrypt($numCurrentScore, $CRYPTO_METHOD, $CRYPTO_KEY)));

} catch(Exception $e) { 
    $dbh->rollback(); 
    $arrReturn = array('e' => 'edbhis');
} 

// formatada em JSON
$json = json_encode($arrReturn);
echo $json;

?>