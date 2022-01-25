
*********************************************************************
*	This file creates sample demographics for IC in LTC project  *	
*                                                                   *
*       - Code written by CS                                        *
*********************************************************************

clear all

foreach sample in nursinghome communitydwelling {
	
	capture log close
	log using "$log/`sample'_table1.log", replace
	
	use "$data/`sample'", clear
	
	
	*\ Age
	*** mean
	summarize r13agey_e 
	summarize r13agey_e [aweight=r13wtrespe]

	*\ Gender
	tab ragender, m 
	tab ragender[aweight=r13wtrespe], m

	*\ Race and Ethnicity
	gen Race_Ethinic = 0
	replace Race_Ethinic=1 if raracem == 1 & rahispan == 0 //non-Hispanic white
	replace Race_Ethinic=2 if raracem == 2 & rahispan == 0 //non-Hispanic black
	replace Race_Ethinic=3 if raracem == 3 & rahispan == 0 //non-Hispanic other
	replace Race_Ethinic=4 if rahispan == 1 //Hispanic-regardless of race
	
	tab Race_Ethinic, m 
	tab Race_Ethinic[aweight=r13wtrespe], m

	*\ Marital Status
	gen Marital_Status = 0
	replace Marital_Status = 1 if inlist(r13mstat,1,2,3) //Married/Living with partner
	replace Marital_Status = 2 if inlist(r13mstat,4,5,7) //Divorced/Separate/Widowed
	replace Marital_Status = 3 if r13mstat==8 //Never married
	
	tab Marital_Status, m
	tab Marital_Status[aweight=r13wtrespe], m

	*\ Self-reported health
	rename r13shlt selfreportedhealth
	replace selfreportedhealth = 0 if selfreportedhealth == .r | selfreportedhealth == .d
	
	tab selfreportedhealth, m
	tab selfreportedhealth[aweight=r13wtrespe], m

}

