********************************************************************************
		*	IC IN LTC FACILITIES	  *
********************************************************************************

/*
GENERAL NOTES:
- This is the master do-file for the IC in LTC Facilities Project.
- This do-file defines folder and data globals and allows users to choose which sections and tables to run.
*/

********************************************************************************
	
	clear  
	clear matrix
	clear mata
	capture log close
	set more off
	set maxvar 120000
	set scheme s1color
	cap ssc install estout
		
********************************************************************************
	*	PART 1:  PREPARING GLOBALS & DEFINE PREAMBLE	  *
********************************************************************************


* FOLDER AND DATA GLOBALS

if 1 {

*select path
gl csun  1
gl name  0

	if $csun {
	gl folder 					"/Users/Sophia/Desktop/Research/Norma/ICinLTC"  
	}

	if $name {
	gl folder					"" /* Enter location of main folder */
	}

}


* FOLDER GLOBALS

		gl do			   			"$folder/do"
		gl output		  			"$folder/output"
		gl log			  		 	"$folder/log"
		gl data			   			"$folder/data"
		
		
* CHOOSE SECTIONS TO RUN
	
	loc descriptive_analysis						1		/* table 1 */
	loc communitydwelling						    1		/* table 2- Community Dwelling */
	loc nursinghome					                1		/* table 2- Nursing Home */								
	loc residentialfacility					        1		/* table 2- Residential Facility */
	
							
********************************************************************************
*				PART 2:  RUN DO-FILES			*
********************************************************************************

* PART 1: Descriptive Analysis	

	if `descriptive_analysis' {
		do "$do/01descriptive_analysis.do"
	}		

* PART 2: Community Dwelling

	if `communitydwelling' {
		do "$do/02community_dwelling.do"
	}				
			
* PART 3: Nursing Home

	if `nursinghome' {
		do "$do/03nursinghome.do"
	}				
		
* PART 4: Residential Facility

	if `residentialfacility' {
		do "$do/04residentialfacility.do"
	}				
		
		
		
		
		
		
		
		
		