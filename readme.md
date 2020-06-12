# ESC-DPA Coverage Analysis

For the ESC-DPA Coverage Analysis software you will need to download and install Matlab Runtime 2018b (ver 9.5) [FREE]:

 * http://ssd.mathworks.com/supportfiles/downloads/R2018b/deployment_files/R2018b/installers/win64/MCR_R2018b_win64_installer.exe
 * https://www.mathworks.com/products/compiler/matlab-runtime.html

Download the USGS folder (6 GBs of terrain data that the compiled app uses): https:// ...   
Unzip and Place the folder on the C drive, resulting in the following path: C:\USGS

Download the ESC-DPA Coverage Analysis Folder: https:// ...   
Example input files are provided.

Double click on `ESC_DPA_Coverage_rev2_3.exe` to run.

  *  Step 1: Load the ESC Location Data. Click the yellow button and select the file "example_ESC_Location_Inputs.xlsx"
  *  Step 2: Load the ESC Logic Data. Click the yellow button and select the file "example_ESC_Combo_Logic_Inputs.xlsx"

The ESC logic file can have multiple DPAs, for Example East1 and East8 combinations can be in the same file.

  * Step 3: If there is a custom ESC antenna model, click on "Custom" button in the Antenna Model group, and then click Load the ESC Antenna Data and select the file "example_ESC_Antenna_Pattern.xlsx"
  
If you select a custom antenna pattern, the Antenna Beamwidth and Antenna Gain from the ESC Location Inputs is ignored.
If there is no antenna pattern, click "WinnForum". This is the WinnForum Antenna Model.

To test the app, keep Sample Step Size at 50km and Computation Select to "Serial".

Note: If you have Matlab (full version/non-runtime), but not the Parallel Computing Toolbox, you will only be able to use the "Serial" option on that computer.

Note: You will need Word 2016 installed to have the word report generated.
If you do not have Word 2016 installed, select "Individual Plots", and all the plots will be saved at the location of the input files.

  * Step 4: Click the yellow button "Generate Report"

An example report has been generated (word document).


