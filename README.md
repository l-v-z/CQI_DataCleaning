# CQI_DataCleaning
Data cleaning of a messy dataset using python and SQL (Azure Data Studio) to prepare it for later use in Tableau


To begin, the arabica_data.csv file needs to be prepared for loading into Azure Data Studio by running pre-cleaning.py. 
It will then produce coffee_data.csv which needs to be loaded into Data Studio with the default data type settings but will null values allowed in eavery column. 
Once coffee_data.csv is loaded into a table in Data Studio, it has to be cleaned using the queries from cqi_data_cleaning.sql which will make
the necessary changes to the file so that we can later use the data for Tableau visualizations. 
