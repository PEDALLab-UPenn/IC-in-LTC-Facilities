README file for posted estimation files**

**&quot;Informal Caregivers Provide Considerable Front-line Support in Residential Care Facilities and Nursing Homes&quot;**

by Norma B. Coe and Rachel M. Werner

**Overview:**

Before running the code:

- Copy file contents into project folder with the following subfolders: do, log, and data
- Change the file path of the folder global (&quot;gl folder&quot;) in 00master.do to the location of the project folder
- Select which sample to run by changing local values from 0 to 1 (local macros in lines 53-55 of 00\_master.do).

Once these changes have been made, running the master file will produce the tables corresponding to the selected sections (noted after each local in 00\_master.do).

For questions about the code, please contact chuxuan.sun@pennmedicine.upenn.edu

**Data required:**

Register for access to the HRS and RAND HRS data on the HRS website ([https://hrs.isr.umich.edu/data-products](https://hrs.isr.umich.edu/data-products)), then download the following files (both .dct and .da, or .dta where noted):

- RAND HRS Fat Files: h16f2a
- RAND HRS Longitudinal File: randhrs1992\_2016v2.dta
- HRS CORE File: H16G\_HP.da and H16G\_HP.dct

Place all data files in the data folder. Ensure that the paths in the .dct files point to the location of the .da files.

**Running the code:**

This code is for Stata, and has been verified to run in version 16.

**Description of files:**

The following describes how the files correspond to the inputs and output:

| File | Description | Inputs/Outputs | Notes |
| --- | --- | --- | --- |
| 00\_master.do | Sets macros for all variables, specifications, and replications used in the other files |
 | Only edit the global folder and the individual global macros |
| 01\_clean\_merge.do | Cleans and merges all raw data files | Input: h16f2a, RAND HRS randhrs1992\_2016v2.dta, H16G\_HP.da and H16G\_HP.dctOutput: randhrs2016.dta, helper.dta, nursinghome.dta, communitydwelling,dta |
 |
| 02\_sampledemographics.do | Creates sample demographics | Input: nursinghome.dta, communitydwelling.dtaOutput: Statistics in sample demographics table |
 |
| 02\_summarystatistics.do | Creates summary statistics | Input: nursinghome.dta, communitydwelling.dtaOutput: Statistics in summary statistic table |
 |
