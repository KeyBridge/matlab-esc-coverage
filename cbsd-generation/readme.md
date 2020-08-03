The folder is “double zipped” because some mail servers flag .mat files as spam.
 
Open and run “START_HERE_initialization_partial_deployment_sort.m” as an example. The mat file is commented for instruction. Example CBSDs are also generated for Norfolk. The program outputs a .mat file and .cvs file of the CBSDs.
 
The CBSDs are sorted by census tract population (column #9 on the list_cbsd).  Assuming larger population centers will have CBSDs deployed first, partial CBSD deployment can be done in the following manner. If you wanted a 10% CBSD deployment, only take the top 10% of the CBSD list. You could do a 10% CatB deployment and a 5% CatA deployment, or any other combination of a percentage deployment for each CBSD type. You could also set a threshold for deployment, for example, any CBSD serving a census tract with population of more than 5,000 people.
 
Everything to generate CBSDs is contained within the folder. The DRAFT East/West DPAs (excluding the port DPAs) and the East/West 10km line are also included in the example. The points in mod_dpa_poly_east/west are the exact points (1 for 1) that in the draft DPA contours.  The 'downsampled_east10km' should be just the 10km points of the DPAs.
 
The census data and NLCD data is included as a .mat file.
 
