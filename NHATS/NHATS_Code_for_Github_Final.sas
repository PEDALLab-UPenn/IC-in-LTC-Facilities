/*******************************************************************************
** PROJECT: INFORMAL CAREGIVING IN LONG TERM CARE SETTINGS
** PROGRAM NAME: NHATS R AND R CODE FOR GITHUB FINAL.SAS
** DATE: 9/8/2021
** AUTHOR: ET

** PURPOSE:    
	1. REVIEWERS REQUESTED ADDING IN  HOURS OF INFORMAL CARE TO THE NHATS TABLE AND Ns
	2. USE XINWEI'S FINAL DATASET "/PATH/norma_cohort_20210517.csv" AND MAKE INTO SAS TEMPORARY DATASET
	3. ADD IN NHATS HOURS OF CARE FROM OP FILE, SUM ON RESPONDENT (EXCLUDE HELPERS WITH 31 OR 37 RELATIONSHIP)
	4. NEED TO REMAKE SPECIFIC HELP VARIABLES 
	4. MERGE TOGETHER
	5. USE PROCSURVEY MEANS AND PROC SURVEYFREQ (DID NOT RUN XINWEI'S RSTUDIO CODE)**********/ 

libname revision "/PATH/Data/";

proc import datafile="/PATH/norma_cohort_20210517.csv"
        out=revision.norma_cohort_20210517
        dbms=csv
        replace;
		getnames=yes;
run; /*N=7574*/ 
	
proc contents data = revision.norma_cohort_20210517; 
	title "CHECK NORMA'S DATASET FOR DURATION OF CARE/HELPER HOURS"; 
run; 	
/*DROP XINWEI'S HELPER VARIABLES AND REMAKE VARIABLES - WILL USE THE SAME VAR NAMES*/ 
data norma_cohort_20210517; 
	set revision.norma_cohort_20210517; 
	
	drop mo_out mo_in mo_bed sc_eat sc_bath sc_toil sc_dres 
	ha_laun ha_shop ha_meal ha_bank mc_med

	mo_out_edit mo_in_edit mo_bed_edit sc_eat_edit sc_bath_edit sc_toil_edit sc_dres_edit 
	ha_laun_edit ha_shop_edit ha_meal_edit ha_bank_edit mc_med_edit

	mo_out_edit2 mo_in_edit2 mo_bed_edit2 sc_eat_edit2 sc_bath_edit2 sc_toil_edit2 sc_dres_edit2 
	ha_laun_edit2 ha_shop_edit2 ha_meal_edit2 ha_bank_edit2 mc_med_edit2	
			
	mo_help sc_help ha_help mc_help 
	mo_help2 sc_help2 ha_help2 mc_help2 ;
run; 

/*DOWNLOADED THE OP (OTHER PERSON FILE)INTO R&R FOLDER RAN SAS CODE "NHATS_ROUND_5_OP_READ_V2.SAS" TO CREATE THE NHATS ROUND 5 OP FILE

/*WILL COLLAPSE OP5DHRSMTH TO THE RESPONDENT LEVEL, THEN MATCH ON REPSONDENT ID BACK TO NORMA'S FINAL DATASET, MADE BY XINWEI*/ 
proc means data= revision.opfile nmiss n min mean median max; 
	var op5dhrsmth op5numdayswk op5numdaysmn op5numhrsday; 
	title "CHECK NHATS DATA I PULLED IN FOR THE VARIABLE I NEED FOR HOURS OF CARE";
run; 
proc freq data = revision.opfile;
	table op5dhrsmth; 
	title "LOOK FOR FREQUENCIES OF MISSING CODES, -13, -11, -9, -12, -1 and 9999";
run; 
proc freq data = revision.opfile; 
	table  op5relatnshp; /*MISSING GOES TO 44,310*/ 
	where op5paidhelpr =1;
	title "CHECK RELATIONSHIPS OF PAID HELPERS";
run; 
proc freq data = revision.opfile; 
	table op5dhrsmth op5relatnshp op5paidhelpr 
	op5outhlp op5insdhlp op5bedhlp op5eathlp op5bathhlp op5toilhlp
	op5dreshlp op5launhlp op5shophlp op5mealhlp op5bankhlp op1medshlp; /*MISSING GOES TO 44,310*/ 
	title "LOOK FOR FREQUENCIES OF MISSING CODES, -13, -11, -9, -12, -1 and 9999";
run; 
/*THIS IS A DATASET OF INFORMAL HELPERS*/ 
data opfile; /*N=49,835*/ 
	set revision.opfile; /*N=52,285*/ 
	/*CODE THOSE MISSINGS TO ., SO WE CAN SUM THEM BY RESPONDENT*/ 
	if op5dhrsmth in ( -13, -11, -9, -12, -1, 9999) then op5dhrsmth = .; 
	if op5outhlp  in ( -13, -11, -9, -12, -1, 9999) then op5outhlp = .; 
	if op5insdhlp in ( -13, -11, -9, -12, -1, 9999) then op5insdhlp = .; 
	if op5bedhlp  in ( -13, -11, -9, -12, -1, 9999) then op5bedhlp = .; 
	if op5eathlp  in ( -13, -11, -9, -12, -1, 9999) then op5eathlp = .; 
	if op5bathhlp in ( -13, -11, -9, -12, -1, 9999) then op5bathhlp = .; 
	if op5toilhlp in ( -13, -11, -9, -12, -1, 9999) then op5toilhlp = .; 
	if op5dreshlp in ( -13, -11, -9, -12, -1, 9999) then op5dreshlp = .; 
	if op5launhlp in ( -13, -11, -9, -12, -1, 9999) then op5launhlp = .; 
	if op5shophlp in ( -13, -11, -9, -12, -1, 9999) then op5shophlp = .; 
	if op5mealhlp in ( -13, -11, -9, -12, -1, 9999) then op5mealhlp = .; 
	if op5bankhlp in ( -13, -11, -9, -12, -1, 9999) then op5bankhlp = .; 
	if op1medshlp in ( -13, -11, -9, -12, -1, 9999) then op1medshlp = .; 
	/*THEN EXCLUDE HELPERS THAT ARE PAID AIDES OR EMPLOYEES AT THE PLACE THEY LIVE*/ 
	if op5relatnshp in (31,37) then delete; 
	/*EXCLUDING NON-FAMILY, PAID HELPERS*/ 
	if op5relatnshp in (35,36,40,92) and op5paidhelpr = 1 then delete; 
	keep spid op5dhrsmth op5relatnshp op5paidhelpr op5outhlp op5insdhlp op5bedhlp op5eathlp op5bathhlp op5toilhlp
	op5dreshlp op5launhlp op5shophlp op5mealhlp op5bankhlp op1medshlp;
run; 

/*CHECKS*/ 
proc freq data = opfile; 
	table op5dhrsmth op5relatnshp op5paidhelpr 
	op5outhlp op5insdhlp op5bedhlp op5eathlp op5bathhlp op5toilhlp
	op5dreshlp op5launhlp op5shophlp op5mealhlp op5bankhlp op1medshlp; /*MISSING GOES TO 44,310*/ 
	title "LOOK FOR FREQUENCIES OF MISSING CODES, -13, -11, -9, -12, -1 and 9999";
run; 
proc means data = opfile; 
	var op5dhrsmth; 
run;
proc univariate data = opfile; 
	var op5dhrsmth; 
	histogram op5dhrsmth;
run;

/*REMOVE FORMATTING TO CHECK RAW VARIABLES - KEPT SHOWING UP AS RANGES*/
proc datasets lib = work;
	modify opfile;
	format op5dhrsmth;
	run ;
quit ;

proc freq data = opfile; 
	table op5dhrsmth op5outhlp op5insdhlp op5bedhlp;
	title "CHECK RAW DATA ";
run; 


/*COLLAPSE TO RESPONDENT LEVEL*/ 
proc sort data = opfile; by spid; run; 
proc sql; 
  create table respondenthelper as /*N=7940*/ 
  select spid, sum(op5dhrsmth) as op5dhrsmth_total, /*ADD UP HOURS*/
 case when sum(op5outhlp)  ge 1 then 1 else 0 end as mo_out, /*CREATE INDICATOR VARIABLES (0/1) IF THEY HAD ANY INFORMAL HELP*/  
 case when sum(op5insdhlp) ge 1 then 1 else 0 end as mo_in, 
 case when sum(op5bedhlp)  ge 1 then 1 else 0 end as mo_bed, 
 case when sum(op5eathlp)  ge 1 then 1 else 0 end as sc_eat, 
 case when sum(op5bathhlp) ge 1 then 1 else 0 end as sc_bath, 
 case when sum(op5toilhlp) ge 1 then 1 else 0 end as sc_toil, 
 case when sum(op5dreshlp) ge 1 then 1 else 0 end as sc_dres, 
 case when sum(op5launhlp) ge 1 then 1 else 0 end as ha_laun,
 case when sum(op5shophlp) ge 1 then 1 else 0 end as ha_shop, 
 case when sum(op5mealhlp) ge 1 then 1 else 0 end as ha_meal, 
 case when sum(op5bankhlp) ge 1 then 1 else 0 end as ha_bank, 
 case when sum(op1medshlp) ge 1 then 1 else 0 end as mc_med
 from opfile
 group by spid;
quit; 

proc freq data = respondenthelper;
 table 	mo_out mo_in mo_bed sc_eat sc_bath sc_toil sc_dres 
	ha_laun ha_shop ha_meal ha_bank mc_med ;
run; 

proc freq data = opfile; table op5outhlp op5insdhlp; run; 
data respondenthelper2; /*SAME CODE AS XINWEI - AGGREGRATE*/ 
	set respondenthelper; 
	/**************************************************************/
	/* MO
	/**************************************************************/
	if mo_out = 1 or mo_in = 1 or mo_bed = 1 then mo_help = 1;
		else if mo_out = . and mo_in = . and mo_bed = . then mo_help = .;
		else mo_help = 0;	

	/**************************************************************/
	/* SC
	/**************************************************************/
	if sc_eat = 1 or sc_bath = 1 or sc_toil = 1 or sc_dres = 1 then sc_help = 1;
		else if sc_eat = . and sc_bath = . and sc_toil = . and sc_dres = . then sc_help = .;
		else sc_help = 0;
		
	/**************************************************************/
	/* HA
	/**************************************************************/
	if ha_laun = 1 or ha_shop = 1 or ha_meal = 1 or ha_bank = 1  then ha_help = 1;
		else if ha_laun = . and ha_shop = . and ha_meal = . and ha_bank = . then ha_help = .;
		else ha_help = 0;
	
	/**************************************************************/
	/* MC
	/**************************************************************/
	if mc_med = 1  then mc_help = 1;
		else if mc_med = .  then mc_help = .;
		else mc_help = 0;	
run;		

proc freq data = respondenthelper2;
 table 	mo_out mo_in mo_bed sc_eat sc_bath sc_toil sc_dres 
	ha_laun ha_shop ha_meal ha_bank mc_med mc_help ha_help mo_help sc_help ;
run; 

proc freq data = opfile; 
	table op5dhrsmth op5relatnshp op5paidhelpr 
	op5outhlp op5insdhlp op5eathlp op5bathhlp op5toilhlp
	op5dreshlp op5launhlp op5shophlp op5mealhlp op5bankhlp op1medshlp; /*MISSING GOES TO 44,310*/ 
	title "LOOK FOR FREQUENCIES OF MISSING CODES, -13, -11, -9, -12, -1 and 9999";
run; 

/*MATCH TO NORMA COHORT AND CHECK AGAIN*/ 
proc format; 
	value r5dresidf 
	1= "COMMUNITY"
	2= "RESDIENTIAL FACILITY"
	4= "NURSING HOME"; 
run; 

proc sort data = norma_cohort_20210517; by spid; run; 
proc sort data = respondenthelper2; by spid; run; 
data cohortandhours; /*N=7574*/ 
	merge norma_cohort_20210517 (in=a) respondenthelper2 (in=b); 
	by spid; 
	if a; /*KEEP THOSE IN NORMA'S ORIGINAL COHORT*/ 
	format r5dresid r5dresidf.;
run; 
proc sort data = cohortandhours; by r5dresid; run; 
proc means data= cohortandhours nmiss n min mean median max; 
	var op5dhrsmth_total; 
	by r5dresid; 
	title "CHECK NEW VARIABLE FOR HOURS OF CARE";
run; 

proc freq data = cohortandhours;
	table op5dhrsmth_total r5dresid; 
	title "CHECK NEW VARIABLE FOR HOURS OF CARE AND VARIABLE FOR RESIDENCE STATUS";
run;

data revision.newfinal; 
	set cohortandhours; 
	idnew = _n_; 
	
	/* WE HAVE WHO GOT HELP (MO_IN, ETC.) AND WE HAVE THE AGGREGATE OF THOSE, 
	NOW WE NEED WHO GOT HELP AMONG THOSE WHO NEEDED HELP AND THEN AGGREATE THAT TOO
	*******************************************************************************
	RECEIVING HELP BASED ON NEEDING HELP (CHANGE DENOMINATORS)
    ***************************************************************************/

	/**************************************************************/
	/* MO: get around outside
	/**************************************************************/
	mo_out2 = mo_out;
	if needhelp_mo_out = 0 then mo_out2 = .;
		else if mo_out = . and needhelp_mo_out = 1 then mo_out2 = 9;
	
	/**************************************************************/
	/* MO: get around inside
	/**************************************************************/
	mo_in2 = mo_in;
	if needhelp_mo_ins = 0 then mo_in2 = .;
		else if mo_in = . and needhelp_mo_ins = 1 then mo_in2 = 9;

	/**************************************************************/
	/* MO: get out of bed
	/**************************************************************/
	mo_bed2 = mo_bed;
	if needhelp_mo_bed = 0 then mo_bed2 = .;
		else if mo_bed = . and needhelp_mo_bed = 1 then mo_bed2 = 9;
	
		
	/**************************************************************/
	/* SC: eating
	/**************************************************************/
	sc_eat2 = sc_eat;
	if needhelp_sc_eat = 0 then sc_eat2 = .;
		else if sc_eat = . and needhelp_sc_eat = 1 then sc_eat2 = 9;
	
	/**************************************************************/
	/* SC: cleaning 
	/**************************************************************/
	sc_bath2 = sc_bath;
	if needhelp_sc_clean = 0 then sc_bath2 = .;
		else if sc_bath = . and needhelp_sc_clean = 1 then sc_bath2 = 9;

	/**************************************************************/
	/* SC: toileting
	/**************************************************************/
	sc_toil2 = sc_toil;
	if needhelp_sc_toilet = 0 then sc_toil2 = .;
		else if sc_toil = . and needhelp_sc_toilet = 1 then sc_toil2 = 9;
	
	/**************************************************************/
	/* SC: dressing
	/**************************************************************/
	sc_dres2 = sc_dres;
	if needhelp_sc_dress = 0 then sc_dres2 = .;
		else if sc_dres = . and needhelp_sc_dress = 1 then sc_dres2 = 9;

	
	/**************************************************************/
	/* HA: do laundry
	/**************************************************************/
	ha_laun2 = ha_laun;
	if needhelp_ha_laun = 0 then ha_laun2 = .;     
		else if ha_laun = . and needhelp_ha_laun = 1 then ha_laun2 = 9;     

	/**************************************************************/
	/* HA: do shopping
	/**************************************************************/
	ha_shop2 = ha_shop;
	if needhelp_ha_shop = 0 then ha_shop2 = .;     
		else if ha_shop = . and needhelp_ha_shop = 1 then ha_shop2 = 9;     

	/**************************************************************/
	/* HA: make hot meals
	/**************************************************************/
	ha_meal2 = ha_meal;
	if needhelp_ha_meal = 0 then ha_meal2 = .;     
		else if ha_meal = . and needhelp_ha_meal = 1 then ha_meal2 = 9;     

	/**************************************************************/
	/* HA: handle bills and banking
	/**************************************************************/
	ha_bank2 = ha_bank;
	if needhelp_ha_bank = 0 then ha_bank2 = .;     
		else if ha_bank = . and needhelp_ha_bank = 1 then ha_bank2 = 9;     

		
	/**************************************************************/
	/* MC: keep track of medicine
	/**************************************************************/
	mc_med2 = mc_med;
	if needhelp_mc_meds = 0 then mc_med2 = .;     
		else if mc_med = . and needhelp_mc_meds = 1 then mc_med2 = 9;     

	
	/*aggregate*/
	/**************************************************************/
	/* MO
	/**************************************************************/
	mo_help2 = mo_help;
	if needhelp_mo = 0 then mo_help2 = .;
		else if mo_help = . and needhelp_mo = 1 then mo_help2 = 9;

	/**************************************************************/
	/* SC
	/**************************************************************/
	sc_help2 = sc_help;
	if needhelp_sc = 0 then sc_help2 = .;
		else if sc_help = . and needhelp_sc = 1 then sc_help2 = 9;
		
	/**************************************************************/
	/* HA
	/**************************************************************/
	ha_help2 = ha_help;
	if needhelp_ha = 0 then ha_help2 = .;
		else if ha_help = . and needhelp_ha = 1 then ha_help2 = 9;
	
	/**************************************************************/
	/* MC
	/**************************************************************/
	mc_help2 = mc_help;
	if needhelp_mc = 0 then mc_help2 = .;
		else if mc_help = . and needhelp_mc = 1 then mc_help2 = 9;
	
	/*drop is5: hc5: r4: r3: r2: r1:;*/ 
	
	if mo_help2 =1 or sc_help2 =1 or ha_help2 =1 or mc_help2 =1 then needandhelp=1; 
	if needandhelp =1 then newstrata =r5dresid;
	
	keep idnew needandhelp newstrata op5dhrsmth_total r5dresid ana_final_wt0 W5VARSTRAT 
	
	mo_out mo_in mo_bed sc_eat sc_bath sc_toil sc_dres 
	ha_laun ha_shop ha_meal ha_bank mc_med
	
	mo_out2 mo_in2 mo_bed2 sc_eat2 sc_bath2 sc_toil2 sc_dres2 
	ha_laun2 ha_shop2 ha_meal2 ha_bank2 mc_med2
	
	mo_help sc_help ha_help mc_help 
	mo_help2 sc_help2 ha_help2 mc_help2
	/*MO_HELP, ETC MEANS YES, NEED HELP THEN MO_HELP2 IS YES, RECEIVED HELP IF THEY NEEDED HELP*/ 
	
	NEEDHELP_MO  NEEDHELP_MO_OUT NEEDHELP_MO_INS NEEDHELP_MO_BED NEEDHELP_SC NEEDHELP_SC_EAT NEEDHELP_SC_CLEAN
	NEEDHELP_SC_TOILET NEEDHELP_SC_DRESS NEEDHELP_HA NEEDHELP_HA_LAUN NEEDHELP_HA_SHOP NEEDHELP_HA_MEAL NEEDHELP_HA_BANK 
	NEEDHELP_MC NEEDHELP_MC_MEDS; 
run; 

proc freq data = revision.newfinal; table 
	/*19 PEOPLE MISSING - THEY WERE NOT IN THE OP FILE BUT IN NORMA'S DATASET, SO WE WILL LEAVE THEIR RESPONSES BLANK*/
	mo_out mo_in
	mo_out2 mo_in2 mo_bed2 sc_eat2 sc_bath2 sc_toil2 sc_dres2 
	ha_laun2 ha_shop2 ha_meal2 ha_bank2 mc_med2
	
	mo_help2 sc_help2 ha_help2 mc_help2

	needhelp_mo  needhelp_mo_out needhelp_mo_ins needhelp_mo_bed needhelp_sc needhelp_sc_eat needhelp_sc_clean
	needhelp_sc_toilet needhelp_sc_dress needhelp_ha needhelp_ha_laun needhelp_ha_shop needhelp_ha_meal needhelp_ha_bank 
	needhelp_mc needhelp_mc_meds needandhelp;
run;  

/*WEIGHTED*/ 
ods graphics on;
title 'WEIGHTED HOURS OR CARE BY LIVING SITUATION';
proc surveymeans data=revision.newfinal /*nmiss mean median*/ ;
   var op5dhrsmth_total ;
   weight ana_final_wt0;
   strata W5VARSTRAT; 
   domain newstrata;
run; 
proc freq data = revision.newfinal ; table newstrata; run; 
title 'WEIGHTED VARS BY LIVING SITUATION';
proc surveyfreq data=revision.newfinal  ;
   table r5dresid*(needhelp_mo  needhelp_mo_out needhelp_mo_ins needhelp_mo_bed needhelp_sc needhelp_sc_eat needhelp_sc_clean
	needhelp_sc_toilet needhelp_sc_dress needhelp_ha needhelp_ha_laun needhelp_ha_shop needhelp_ha_meal needhelp_ha_bank 
	needhelp_mc needhelp_mc_meds mo_help2 sc_help2 ha_help2 mc_help2 mo_out2 mo_in2 mo_bed2 sc_eat2 sc_bath2 sc_toil2 sc_dres2 
	ha_laun2 ha_shop2 ha_meal2 ha_bank2 mc_med2)/ row ;
   weight ana_final_wt0;
   strata W5VARSTRAT; 
   title "Final Exhibit 4";
run; 

data graph;
	set revision.newfinal; 
	if mo_help2=1 then mo_cat = 1; 
	if needhelp_mo=1 and mo_help2 ne 1 then mo_cat = 2; 
	if needhelp_mo=0 then mo_cat = 3;
	
	if sc_help2=1 then sc_cat = 1; 
	if needhelp_sc=1 and sc_help2 ne 1 then sc_cat = 2; 
	if needhelp_sc=0 then sc_cat = 3;
	
	if ha_help2=1 then ha_cat = 1; 
	if needhelp_ha=1 and ha_help2 ne 1 then ha_cat = 2; 
	if needhelp_ha=0 then ha_cat = 3;
run; 
proc format; 
value  graphf
1="Having need and getting it met by informal care"
2="Needing help"	
3="Not needing assistance"; 
run; 

proc surveyfreq data=graph  ;
   table r5dresid*(ha_cat sc_cat mo_cat)/ row ;
   weight ana_final_wt0;
   strata W5VARSTRAT; 
   title "Final Figure 1";
   format ha_cat graphf. sc_cat graphf. mo_cat graphf.; 
run; 

proc sort data = revision.newfinal; by r5dresid; run;
proc means data= revision.newfinal nmiss n min mean median max; 
	var op5dhrsmth_total; 
	by r5dresid; 
	title "CHECK NEW VARIABLE FOR HOURS OF INFORMAL CARE";
run;  

/*STOPPED HERE ON 9/8*/ 


