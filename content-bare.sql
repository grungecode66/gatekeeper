USE cromaca;

CREATE TABLE CONTENT (
     content_id INT NOT NULL AUTO_INCREMENT,
     content_sid VARCHAR(32) NOT NULL,
     content_file VARCHAR(64) NOT NULL,
     content_subject INT,
     content_add_date DATE NOT NULL,
     content_proc_ind INT DEFAULT 0,
     content_type,
     content_source VARCHAR(64) 
     PRIMARY KEY (content_sid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
 


