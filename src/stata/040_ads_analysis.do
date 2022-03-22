//labeling variables
gen c = 0 //self-oriented
replace c = 1 if campaign== "Helping Community EN" | campaign== "Helping Community SP"
replace c = 2 if campaign== "Helping Others EN" | campaign== "Helping Others SP"
replace c = 3 if campaign== "Personal Responsibility EN" | campaign== "Personal Responsibility SP"
recode c (0= 0 "Self-Oriented") (1= 1 "Helping Community") (2= 2 "Helping Others") (3= 3 "Personal Responsibility"), gen(group)

gen cl = 0 if was_clicked== "False"
replace cl = 1 if was_clicked== "True"
recode cl (0 = 0 "No") (1 = 1 "Yes"), gen(click)

gen sp = 0
replace sp= 1 if language== "sp"
recode sp (0= 0 "English") (1= 1 "Spanish"), gen(AdLanguage)

g a= 0
replace a= 1 if age== "25 - 34"
replace a= 2 if age== "35 - 44"
replace a= 3 if age== "45 - 54"
replace a= 4 if age== "55 - 64"
recode a (0= 0 "18 - 24") (1= 1 "25 - 34") (2= 2 "35 - 44") (3= 3 "45 - 54") (4= 4 "55 - 64"), gen(age_group)

g f= 0
replace f= 1 if gender== "Female"
recode f (0= 0 "Male") (1= 1 "Female"), gen(female)

g p= 0
replace p= 1 if is_a_parent== "True"
recode p (0= 0 "No") (1= 1 "Yes"), gen(parent)

g h= 0
replace h= 1 if household_income== "11 - 20%"
replace h= 2 if household_income== "21 - 30%"
replace h= 3 if household_income== "31 - 40%"
replace h= 4 if household_income== "41 - 50%"
recode h (0= 0 "Top 10%") (1= 1 "11 - 20%") (2= 2 "21 - 30%") (3= 3 "31 - 40%") (4= 4 "41 - 50%"), gen(HHincome)

//regressions
reg click i.group if AdLanguage== 0, ro
test 1.group 2.group 3.group, mtest(bonferroni)
test 1.group=2.group, mtest(b)
test 1.group=3.group, mtest(b)
test 2.group=3.group, mtest(b)
reg click i.group if AdLanguage== 1, ro
test 1.group 2.group 3.group, mtest(bonferroni)
test 1.group=2.group, mtest(b)
test 1.group=3.group, mtest(b)
test 2.group=3.group, mtest(b)

reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0, ro
test 1.group 2.group 3.group, mtest(bonferroni)
test 1.group=2.group, mtest(b)
test 1.group=3.group, mtest(b)
test 2.group=3.group, mtest(b)
estimates store en
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1, ro
test 1.group 2.group 3.group, mtest(bonferroni)
test 1.group=2.group, mtest(b)
test 1.group=3.group, mtest(b)
test 2.group=3.group, mtest(b)
estimates store sp

//subgroup analyses
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & female== 1, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & female== 0, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & age_group<= 2, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & age_group> 2, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & HHincome<= 1, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & HHincome> 1, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & parent== 1, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & parent== 0, ro

reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & female== 1, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & female== 0, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & age_group<= 2, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & age_group> 2, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & HHincome<= 1, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & HHincome> 1, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & parent== 1, ro
reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & parent== 0, ro

//coefplot
qui eststo Whole_Sample: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0, ro
qui eststo Female: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & female== 1, ro
qui eststo Male: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & female== 0, ro
qui eststo AgesUncer45: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & age_group<= 2, ro
qui eststo Ages45To64: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & age_group> 2, ro
qui eststo Income_Top20Percent: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & HHincome<= 1, ro
qui eststo Income_21To50Percent: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & HHincome> 1, ro
qui eststo WithChildren: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & parent== 1, ro
qui eststo WithoutChildren: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 0 & parent== 0, ro
coefplot Whole_Sample || Female || Male || AgesUncer45 || Ages45To64 || Income_Top20Percent || Income_21To50Percent || WithChildren || WithoutChildren, keep(*.group) bycoefs byopts(xrescale) mlabel format(%9.3f) mlabposition(6) mlabsize(small) mlabgap(*2)

qui eststo Whole_Sample: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1, ro
qui eststo Female: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & female== 1, ro
qui eststo Male: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & female== 0, ro
qui eststo AgesUncer45: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & age_group<= 2, ro
qui eststo Ages45To64: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & age_group> 2, ro
qui eststo Income_Top20Percent: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & HHincome<= 1, ro
qui eststo Income_21To50Percent: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & HHincome> 1, ro
qui eststo WithChildren: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & parent== 1, ro
qui eststo WithoutChildren: reg click i.group i.age_group female parent i.HHincome if AdLanguage== 1 & parent== 0, ro
coefplot Whole_Sample || Female || Male || AgesUncer45 || Ages45To64 || Income_Top20Percent || Income_21To50Percent || WithChildren || WithoutChildren, keep(*.group) bycoefs byopts(xrescale) mlabel format(%9.3f) mlabposition(12) mlabsize(small) mlabgap(*2)
