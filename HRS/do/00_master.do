********************************************************************************
		*	IC IN LTC FACILITIES	  *
********************************************************************************

/*
GENERAL NOTES:
- This is the master do-file for the IC in LTC Facilities Project.
- This do-file defines folder and data globals and allows users to choose which sections and tables to run.
- Code written by CS.
*/

********************************************************************************
	
	clear  
	capture log close
	set more off
	set maxvar 20000
	set scheme s1color
		
********************************************************************************
	*	PART 1:  PREPARING GLOBALS & DEFINE PREAMBLE	  *
********************************************************************************


* FOLDER AND DATA GLOBALS

if 1 {

*select path
gl csun  1
gl name  0

	if $csun {
	gl folder 					"/project/coe_eol/Sun/ICinLTC/"  
	}

	if $name {
	gl folder					"" /* Enter location of main folder */
	}

}


* FOLDER GLOBALS

	gl do			   		"$folder/do"
	gl log			  		"$folder/log"
	gl data			   		"$folder/data"
		
		
* CHOOSE SECTIONS TO RUN
	
	loc clean_merge		            1		
	loc sampledemographics			1		/* table 1- Sample Demographics */
	loc summarystatistics			1		/* table 2- Summary Statistics */								
							
********************************************************************************
             *	            PART 2:  RUN DO-FILES		*
********************************************************************************

* PART 1: CLEAN AND MERGE

	if `clean_merge' {
		do "$do/01_clean_merge.do"
	}		

* PART 2: CREATE TABLES	

	if `sampledemographics' {
		do "$do/02_sampledemographics.do"
	}				
			
	if `summarystatistics' {
		do "$do/02_summarystatistics.do"
	}				
		
		
		
		
		
		
		
		
		
