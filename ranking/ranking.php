<?php

header ('Content-type: text/html; charset=UTF-8');

// GET SCORE TABLE

require_once("includes/config.php");
	
$userID = openssl_decrypt ( $_POST['i'], $CRYPTO_METHOD, $CRYPTO_KEY );
$typeRank = $_POST['r'];
$isOnlyMe = $_POST['m'];
$codCountry = 'Z4'; // DEFAULT - NONE

$arrRanking = array();
$arrReturn = array();

if ($typeRank == '') {
   $typeRank = 1;
}

if ($isOnlyMe == '') {
   $isOnlyMe = 0;
}

try { 
	
	if ($isOnlyMe == 1 or $typeRank == 4) {
		$stmt = $dbh->prepare("
			SELECT cod_country
			FROM t_phoenix_score
			WHERE num_id = :userID
	    ");
	    $stmt->bindParam(':userID', $userID);
	    $stmt->execute();
	    $reg = $stmt->fetch();
	    
	    $codCountry = $reg[0];
	}
	
	function getRank($dbh, $t, $id, $country) {
		$r = 0;
		$tr = 0;
		
		if ($t == 1) {
		    $stmt = $dbh->prepare("
				SELECT count(*) AS rank 
				FROM t_phoenix_score AS p join t_phoenix_score AS s on p.num_high_score_day <= s.num_high_score_day  and s.dat_high_score_day > DATE_FORMAT(NOW() ,'%Y-%m-%d') 
				AND p.num_id = :userID and p.dat_high_score_day > DATE_FORMAT(NOW() ,'%Y-%m-%d')
				ORDER BY p.dat_high_score_day ASC
		    ");
		    $stmt->bindParam(':userID', $id);
		    $stmt->execute();
		    $reg = $stmt->fetch();
		    $r = $reg[0];
		    
		    $stmt = $dbh->prepare("
				SELECT count(*) 
				FROM t_phoenix_score
				WHERE dat_high_score_day > DATE_FORMAT(NOW() ,'%Y-%m-%d')
		    ");
		    $stmt->execute();
		    $reg = $stmt->fetch();
		    $tr = $reg[0];
		    
		} elseif ($t == 2) {
		    $stmt = $dbh->prepare("
				SELECT count(*) AS rank 
				FROM t_phoenix_score AS p join t_phoenix_score AS s on p.num_high_score_month <= s.num_high_score_month  and s.dat_high_score_month > DATE_FORMAT(NOW() ,'%Y-%m-01') 
				AND p.num_id = :userID and p.dat_high_score_month > DATE_FORMAT(NOW() ,'%Y-%m-01')
				ORDER BY p.dat_high_score_month ASC
		    ");
		    $stmt->bindParam(':userID', $id);
		    $stmt->execute();
		    $reg = $stmt->fetch();
		    $r = $reg[0];
		    
		    $stmt = $dbh->prepare("
				SELECT count(*) 
				FROM t_phoenix_score
				WHERE dat_high_score_month > DATE_FORMAT(NOW() ,'%Y-%m-01')
		    ");
		    $stmt->execute();
		    $reg = $stmt->fetch();
		    $tr = $reg[0];
		    
		} elseif ($t == 3) {
		    $stmt = $dbh->prepare("
				SELECT count(*) AS rank 
				FROM t_phoenix_score AS p join t_phoenix_score AS s on p.num_high_score <= s.num_high_score
				WHERE p.num_id = :userID
				ORDER BY p.dat_high_score ASC
		    ");
		    $stmt->bindParam(':userID', $id);
		    $stmt->execute();
		    $reg = $stmt->fetch();
		    $r = $reg[0];
		    
		    $stmt = $dbh->prepare("
				SELECT count(*) AS rank 
				FROM t_phoenix_score
		    ");
		    $stmt->execute();
		    $reg = $stmt->fetch();
		    $tr = $reg[0];
		    
		} elseif ($t == 4) {
		    $stmt = $dbh->prepare("
				SELECT count(*) AS rank 
				FROM t_phoenix_score AS p join t_phoenix_score AS s on p.num_high_score <= s.num_high_score AND s.cod_country = :country
				WHERE p.num_id = :userID
				ORDER BY p.dat_high_score ASC
		    ");
		    $stmt->bindParam(':userID', $id);
		    $stmt->bindParam(':country', $country);
		    $stmt->execute();
		    $reg = $stmt->fetch();
		    $r = $reg[0];
		    
		    $stmt = $dbh->prepare("
				SELECT count(*) AS rank 
				FROM t_phoenix_score
				WHERE cod_country = :country
		    ");
		    $stmt->bindParam(':country', $country);
		    $stmt->execute();
		    $reg = $stmt->fetch();
		    $tr = $reg[0];
		    
		}
		
		return array(0 => $r, 1 => $tr);
	}
	
	function setReturn($reg) {
		$json = json_encode($reg);
		echo $json;
	}
	
	function getWhereRank($dbh, $t, $id, $ranking) {
		if ($ranking[0] < 20) {
			return " num_rank BETWEEN 1 and 40 ";
		}
		return " num_rank BETWEEN 1 and 10 or num_rank BETWEEN ".($ranking[0]-20)." and ".($ranking[0]+20);
	}
	
	if ($userID == '' or $userID == '0') {
	   $arrReturn = array('e' => 'edbuni');
	} else {
		
		if ($isOnlyMe == 1) {
			$arrResume = array();
			for ($i = 1; $i < 5; $i++) {
				$arrRanking = getRank($dbh, $i, $userID, $codCountry);
				$arrResume[] = array(t => $i, r => $arrRanking[0]);
			}
			$arrReturn[] = $arrResume;
			setReturn($arrReturn);
			
			return;
		}
		
		$arrRanking = getRank($dbh, $typeRank, $userID, $codCountry);
		
		if ($typeRank == 1) {
		    $stmt = $dbh->prepare("
			    SELECT num_id, nom_user, cod_country, num_high_score_day, num_rank, DATE_FORMAT(dat_high_score_day,'%Y-%m-%d'), cod_assist_high_score_day 
			    FROM ( 
			        SELECT p.num_id, p.nom_user, p.cod_country, p.num_high_score_day, p.dat_high_score_day, p.cod_assist_high_score_day, @count := @count + 1 AS num_rank 
			        FROM t_phoenix_score AS p, 
		            	(SELECT @count:=0) AS q
		            WHERE p.dat_high_score_day > DATE_FORMAT(NOW() ,'%Y-%m-%d')
			      	ORDER BY p.num_high_score_day DESC, p.dat_high_score_day ASC, p.cod_assist_high_score_day ASC
			    ) AS t 
			    WHERE ".getWhereRank($dbh, $typeRank, $userID, $arrRanking));
		    $stmt->execute();
		    
		} elseif ($typeRank == 2) { 
		    $stmt = $dbh->prepare("
			    SELECT num_id, nom_user, cod_country, num_high_score_month, num_rank, DATE_FORMAT(dat_high_score_month,'%Y-%m-%d'), cod_assist_high_score_month 
			    FROM ( 
			        SELECT p.num_id, p.nom_user, p.cod_country, p.num_high_score_month, p.dat_high_score_month, p.cod_assist_high_score_month, @count := @count + 1 AS num_rank 
			        FROM t_phoenix_score AS p, 
		            	(SELECT @count:=0) AS q
		            WHERE p.dat_high_score_month > DATE_FORMAT(NOW() ,'%Y-%m-01')
			      	ORDER BY p.num_high_score_month DESC, p.dat_high_score_month ASC, p.cod_assist_high_score_month ASC
			    ) AS t 
			    WHERE ".getWhereRank($dbh, $typeRank, $userID, $arrRanking));
		    $stmt->execute();
		    
		} elseif ($typeRank == 3) { 
		    $stmt = $dbh->prepare("
			    SELECT num_id, nom_user, cod_country, num_high_score, num_rank, DATE_FORMAT(dat_high_score,'%Y-%m-%d'), cod_assist_high_score 
			    FROM ( 
			        SELECT p.num_id, p.nom_user, p.cod_country, p.num_high_score, p.dat_high_score, p.cod_assist_high_score, @count := @count + 1 AS num_rank 
			        FROM t_phoenix_score AS p, 
		            	(SELECT @count:=0) AS q
			      	ORDER BY p.num_high_score DESC, p.dat_high_score ASC, p.cod_assist_high_score ASC
			    ) AS t 
			    WHERE ".getWhereRank($dbh, $typeRank, $userID, $arrRanking));
		    $stmt->execute();
		    
		} elseif ($typeRank == 4) { 
		    $stmt = $dbh->prepare("
			    SELECT num_id, nom_user, cod_country, num_high_score, num_rank, DATE_FORMAT(dat_high_score,'%Y-%m-%d'), cod_assist_high_score
			    FROM ( 
			        SELECT p.num_id, p.nom_user, p.cod_country, p.num_high_score, p.dat_high_score, p.cod_assist_high_score, @count := @count + 1 AS num_rank 
			        FROM t_phoenix_score AS p, 
		            	(SELECT @count:=0) AS q
		            WHERE p.cod_country = '".$codCountry."'
			      	ORDER BY p.num_high_score DESC, p.dat_high_score ASC, p.cod_assist_high_score ASC
			    ) AS t 
			    WHERE ".getWhereRank($dbh, $typeRank, $userID, $arrRanking));
		    $stmt->execute();
		    
		}
	
	    $arrReturn[] = array( t => $typeRank, r=>$arrRanking[0], a=>$arrRanking[1] );
	
	    while ($reg= $stmt->fetch()) {
	        $arrReturn[] = array(
	                            i =>  ( openssl_encrypt ( $reg[0], $CRYPTO_METHOD, $CRYPTO_KEY ) ),
	                            n => $reg[1],
	                            c => $reg[2],
	                            p => intval($reg[3]),
	                            r => $reg[4],
	                            d => $reg[5],
	                            a => $reg[6]
	                        );
	    }
		
	}

} catch(Exception $e) { 
	$arrReturn = array('e' => 'edbnav'); 
}

setReturn($arrReturn);

?>