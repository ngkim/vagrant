# -*- coding: utf-8 -*-

"""

  프로젝트에서 사용되는 모든 데이터베이스 질의문 템플릿
  보통 요즘은 ORM을 많이 사용하나 개발 생산성과 관리를 위해 템플릿을 사용
  나중에 여러명이 함께 개발할 때는 ORM 사용

"""

##########################################################################
#  모니터링 테이블 스키마 -> 여기는 당사자가 알아서 만들어 쓰시요
##########################################################################

paxnet_stock_list_table_query = {

    'create_stock_list': """    
        DROP TABLE IF EXISTS `stock_list`;
        
        CREATE TABLE `mon_list` (
          `id`             bigint(20)  NOT NULL AUTO_INCREMENT,                
          `col_date`       date        DEFAULT NULL,
          `col_site`       varchar(20) NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY (stock_name)
        ) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8
        
    """,
    
    'insert_stock_list_info': """
    
        REPLACE INTO mon_list
            (id, col_date, col_site)
        VALUES (
              0, %s, %s, %s, %s, %s
        )
    
    """

}