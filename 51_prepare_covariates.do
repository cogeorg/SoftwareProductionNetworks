// ============================================================================
//
// Cargo
//
// ============================================================================

//
// PRELIMINARY ANALYSES
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using "dependencies_Cargo.csv", delimiter(";") names clear
	rename projectid id_from
	rename dependencyprojectid id_to
	keep id*
duplicates drop
	drop if id_from == "Project ID"
	destring id*, replace
outsheet using "dependencies_Cargo-projects.csv", delimiter(";") replace


//
// 1_maintainer_githubID.dta
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using "Maintainer_GithubID.csv", delimiter(",") names clear 
	rename project name_project
save "1_maintainer_githubID.dta", replace


//
// 2_maintainer_github_metadata.dta
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using "Maintainer_github_metadata.csv", delimiter(",") names clear 
	rename contributor_github_url maintainer_github_url

	// data not filled for 2/3 of the maintainers
	gen pct_code_review = round(100*code_review / contributions)
	gen pct_commits = round(100*commits / contributions)
	gen pct_issues = round(100*issues / contributions)
	gen pct_pull_requests = round(100*pull_requests / contributions)
	
save "2_maintainer_github_metadata-full.dta", replace
outsheet using "2_maintainer_github_metadata-full.csv", delimiter(",") replace

	sort maintainer_github_url year
	bysort maintainer_github_url: gen MaintainerSeniority = _N
	bysort maintainer_github_url: egen MaintainerActivity = sum(contributions)
	gen MaintainerAvgActivity = MaintainerActivity / MaintainerSeniority

	keep maintainer_github_url Maintainer*
	duplicates drop
	
save "2_maintainer_github_metadata.dta", replace
outsheet using "2_maintainer_github_metadata.csv", delimiter(",") replace
 

//
// 2_contributor_commits.dta
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using "Contributor_commits-clean.csv", delimiter(";") names clear 
	
	drop if contributor_github_url == ""  // 5,476 observations lost
	sort name_project contributor_github_url
	
save "2_contributor_commits-full.dta", replace
outsheet using "2_contributor_commits-full.csv", delimiter(",") replace

	bysort name_project: gen num_contributors_alt = _N

	bysort contributor_github_url: gen ContributorExperience = _N
	bysort contributor_github_url: egen ContributorTotalCommits = sum(contributor_commits)
	gen ContributorActivty = ContributorExperience / ContributorTotalCommits

	keep name_project contributor_github_url Contributor*
	
	duplicates drop
	
save "2_contributor_commits.dta", replace
outsheet using "2_contributor_commits.csv", delimiter(",") replace
	bysort name_project: egen TotalContributorCommits = sum(ContributorTotalCommits)
	keep name_project TotalContributorCommits
	duplicates drop 
save 12_contributors_project.dta, replace

//
// 3_covariates_maintainers.dta
//
// prepare maintainer data
use 2_maintainer_github_metadata-full.dta, clear
	bysort maintainer_github_url: egen total_contributions = sum(contributions)
	drop if total_contributions > 125000 // there seem to be a handful of either malicious or automated accounts that we are dropping here
	keep maintainer_github_url total_contributions
	duplicates drop
save 12_maintainer_contributions.dta, replace

// prepare contributor data 
insheet using Maintainer_GithubID.csv, delimiter(",") clear names
	merge m:1 maintainer_github_url using 12_maintainer_contributions.dta 
	drop if _merge != 3
	drop _merge
	rename project name_project
	bysort maintainer_github_url: gen num_repos_contributed_to = _N
	gen avg_contributions = total_contributions / num_repos_contributed_to
	duplicates drop
	sort name_project
	by name_project: egen tot_avg_maint_contrib = sum(avg_contributions)
save 12_maintainer_project.dta, replace // careful, total contributions are to all repositories a maintainer works on

	keep name_project tot_avg_maint_contrib
	duplicates drop
merge 1:1 name_project using 12_contributors_project.dta. // from before
	drop if _merge == 2
	drop _merge
	replace TotalContributorCommits = 0 if TotalContributorCommits == .
	rename tot_avg_maint_contrib TotalAverageMaintainerCommits
	gen TotalCommits = TotalAverageMaintainerCommits + TotalContributorCommits
save 12_project_commits.dta, replace

// prepare covariates
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using "covariates_maintainers-1.csv", delimiter(";") clear
	rename date_first_release str_date_first_release
	rename date_latest_release str_date_latest_release
	gen date_first_release = date(str_date_first_release, "YMD")
	format date_first_release %td
	gen date_latest_release = date(str_date_latest_release, "YMD")
	format date_latest_release %td
duplicates drop

	// Activity, Maturity
	gen Maturity = date_latest_release - date_first_release

	gen Activity = 30*num_total_releases / Maturity
	replace Activity = 0 if Activity == .

	// Other variables
	rename num_stars Popularity
	rename num_forks NumForks
	rename num_contributors NumContributors
	rename size_repository Size  // in Byte
	rename num_watchers NumWatchers 
	rename num_total_releases NumReleases
merge 1:1 name_project using 12_project_commits.dta 
	keep if _merge == 3
	drop _merge
	
	order name_project crates_url github_repo
outsheet using "3_covariates_maintainers.csv", delimiter(",") names replace
save "3_covariates_maintainers.dta", replace

	drop if crates_url == ""

	bysort crates_url: gen projects_per_crate = _N 
	bysort github_repo: gen projects_per_repo = _N 
	
	order github_repo projects_per_* name_project crates_url
	keep github_repo projects_per_* name_project crates_url
outsheet using "3_projects_per_repo.csv", delimiter(",") names replace
save "3_projects_per_repo.dta", replace
	
 
//
// 4_projects_cargo.dta -- to prepare mapping
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using "projects_Cargo.csv", delimiter(";") clear
	rename projectid key1
	rename name name_project
	keep key1 name_project
duplicates drop
save "covariates/4_projects_cargo.dta", replace
outsheet using "covariates/4_projects_cargo.csv", delimiter(",") replace



//
// dependencies_Cargo-repo -- create repo-based dependency graph
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using "dependencies_Cargo.csv", delimiter(";") names clear
	rename projectid from
	rename dependencyprojectid to
	keep from to
	duplicates drop
	drop if from == "Project ID"
	
	// match project names
	rename from key1
	destring key1, replace
merge m:1 key1 using covariates/4_projects_cargo.dta
	keep if _merge == 3
	drop _merge
	rename key1 id_from 
	// now match repos to project names
merge m:1 name_project using covariates/3_projects_per_repo.dta 
	keep if _merge == 3
	drop _merge
	rename name_project name_from
	rename github_repo repo_from
	rename crates_url crates_from
	drop projects*
	
	// match project names
	rename to key1
	destring key1, replace
merge m:1 key1 using covariates/4_projects_cargo.dta
	keep if _merge == 3
	drop _merge
	rename key1 id_to 
	// now match repos to project names
merge m:1 name_project using covariates/3_projects_per_repo.dta 
	keep if _merge == 3
	drop _merge
	rename name_project name_to
	rename github_repo repo_to
	rename crates_url crates_to
	drop projects*
save dependencies_Cargo-repo-tmp.dta, replace

use dependencies_Cargo-repo-tmp.dta, clear
	keep repo_from
	duplicates drop
	rename repo_from repo_name
save repo_from.dta, replace

use dependencies_Cargo-repo-tmp.dta, clear
	keep repo_to
	rename repo_to repo_name
	duplicates drop
append using repo_from.dta	
	duplicates drop
	
	sort repo_name
	egen id_repo = group(repo_name)
	replace id_repo = 0 if id_repo == .
save id_repo_name.dta, replace

	// generate repo ids
use dependencies_Cargo-repo-tmp.dta, clear
	rename repo_from repo_name
merge m:1 repo_name using id_repo_name.dta
	keep if _merge == 3
	drop _merge
	rename repo_name repo_from 
	rename id_repo id_repo_from 

	rename repo_to repo_name
merge m:1 repo_name using id_repo_name.dta
	keep if _merge == 3
	drop _merge
	rename repo_name repo_to
	rename id_repo id_repo_to
	
	gen _missing = 0
	replace _missing = 1 if repo_from == "" | repo_to == ""
	replace _missing = 2 if repo_from == "" & repo_to == ""
	
	order id_from id_repo_from id_to id_repo_to _missing name_from name_to repo_from repo_to crates_from crates_to
	sort name_from name_to
save dependencies_Cargo-repo.dta, replace	
outsheet using dependencies_Cargo-repo.csv, delimiter(";") replace
	
	// now save only those for which we have to and from repos
	keep if _missing == 0
outsheet using dependencies_Cargo-repo-nomissing.csv, nonames delimiter(";") replace
	keep id_repo_from id_repo_to // repo_from repo_to
	duplicates drop
	sort id_repo_from id_repo_to
outsheet using dependencies_Cargo-repo-nomissing.dat, nonames delimiter(" ") replace


//
// MAIN ANALYSIS -- REPO LEVEL
//
// PREPARE CENTRALITIES
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using analysis_dependencies_Cargo-repo-nomissing.csv, delimiter(";") names clear
	rename id_node id_repo
save 6_centralities_Cargo-repo-nonmissing.dta, replace

// CREATE MASTER DATASET
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use 3_covariates_maintainers.dta, clear
	keep name_project NumForks NumContributors NumReleases Size Popularity NumWatchers Total*

merge 1:1 name_project using 3_projects_per_repo.dta
	drop if _merge != 3
	drop _merge
	
	drop if github_repo == ""
	
	bysort github_repo: egen foo = total(NumReleases)
	drop NumReleases
	rename foo NumReleases
	
	order github_repo NumReleases Size NumContributors NumForks Popularity NumWatchers
	keep github_repo NumReleases Size NumContributors NumForks Popularity NumWatchers Total*
	duplicates drop

	// there are some edge cases here that we are alleviating this way; the issue is in the raw data
	foreach var of varlist NumReleases-TotalCommits {
		bysort github_repo: egen foo = mean(`var')
		drop `var'
		rename foo `var'
	}
	duplicates drop
	
	rename github_repo repo_name
merge 1:1 repo_name using ../id_repo_name.dta
	keep if _merge == 3
	drop _merge
	rename repo_name github_repo
	
merge 1:1 id_repo using ../6_centralities_Cargo-repo-nonmissing.dta
	keep if _merge == 3
	drop _merge 
save ../10_popularity_centrality-projects.dta, replace

use ../10_popularity_centrality-projects.dta, clear
	drop if Size == 0  // some packages have zero size

	// truncate Popularity and centrality 
	
	// simple scatter plot
	scatter Popularity ev_centrality
	graph export popularity-ev_centrality.jpg, replace
	
	scatter Popularity katz_centrality
	graph export popularity-katz_centrality.jpg, replace

	scatter Popularity indeg_centrality
	graph export popularity-indeg_centrality.jpg, replace
	
	// binscatter
// 	winsor2 ev_centrality, replace cuts(0 99) trim
	binscatter Popularity ev_centrality
	graph export bs_popularity-ev_centrality.jpg, replace
	
// 	winsor2 katz_centrality, replace cuts(0 99) trim
	binscatter Popularity katz_centrality
	graph export bs_popularity-katz_centrality.jpg, replace
	
// 	winsor2 indeg_centrality, replace cuts(0 99) trim
	binscatter Popularity indeg_centrality
	graph export bs_popularity-indeg_centrality.jpg, replace

	// number of releases and popularity should be truncated as well
	winsor2 NumReleases, replace cuts(0 99) trim
	winsor2 Popularity, replace cuts(0 99) trim
	
	// number of contributors vs popularity
	binscatter NumContributors Popularity
	graph export bs_t99_numcontributors_popularity.jpg, replace
	
	binscatter NumContributors katz_centrality
	graph export bs_t99_numcontributors_katz_centrality.jpg, replace

	binscatter NumContributors indeg_centrality
	graph export bs_t99_numcontributors_indeg_centrality.jpg, replace

	// regressions
	regress Popularity NumContributors
	regress Popularity katz_centrality
	
	// 
	// activity vs. popularity plots
	//
	gen top_pop = 0
	replace top_pop = 1 if Popularity > 1800 // 138 changes, 99pct
	gen bot_pop = 0 
	replace bot_pop = 1 if Popularity <= 4 // 3581 changes, 50pct
	
	gen top_katz_cent = 0
	replace top_katz_cent = 1 if katz_centrality > 0.024288 // 77 changes, 99pct
	gen bot_katz_cent = 0
	replace bot_katz_cent = 1 if katz_centrality <= 0.0011881 // 4036 changes, 50pct
	
	gen top_indeg_cent = 0
	replace top_indeg_cent = 1 if indeg_centrality > 0.0068458 // 69 changes, 99pct
	gen bot_indeg_cent = 0
	replace bot_indeg_cent = 1 if indeg_centrality <= 0 // 4036 changes, 50 pct

save ../tmp_10_popularity_centrality-projects.dta, replace


//
// CENTRALTIES
//
// KATZ CENTRALITY VS. POPULARITY
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../tmp_10_popularity_centrality-projects.dta, clear
	
	keep if top_katz_cent == 1 | top_pop == 1. // 331 obs left
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_katz_cent == 1
	hist logSize if top_pop == 1
	
	hist NumContributors if top_katz_cent == 1
	hist NumContributors if top_pop == 1
	
	twoway (hist logSize if top_katz_cent == 1, start(-6) width(2) color(red%30)) ///
		(hist logSize if top_pop == 1, start(-5) width(2) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_logSize_CentralPopular.jpg, replace
		
	twoway (hist NumContributors if top_katz_cent == 1, start(0) width(125) color(red%30)) ///
		(hist  NumContributors if top_pop == 1, start(0) width(125) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_NumContributors_CentralPopular.jpg, replace
		
	twoway (hist NumReleases if top_katz_cent == 1, start(0) width(10) color(red%30)) ///
		(hist   NumReleases if top_pop == 1, start(0) width(10) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_NumReleases_CentralPopular.jpg, replace
save ../11_top_popularity_centrality-projects-1.dta, replace

// TOP VS. BOTTOM KATZ CENTRALITY
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../tmp_10_popularity_centrality-projects.dta, clear
	
	keep if top_katz_cent == 1 | bot_katz == 1
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_katz_cent == 1
	hist logSize if bot_katz_cent == 1
	
	hist NumContributors if top_katz_cent == 1
	hist NumContributors if bot_katz_cent == 1
	
	twoway (hist logSize if top_katz_cent == 1, start(-8) width(2) color(red%30)) ///
		(hist logSize if bot_katz_cent == 1, start(-8) width(2) color(blue%30)), ///
		legend(order(1 "Log(Size) Most Central" 2 "Log(Size) Least Central"))
	graph export hist_logSize_TopLeast_Central.jpg, replace
		
	twoway (hist NumContributors if top_katz_cent == 1, start(0) width(100) color(red%30)) ///
		(hist  NumContributors if bot_katz_cent == 1, start(0) width(100) color(blue%30)), ///
		legend(order(1 "NumContrib Most Central" 2 "NumContrib Least Central"))
	graph export hist_NumContributors_TopLeast_Central.jpg, replace
		
	twoway (hist NumReleases if top_katz_cent == 1, start(0) width(10) color(red%30)) ///
		(hist   NumReleases if bot_katz_cent == 1, start(0) width(10) color(blue%30)), ///
		legend(order(1 "NumReleases Most Central" 2 "NumReleases Least Central"))
	graph export hist_NumReleases_TopLeast_Central.jpg, replace 
save ../11_top_popularity_centrality-projects-2.dta, replace

// TOP VS. BOTTOM POPULARITY
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../tmp_10_popularity_centrality-projects.dta, clear
	
	keep if top_pop == 1 | bot_pop == 1
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_pop == 1
	hist logSize if bot_pop == 1
	
	hist NumContributors if top_pop == 1
	hist NumContributors if bot_pop == 1
	
	twoway (hist logSize if top_pop == 1, start(-8) width(2) color(red%30)) ///
		(hist logSize if bot_pop == 1, start(-8) width(2) color(blue%30)), ///
		legend(order(1 "Log(Size) Most Popular" 2 "Log(Size) Least Popular"))
	graph export hist_logSize_TopLeast_Popularity.jpg, replace
		
	twoway (hist NumContributors if top_pop == 1, start(0) width(100) color(red%30)) ///
		(hist  NumContributors if bot_pop == 1, start(0) width(100) color(blue%30)), ///
		legend(order(1 "NumContrib Most Popular" 2 "NumContrib Least Popular"))
	graph export hist_NumContributors_TopLeast_Popularity.jpg, replace
		
	twoway (hist NumReleases if top_pop == 1, start(0) width(10) color(red%30)) ///
		(hist   NumReleases if bot_pop == 1, start(0) width(10) color(blue%30)), ///
		legend(order(1 "NumReleases Most Popular" 2 "NumReleases Least Popular"))
	graph export hist_NumReleases_TopLeast_Popular.jpg, replace 
save ../11_top_popularity_centrality-projects-3.dta, replace

// INDEGREE CENTRALITY VS. POPULARITY
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../tmp_10_popularity_centrality-projects.dta, clear	
	keep if top_indeg_cent == 1 | top_pop == 1. // 331 obs left
	gen foo = log(Size / (1024*1024))
	drop Size
	rename foo logSize // MB
	
	hist logSize if top_indeg_cent == 1
	hist logSize if top_pop == 1
	
	hist NumContributors if top_indeg_cent == 1
	hist NumContributors if top_pop == 1

	twoway (hist logSize if top_indeg_cent == 1, start(-6) width(2) color(red%30)) ///
		(hist logSize if top_pop == 1, start(-5) width(2) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_logSize_IndegCentralPopular.jpg, replace
		
	twoway (hist NumContributors if top_indeg_cent == 1, start(0) width(125) color(red%30)) ///
		(hist  NumContributors if top_pop == 1, start(0) width(125) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_NumContributors_IndegCentralPopular.jpg, replace
		
	twoway (hist NumReleases if top_indeg_cent == 1, start(0) width(10) color(red%30)) ///
		(hist   NumReleases if top_pop == 1, start(0) width(10) color(blue%30)), ///
		legend(order(1 "Most Central" 2 "Most Popular"))
	graph export hist_NumReleases_IndegCentralPopular.jpg, replace
save ../11_top_popularity_centrality-projects-4.dta, replace


//
// NUMCONTRIBUTORS VS. SIZE
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo
use tmp_10_popularity_centrality-projects.dta, clear
// 	gen foo = log(Size / (1024*1024))
// 	drop Size
// 	rename foo logSize // MB
	gen foo = Size/(1024*1024)
	drop Size
	rename foo Size
	
// 	winsor2 Size, replace cuts(0,90) trim
// 	winsor2 TotalCommits, replace cuts(0,90) trim
// 	winsor2 NumContributors, replace cuts(0,90) trim. // TODO: careful
	drop if TotalCommits > 1000000  // all of these are somewhat suspicious repositories
	drop if NumContributors > 150
	drop if Size > 38.3  // p99
	
	scatter NumContributors Size
	graph export NumContrib_Size.jpg, replace
	
	scatter TotalCommits Size
	graph export TotalCommits_Size.jpg, replace
	
	scatter TotalCommits NumContributors
	graph export TotalCommits_NumContributors.jpg, replace

	gen Binned_NumContrib = round(NumContributors/10,1)
	gen AvgNumCommits = TotalCommits / NumContributors
	bysort Binned_NumContrib: egen AvgCommits = mean(AvgNumCommits)
	keep Binned_NumContrib AvgCommits
	duplicates drop
	
	line AvgCommits Binned_NumContrib
	graph export AvgCommits_BinnedNumContrib.jpg, replace
	

// ============================================================================
//
// Pypi
//
// ============================================================================

//
// PRELIMINARY ANALYSES
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Pypi/
insheet using "dependencies_Pypi.csv", delimiter(";") names clear
	rename projectid id_from
	rename dependencyprojectid id_to
	keep id*
duplicates drop
	drop if id_from == "Project ID"
	destring id*, replace
outsheet using "dependencies_Pypi-projects.csv", delimiter(";") replace


//
// 1_maintainer_githubID.dta
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Pypi/covariates
insheet using "Maintainer_GithubID.csv", delimiter(",") names clear 
	rename project name_project
save "1_maintainer_githubID.dta", replace


//
// 2_maintainer_github_metadata.dta
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using "Maintainer_github_metadata.csv", delimiter(",") names clear 
	rename contributor_github_url maintainer_github_url

	// data not filled for 2/3 of the maintainers
	gen pct_code_review = round(100*code_review / contributions)
	gen pct_commits = round(100*commits / contributions)
	gen pct_issues = round(100*issues / contributions)
	gen pct_pull_requests = round(100*pull_requests / contributions)
	
save "2_maintainer_github_metadata-full.dta", replace
outsheet using "2_maintainer_github_metadata-full.csv", delimiter(",") replace

	sort maintainer_github_url year
	bysort maintainer_github_url: gen MaintainerSeniority = _N
	bysort maintainer_github_url: egen MaintainerActivity = sum(contributions)
	gen MaintainerAvgActivity = MaintainerActivity / MaintainerSeniority

	keep maintainer_github_url Maintainer*
	duplicates drop
	
save "2_maintainer_github_metadata.dta", replace
outsheet using "2_maintainer_github_metadata.csv", delimiter(",") replace
 

//
// 2_contributor_commits.dta
//
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using "Contributor_commits-clean.csv", delimiter(";") names clear 
	
	drop if contributor_github_url == ""  // 5,476 observations lost
	sort name_project contributor_github_url
	
save "2_contributor_commits-full.dta", replace
outsheet using "2_contributor_commits-full.csv", delimiter(",") replace

	bysort name_project: gen num_contributors_alt = _N

	bysort contributor_github_url: gen ContributorExperience = _N
	bysort contributor_github_url: egen ContributorTotalCommits = sum(contributor_commits)
	gen ContributorActivty = ContributorExperience / ContributorTotalCommits

	keep name_project contributor_github_url Contributor*
	
	duplicates drop
	
save "2_contributor_commits.dta", replace
outsheet using "2_contributor_commits.csv", delimiter(",") replace
	bysort name_project: egen TotalContributorCommits = sum(ContributorTotalCommits)
	keep name_project TotalContributorCommits
	duplicates drop 
save 12_contributors_project.dta, replace
	
	
	
	
	

// ==============================================================================
//
// NOT USED
//
// ==============================================================================
// NOTE: based on dependency graph with versions

cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/
insheet using centrality_dependencies_Cargo-merged.csv, delimiter(";") clear
	split node, p(-)
	rename node1 key1
	drop node* 
	order key1
	sort key1
	duplicates drop
	
	destring key1, replace
	bysort key1: egen ev_cent_mean = mean(ev_centrality)
	bysort key1: egen deg_cent_mean = mean(deg_centrality)
	
	keep key1 *_mean
	duplicates drop 

save 5_centralities_cargo.dta, replace
outsheet using 5_centralities_cargo.csv, delimiter(";") replace

// based on dependency graph on project level
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
insheet using ../centrality_dependencies_Cargo-projects.csv, delimiter(";") clear
	rename node key1
	sort key1
save 5_centralities_cargo-projects.dta, replace
outsheet using 5_centralities_cargo-projects.csv, delimiter(";") replace
	


	
	
	
	
	
	
	

// summary stats of most central and most popular packages
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../10_popularity_centrality-projects.dta, clear

	// table for most central projects
	gsort - degree

	order name_project degree ev_centrality deg_centrality Popularity Size NumContributors NumReleases
	keep name_project degree ev_centrality deg_centrality Popularity Size NumContributors NumReleases
	keep in 1/10
	
	texsave using 5_centralities_list.tex, replace
	
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
use ../10_popularity_centrality-projects.dta, clear
	// table for most popular projects
	gsort - Popularity
	drop if Size == 978321408 // drop rust language repositories
	drop if Size == 4383047
	
	order name_project degree ev_centrality deg_centrality Popularity Size NumContributors NumReleases
	keep name_project degree ev_centrality deg_centrality Popularity Size NumContributors NumReleases
	keep in 1/10
	
	texsave using 5_popularity_list.tex, replace

	
	
	
	
cd ~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/Cargo/covariates
// // prepare maintainer data
// use 2_maintainer_github_metadata-full.dta, clear
// 	bysort maintainer_github_url: egen total_contributions = sum(contributions)
// 	drop if total_contributions > 125000 // there seem to be a handful of either malicious or automated accounts that we are dropping here
//
// 	keep maintainer_github_url total_contributions
// 	duplicates drop
// save 2_maintainer_github_metadata-full-total.dta, replace
//
// // prepare mapping
insheet using Maintainer_GithubID.csv, delimiter(",") clear names
//
// merge m:1 maintainer_github_url using 2_maintainer_github_metadata-full-total.dta
// 	keep if _merge == 3
// 	drop _merge

// PROJECT.MAJOR.MINOR.VERSION LEVEL
// TODO: double check why we have so few matches between centrality and popularity


// ============================================================================
//
// DEPRECATED
// 
// ============================================================================

// // 5_master_covariates_Cargo-merged.dta -- the actual mapping
// insheet using "key_dependencies_Cargo-merged.dat", delimiter(";") clear   // created by 30_create_dependency_graph.py so that node names can be used in gephi
// 	split key, p("-")
// 	replace key3 = key3 + "-" + key4 if key4 != ""
// 	drop key4
// 	replace key2 = key2 + "-" + key3 if key3 != ""
// 	drop key3
// save "covariates/5_key_dependencies_Cargo-merged.dta", replace
// outsheet using "covariates/5_key_dependencies_Cargo-merged.csv", delimiter(",") replace
//
// 	destring key1, replace
// 	merge m:1 key1 using "covariates/4_projects_cargo.dta"
// keep if _merge == 3
// 	drop _merge
//
// 	sort name_project
// 	keep name_project key1 node_id
// duplicates drop
// 	merge m:1 name_project using "covariates/3_covariates_maintainers.dta"
// keep if _merge == 3
// 	drop _merge
//
// save "covariates/5_master_covariates_Cargo-merged.dta", replace
// outsheet using "covariates/5_master_covariates_Cargo-merged.csv", delimiter(",") replace
