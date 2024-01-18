<?php

/*$con = mysqli_connect("localhost","root","","crud");

if(!$con){
    die('Connection Failed'. mysqli_connect_error());
}*/


$con = mysqli_init();
mysqli_ssl_set($con,NULL,NULL, "/home/adminuser/crud/DigiCertGlobalRootCA.crt.pem", NULL, NULL);
mysqli_real_connect($con, "eval-mysql-flexible-server.mysql.database.azure.com", "stanvictor", "Azerty1234", "crud", 3306, MYSQLI_CLIENT_SSL);

//If connection failed, show the error

if (mysqli_connect_errno())
{
    die('Failed to connect to MySQL: '.mysqli_connect_error());
}

?>