
*********************************************************************
*	This file cleans/merges data for IC in LTC project           *	
*                                                                   *
*       - Code written by CS                                        *
*********************************************************************

clear all



 	***************************************************************
	* 1. Import and Merge RAND 2016 Biennial & Longitudinal Files *
 	***************************************************************
	
** Start with RAND biennial dataset to get some necessary variables
   use ph115 ph124 ph130 ph004 hhidpn using "$data/h16f2a.dta", clear
   
   tempfile 2016biennial
   save `2016biennial'

** Then import RAND longitudinal file 
   use inw13 ragender raracem rahispan r13mstat r13shlt r13wtrespe r13agey_e r13nhmliv ///
   r13walkr r13dress r13bath r13eat r13bed r13toilt r13phone r13money r13meds ///
   r13shop r13meals hhidpn r13wtrespe using "$data/randhrs1992_2016v2.dta",clear
   keep if inw13==1
   
   tempfile 2016longitudinal
   save `2016longitudinal'

** Merge two datasets
   use `2016longitudinal', clear
   merge 1:1 hhidpn using `2016biennial',nogen
   
** Sample restriction
   keep if r13agey_e>=65


	************************************************************************************
	* 2. Generate Vars for People living in Nursing Home & Formal Residential LTC Care *
	************************************************************************************

** Rename PH115 (Group Meals) as Meals 
   rename ph115 Meals
** Rename PH124 as ADLHELP
   rename ph124 ADLHELP 
** Rename PH130 as NURSINGHELP
   rename ph130 NURSINGHELP
** Rename PH004 as LTCRENT
   rename ph004 LTCRENT

** Formal Residential LTC Care
*** Independent Living = Meals Yes, ADL HELP No, Nursing No, RENT Yes;
   gen IL = 0
   replace IL = 1 if Meals ==1 & ADLHELP ==5 & NURSINGHELP ==5 & LTCRENT ==2
   tab IL, m 
*** Assisted Living = Meals Yes, ADL HELP Yes, Nursing No, RENT Yes;
   gen AL = 0
   replace AL = 1 if Meals ==1 & ADLHELP == 1 & NURSINGHELP ==5 & LTCRENT == 2
   tab AL, m
*** Continuing Care Retirement Community = Meals Yes, ADL HELP Yes, Nursing Yes, RENT or Own 
   gen CCRC = 0 
   replace CCRC = 1 if Meals ==1 & ADLHELP ==1 & NURSINGHELP ==1
   tab CCRC,m 
*** Combine three above because frequencies are so low for them separately
   gen FC_COMBO = 0
   replace FC_COMBO = 1 if CCRC ==1 | AL ==1 | IL ==1 
   
** Nursing Home
   gen nursinghome = 0
   replace nursinghome = 1 if r13nhmliv == 1 & CCRC!=1 & FC_COMBO==0

sa "$data/randhrs2016",replace


	***************************************
	* 3. Import 2016 HRS Core Helper File *
	***************************************
	
clear all

** Import dataset- HRS 2016 core helper file
   infile using "$data/H16G_HP.dct", using("$data/H16G_HP.da")
** Gen hhidpn using HHID and PN
   gen hhidpn = HHID+PN
   destring hhidpn, replace
** Make 6 relationship categories from dozens of options for helper relationships
   gen rel_cat = 0
   replace rel_cat = 1 if inlist(PG069,21,22,23,24,25) //Professional
   replace rel_cat = 2 if inlist(PG069,2,26,27) //Spouse/Partner
   replace rel_cat = 3 if inlist(PG069,3,8) //Son/Daughter in Law
   replace rel_cat = 4 if inlist(PG069,5,6) //Daughter/Son in law
   replace rel_cat = 5 if inlist(PG069,4,7,9,10,11,12,13,14,15,16,17,18,19,28,30,31,33,90,91)
   replace rel_cat = 6 if inlist(PG069,20,32,34,98)
   replace rel_cat = 99 if PG069 == 98 //0 represents self
** Informal helpers
   gen Informal = 0
   replace Informal = 1 if PG076 == 5 & inlist(rel_cat,1,6,99)
   replace Informal = 1 if inlist(rel_cat,2,3,4,5)
** Keep if Informal equals to 1 AND keep unique IDs for merging
   keep if Informal == 1
   bys hhidpn: gen dup = cond(_N==1,0,_n)
   drop if dup>1
   distinct hhidpn //3131 obs
   keep Informal hhidpn

   sa "$data/helper",replace
   

	***************************************
	* 4. Generate Nursing Home Sub-Sample *
	***************************************

** Identify people who are currently living in a nursing home
   use "$data/randhrs2016", clear
   keep if nursinghome==1
** Merge with helper file
   merge m:1 hhidpn using "$data/helper", nogen keep(master matched)

   sa "$data/nursinghome",replace
   

	*********************************************
	* 5. Generate Community-Dwelling Sub-Sample *
	*********************************************

** Identify people who are community-dwelling
   use "$data/randhrs2016", clear
   drop if FC_COMBO==1|nursinghome ==1 
** Merge with helper file
   merge m:1 hhidpn using "$data/helper", nogen keep(master matched)
   
   sa "$data/communitydwelling",replace
