/*code for mens flexibility vizualization
Jenny Trinitapoli, Iris Zhao, Abdallah Chilungo, jimi adams, Sara Yeatman
Socius -- project begun Jan 2019 and finished in March 2022 
code-review by Iris on March 20th --> annotation-only updates
last edit: March 5, 2022 */

/**code is written to run smoothly on both men's and women's files from 2009 and 2015 
Focusing on W1 analyses using the men's data from 2009 */

cd "/Users/JennyTrinitapoli/Box/TLT_RAs_2020"
use "./paper_flexibility_men/data_tlt/W1_public_20190722.dta", clear

*INSTALLATION SUGGESTION: install 3 ados you might need: ssc install mipolate carryforward grc1leg

**IMPOSE SAMPLE RESTRICTION: ONLY RANDOM MEN, CHILDLESS, and UNMARRIED
*keep random men only
keep if respid>1000000 & respid<6000000
*keep unmarrieds only
keep if m1==5
*keep childless men only
keep if z1==0

*DESCRIPTIVE STUDY
*examine Ideal Family Size Variable
gen ifs=f1
sum ifs, detail /*mean is 3.3; 99% of responses fall between 1-7 */
**how many children would these men have culumlatively if their IFS were realized?
display r(sum)

*Strong preference for examing the actual responses; creating a top-coded version of the IFS variable as back-up
gen ideal=ifs
replace ideal=6 if ifs>=6

*examine the timing varible; see TLT codebook
gen timing=f7
recode timing(1=2)(7=.d)
replace timing=timing-1
label define tempo 1 "<2 Years" 2 "2-3 Years" 3 "3-4 Years" 4 "4-5 Years" 5 ">5 Years"
label values timing tempo

label var ifs "Ideal Family Size"
label var timing "Desired Time to First Birth"
label var ideal "Top-Coded IFS"


*VIEW HISTOGRAMS FOR EXPLORATORY PURPOSES
*****IFS
hist ifs, percent scheme(burd4) name(hist1, replace) ylabel(0(10)60)
*****Timing
hist timing, percent scheme(burd4) name(hist2, replace) xlabel(1 "<2 Years" 2 "2-3 Years" 3 "3-4 Years" 4 "4-5 Years" 5 ">5 Years", angle(45)) ylabel(0(10)60)
*****Together
graph combine hist1 hist2, col(2) scheme(burd4)


**GENERATING THE FLEXIBILTIY SCORES 
**break both change variables into 3 pieces each; these are the change variables (for all 18 conditions)
**lower-case p is quantum; upper-case P is tempo
forvalues i=1/18{
	tab c`i'a, gen(pref`i')
	tab c`i'b, gen(Pref`i')
}
*stub 1 is more/sooner, 2 is fewer/later, 3 is no change (this is clearly labeled in dataset)

*MANUAL FIX: Review all newly created variables and fix up 3 variables with 0 movement in the MORE direction because these categories get collapsed to 1-2 instead of 1-2-3 and are misaligned when reshaping.
*CAUTION: This step I did by hand (lines 60-67). First, skim all 32 conditions to make sure there are valid answers for all options. If there are not any valid responses in place 1 or 2, the values will get shifted (and messed up) when the collapsing process stars below. This code is not necessary for the women's data, and if using a diferent dataset (say for male partners) may need to be adjusted based on the content of their responses. There may be a way to automate this step, but I couldn't easily think of one and always recommend browsing new variables anyhow.
rename pref112 pref113 
rename pref111 pref112

rename pref132 pref133 
rename pref131 pref132 

rename pref122 pref123 
rename pref121 pref122 

*count the number of NO CHANGE responses
gen fixedQ=0
gen fixedT=0
forvalues i=1/18 {
    capture replace fixedQ = fixedQ + 1 if pref`i'3==1
	capture replace fixedT = fixedT + 1 if Pref`i'3==1
}
tab1 fixedQ fixedT
sum fixedQ fixedT, detail


***REVERSE CODE FIXED --> FLEX QUANTUM (SO HIGH # FLEXIBLE, LOW # FIXED)***
gen flexibleQ=18-fixedQ
tab flexibleQ
label var flexibleQ "Level of Quantum Flexibility"

gen flexibleT=18-fixedT
tab flexibleT
label variable flexibleT "Level of Tempo Flexibility"

*Interesting finding: people with larger IFS are more flexible; but there is no room to explore this in the Descriptive Viz. I'm already over 500 words.  Decision to focus exclusively on the basics.
graph hbar flexibleQ flexibleT if f1~=0, over(ideal) scheme(lean1) ylabel(0(2)18) legend(ring(0) pos(3)) ///
legend(nobox order (1 "Quantum Flexibility" 2 "Tempo Flexibility")) ytitle("Flexibility Score (0-18)")


/*DATA TRANFORMATIONS BEGIN HERE
this part of the file begins to transforms the data into a <<dataset of means>> for each flexibility condition
CAUTION: units are no-longer individual-level, as they were in the original dataset*/

*break condition variables into 3 pieces each: no change, a change, or b change
forv i=1/18 {
	tab c`i'a, gen(quantum`i'_)
	tab c`i'b, gen(tempo`i'_)
}

*rename them to put stubs at the end
forv i=1/18 {
	rename tempo`i'_1 tempo_1_`i'
	rename tempo`i'_2 tempo_2_`i'
	rename tempo`i'_3 tempo_3_`i'
	rename quantum`i'_1 quantum_1_`i'
	rename quantum`i'_2 quantum_2_`i'
}

*separated out this step and added "catpure" to address a glitch in the women's data.
*because thre are no UP values for one of the conditions, the loop hits a snag. This fixes it and it also runs smoothly for men. 
*best practices might involev using capture for the chunk above and running this all together.
forv i=1/18 {
	cap  rename quantum`i'_3 quantum_3_`i' 
}

keep quantum* tempo*

/*Instead of a dataset of 476 men, this becomes a dataset of means: 
105 of them 18 conditions & 3 results & 2 types = 108 but there are 105 in the dataset because a few (3) appear to be blank */
collapse quantum* tempo*

gen id=1
**reshape by condition: now this is a dataset of means = 6 each for 18 conditions
reshape long quantum_1_ quantum_2_ quantum_3_ tempo_1_ tempo_2_ tempo_3_, i(id) j(condition)
*the blank values are unaligned
gen nothree=0
replace nothree=1 if quantum_3_==.
replace quantum_3_ = quantum_2_ if nothree==1
replace quantum_2_ = quantum_1_ if nothree==1
replace quantum_1_ = 0 if nothree==1
*not all the 3 values are "NO CHANGE"

*rename all vars to remove the stubs at the end
rename *_ *

*reshape again by direction
reshape long quantum_ tempo_, i(condition) j(direction)
rename quantum mean1
rename tempo mean2
drop id
egen newid=concat(condition direction)
reshape long mean, i(newid)
*now this is a long dataset with 6 values for each condition, totaling 108

rename _j type /*distinguishes quantum and tempo responses; 1 is quantum 2 is tempo */ 
gen id=_n /*numbers all the values in the dataset */

*reshape it wide to be able to graph the means as 3 distinct values
sort condition type direction
reshape wide mean type condition, i(id) j(direction)

*reduce this dataset; there should be an automated way, but I'm not sure
*consolidate the type variable 
gen type=type1
replace type=type2 if type==.
replace type=type3 if type==.
drop type1 type2 type3

*consolidate the condition variable
gen condition=condition1
replace condition=condition2 if condition==.
replace condition=condition3 if condition==.
drop condition1 condition2 condition3
*condolidate the condition var & re-label it
label values condition conditions


*basic graph of distribution (totaling 100% by condition) 
graph bar mean1 mean3 mean2 if type==1, stack over(condition) legend(col(3) pos(6)) scheme(lean1)
*basic graph of distribution (totaling 100% by condition) 
graph bar mean1 mean3 mean2 if type==2, stack over(condition) legend(col(3) pos(6)) scheme(lean1)
*everything sums to 100% so good. But better to reduce and take out the NO change category


*change the delay and reduce variables to show quantity of directional changes (relative to no change)
replace mean2=mean2*-1
graph bar mean1 mean2 if type==1, stack over(condition, lab(angle(45))) legend(off) scheme(lean1) /*quantum*/
graph bar mean1 mean2 if type==2, stack over(condition, lab(angle(45))) legend(off) scheme(lean1) /*tempo*/


*make the groups to differentiate types of conditions
gen group=.
replace group=1 if condition==12 | condition==13 | condition==10  /*aids-related*/
replace group=2 if inlist(condition, 1, 4, 5, 14, 15, 16, 17, 18) /*family*/
replace group=3 if group==.   /*economic*/


*LABEL ALL THE CONDITIONS this is a new lable jenny is makeing following the questinonnaire
label define conditions 1 "foster" 2 "migrant" 3 "lottery" 4 "pfewer" 5 "pmore" 6 "freeuniform" 7 "xschoolfees" 8 "steadyjob" ///
9 "partnerjob" 10 "rumors" 11 "nomairze" 12 "hiv" 13 "phiv" 14 "sickkid" 15"boys" 16 "girls" 17"momsick" 18 "momdies"

*make long-labels to use in the graph
label define long 1 "Foster 3 Children" 2 "Migrate to South Africa" 3 "Win lottery" 4 "Partner wants fewer" 5 "Partner wants more" ///
6 "Uniforms become free" 7 "School fees abolished" 8 "Find steady job" 9 "Partner gets job" 10 "Partner is unfaithful" ///
11 "Facing a food shortage" 12" Suspect you have HIV" 13 "Suspect partner has HIV"  14 "Child gets sick" 15 "Have only boys" ///
16 "Have only girls" 17 "Mom gets sick" 18 "Mom dies" 

label values condition conditions
gen condition_long=condition
label values condition_long long
tab condition
tab condition_long


**reduce the dataset a bit to create points
bysort condition type: carryforward(mean3), replace
bysort condition type: carryforward(mean2), replace
bysort condition type: carryforward(mean1), replace
replace mean2=mean2*-1
keep if mean1~=. & mean2~=. & mean3~=.

*make a mid-point on which to anchor the arrows line
gen zero=0

*try this with four points, 3 segments
gen point1=0
gen point2=mean2
gen point3=(mean2)+mean3
gen point4=1

*make a new RANK variable to order these from most to least numeric change within each group
*(tested this with )
sort group condition type 
*store the NO NUMERIC CHANGE value for each of the conditions
gen condition2=mean3 if type==1 /*rank based on the no change values from the IFS measure only */
egen rank=rank(condition2), track
bysort condition: generate n=_n
bysort condition: mipolate rank n, groupwise generate(rank2)
*distill and fix up the rank variables a bit
drop rank
rename rank2 rank
*SY suggested most to least change in the figure (rather than the reverse)
replace rank=19-rank


*Since the graph below is built on the rank label (rather than condition), the rank variable nees lables
label values rank long
label define long2 18 "Suspect partner has HIV" 17 "Suspect you have HIV" 16 "Partner is unfaithful" 15 "Foster 3 Children" ///
14 "Partner wants fewer" 13 "Facing a food shortage" 12 "Migrate to South Africa" 11 "Have only boys" 10 "Have only girls" ///
9 "Child gets sick" 8 "Partner wants more" 7 "Find steady job" 6 "Win lottery" 5 "Partner gets job" 4 "Mom dies" ///
3 "Uniforms become free" 2 "School fees abolished" 1"Mom gets sick"
label values rank long2



*-- IFS CHANGES **IN SEGMENTS --BY HAND; change the arrows to cirucles in the 3 cases with no change
graph twoway ///
(pcarrow rank point2 rank point1 if type==1 & group==1, msize(2) barbsize(medium) lwidth(medthick) color("178 24 43")) || ///
(pcarrow rank point2 rank point1 if type==1 & group==3, msize(2) barbsize(medium) lwidth(medthick) color("244 165 130")) || ///
(pcarrow rank point2 rank point1 if type==1 & group==2, msize(2) barbsize(medium) lwidth(medthick) color("33 102 172")) ///
(pcarrow rank point3 rank point4 if type==1 & group==1 & point3~=1, msize(2) barbsize(2) lwidth(medthick) color("178 24 43")) || ///
(pcarrow rank point3 rank point4 if type==1 & group==2, msize(2) barbsize(2) lwidth(medthick) color("33 102 172")) || ///	
(pcarrow rank point3 rank point4 if type==1 & group==3 & point3~=1, msize(2) barbsize(2) lwidth(medthick) color("244 165 130")) || ///
(scatter rank point4 if group==1 & point3==1, msymbol(pipe) mcolor("178 24 43")) || ///
(scatter rank point4 if group==3 & point3==1, msymbol(pipe) mcolor("244 165 130")), ///
legend(off) ///
scheme(s1color) ///
ytitle("") ///
yla("") ///
xtitle("Proportion") title("Expected Numeric Changes" "(<--decreases)	 (increases-->)", size(medsmall)) ///
xlabel(0(.2)1) ///
fxsize(60) ///
name(ifs_segments, replace)

*fxsize(50) ///


*yla(1/18, ang(h) notick valuelabel) ///
*(scatter rank spot, mlabel(rank) m(i) mlabcolor(black) mlabposition(0)), ///
*followed this [below] for dealing with the aspect ratio problem on the LH panel; just played with the # till it looked right.
*https://www.stata.com/statalist/archive/2012-03/msg00769.html


/*-- horizontal timing **IN SEGMENTS, labels on the side
graph twoway ///
(pcarrow rank point2 rank point1 if type==2 & group==1, msize(2) barbsize(2) lwidth(medthick) color("178 24 43")) || ///
(pcarrow rank point2 rank point1 if type==2 & group==2, msize(2) barbsize(2) lwidth(medthick) color("33 102 172")) || ///
(pcarrow rank point2 rank point1 if type==2 & group==3, msize(2) barbsize(2) lwidth(medthick) color("244 165 130")) || ///
(pcarrow rank point3 rank point4 if type==2 & group==1, msize(2) barbsize(2) lwidth(medthick) color("178 24 43")) || ///
(pcarrow rank point3 rank point4 if type==2 & group==2, msize(2) barbsize(2) lwidth(medthick) color("33 102 172")) || ///	
(pcarrow rank point3 rank point4 if type==2 & group==3, msize(2) barbsize(2) lwidth(medthick) color("244 165 130")), ///
scheme(s1color) ///
ytitle("") ///
yla(1/18, ang(h) notick valuelabel) ///
xtitle("Proportion") title("Expected Timing Shifts" "(<--delays) 	(accelerations-->)", size(medsmall)) ///
xlabel(0(.2)1) ///
name(timing, replace) ///
legend(order (1 "HIV-Related" 2 "Family" 3 "Economic") col(3))
*/

*-- horizontal timing
graph twoway ///
(pcarrow rank point2 rank point1 if type==2 & group==1, msize(2) barbsize(2) lwidth(medthick) color("178 24 43")) || ///
(pcarrow rank point2 rank point1 if type==2 & group==2, msize(2) barbsize(2) lwidth(medthick) color("33 102 172")) || ///
(pcarrow rank point2 rank point1 if type==2 & group==3, msize(2) barbsize(2) lwidth(medthick) color("244 165 130")) || ///
(pcarrow rank point3 rank point4 if type==2 & group==1, msize(2) barbsize(2) lwidth(medthick) color("178 24 43")) || ///
(pcarrow rank point3 rank point4 if type==2 & group==2, msize(2) barbsize(2) lwidth(medthick) color("33 102 172")) || ///	
(pcarrow rank point3 rank point4 if type==2 & group==3, msize(2) barbsize(2) lwidth(medthick) color("244 165 130")), ///
scheme(s1color) ///
ytitle("") ///
yla(1/18, ang(h) notick valuelabel) ///
xtitle("Proportion") title("Expected Timing Shifts" "(<--delays) 	(accelerations-->)", size(medsmall)) ///
xlabel(0(.2)1) ///
name(timing, replace) ///
fxsize(98) ///
legend(order (1 "HIV-Related" 2 "Family" 3 "Economic") col(3))


*combine the two panels of the figure into 1
grc1leg ifs_segments timing, col(2) scheme(s1mono) name(twosegments, replace) legendfrom(timing) 
graph export "/Users/JennyTrinitapoli/Desktop/flex_2segments_2009.pdf", as(pdf) replace

*ONE NON-REPLICABLE CLEAN_UP STEP IN ADOBE: last step conducted in adobe: center labels to sit midway between the 2 panels

*for data-sharing's-sake: export a "table" of the data to post alongside the figure
export excel using "./paper_flexibility_men/data_tlt/data_men_flex_viz_20220421", firstrow(variables)



/*/ ColorBrewer RdBu-8 reversed

color p1              "33 102 172"
color p2              "67 147 195"
color p3              "146 197 222"
color p4              "209 229 240"
color p5              "253 219 199"
color p6              "244 165 130"
color p7              "214 96 77"
color p8              "178 24 43"

/*colors from colorbrewer -- suggested by Iris
https://colorbrewer2.org/#type=qualitative&scheme=Dark2&n=3 */
