start cmd /k "mvn -f E:\品优购双元资料V1.4_20180105\code\pinyougou-parent\pinyougou-sellergoods-service\pom.xml tomcat7:run"
@ping 127.0.0.1 -n 16 >nul
start cmd /k "mvn -f E:\品优购双元资料V1.4_20180105\code\pinyougou-parent\pinyougou-content-service\pom.xml tomcat7:run"
@ping 127.0.0.1 -n 16 >nul
start cmd /k "mvn -f E:\品优购双元资料V1.4_20180105\code\pinyougou-parent\pinyougou-search-service\pom.xml tomcat7:run"  
@ping 127.0.0.1 -n 16 >nul
start cmd /k "mvn -f E:\品优购双元资料V1.4_20180105\code\pinyougou-parent\pinyougou-page-service\pom.xml tomcat7:run"
@ping 127.0.0.1 -n 16 >nul
start cmd /k "mvn -f E:\品优购双元资料V1.4_20180105\code\pinyougou-parent\pinyougou-user-service\pom.xml tomcat7:run"
@ping 127.0.0.1 -n 16 >nul
start cmd /k "mvn -f E:\品优购双元资料V1.4_20180105\code\pinyougou-parent\pinyougou-cart-service\pom.xml tomcat7:run"
@ping 127.0.0.1 -n 16 >nul
start cmd /k "mvn -f E:\品优购双元资料V1.4_20180105\code\pinyougou-parent\pinyougou-order-service\pom.xml tomcat7:run"
@ping 127.0.0.1 -n 16 >nul
start cmd /k "mvn -f E:\品优购双元资料V1.4_20180105\code\pinyougou-parent\pinyougou-pay-service\pom.xml tomcat7:run"
@ping 127.0.0.1 -n 16 >nul
start cmd /k "mvn -f E:\品优购双元资料V1.4_20180105\code\pinyougou-parent\pinyougou-seckill-service\pom.xml tomcat7:run"