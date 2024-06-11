setBatchMode(true); //Start batch mode

/*///This macro was created by Anne BEGHIN, Eric DENARIER and Benoit BOULAN
This was performed on (Fiji Is Just) ImageJ 1.51h version

This macro allow the selection of neurons to quantify the neurite arborescence from mosaic acquisitions 
(stitching of  X20 objective image of a coverslip and binning of 1 or 2 )
It can proceeds several mosaic saved in different folders.

This macro requires in each folder :
		2 images(beware to the naming ) :
			An original image of neurons (e.g neurons.tif)
			The corresponding original image of nucleus (e.g nuclei.tif)

Additional plugins to install in Fiji/plugins: 
		The plugin "Analyze Skeleton 2D/3D"  Developped by Ignacio Arganda-Carreras http://imagej.net/AnalyzeSkeleton
		the Morphology plugins from Gabriel Landini's website : http://www.mecourse.com/landinig/software/software.html

Additional file to install in Fiji/LUT: 
		neurons.lut 
		
It creates 6 stacks : 
	Neurones = Stack_Neuron_Original
	Binary Neurons = Stack_Neuron
	Skeletonized = Stack_Skelet
	Cell Body (a circle at the position of the nuclei enlarge to fit the cell body ) = Stack_Body
	Skelet+Cell Body=Stack_BodySkelet
	Skelet-Cell Body= Stack_NobodySkelet
	
	and a ROIset corresponding to the selected neurons on the original image

*/
 macro "AutoNeuriteJ (all in one)" {

//////////////////////// Parameters////////////////////////////////////////////////////
Taille=1;                   // Scalling factor to reduce image size before processing 
minNeuron_part1=1500;	    // Minimal neuron area in order to exclude debris
NucleusDiameter=30;	    // Diameter of nuclei
minNeuriticTree=15;         // Defines the minimal length to be a primary neurite tree if smaller it is erased from the skeleton
minNeuron_part2=2000;        // Defines the minimal area in the binary image to be a neuron if less the neuron is not considered
minLengthSkelet=100;         // Defines the minimal length of a neuritic skeleton if smaller the neuron is not considered
minAxon=150; 		    // Minimal length to be an axon (pixels)
minNeurite=15; 		    // Minimal length to be a neurite (pixels)
ratio=1.5; 		    // Minimal ratio between (mean primary neurite length) and (axonal length)--> Minimal ratio to be an axon

/////////////////////////////pic up the previewsly used settings///////////////////////////
ParameterFile=getDirectory("temp"); 

filesaver=File.exists(ParameterFile+"/AutoneuriteJ_settings.txt");

if (filesaver==1){									// verify if the macro has already been used is the current computer and gets previously used parameters if true
	
	filestring=File.openAsString(ParameterFile+"/AutoneuriteJ_settings.txt");
	rows=split(filestring, "\n");
	settings=newArray(rows.length);
		
	for(i=0; i<rows.length; i++){                 ///////////transform text from txt files into integers
		columns=split(rows[i],"\t");
		settings[i]=parseFloat(columns[0]);
	}
	Taille=settings[0];
	minNeuron_part1=settings[1];
	NucleusDiameter=settings[2];
	minNeuriticTree=settings[3]; 
	minNeuron_part2=settings[4];  
	minLengthSkelet=settings[5];
	minAxon=settings[6];				
	minNeurite=settings[7]; 				
	ratio=settings[8];
}

////////////////////////Launcher///////////////////////
mainDir = "E:\\Experiments\\Primary_Cell_Culture\\Compound_Testing\\Cerebellum\\SC_SF_bpV\\3rd_Test\\2nd Replicate 110723\\Images\\Analysis\\From_TIFF\\dmso"; //getDirectory("Choose main directory"); 
mainList = getFileList(mainDir); 

for (fileIndex=0; fileIndex<mainList.length; fileIndex++) {  /* for loop to parse through names in main folder*/ 
    if(!endsWith(mainList[fileIndex], "/")){   /* if the name is not a subfolder...*/ 
		continue;
	}

//macro "AutoNeuriteJ Part I  [F1]" {

     
	// RUNNING PART 1
	/* This macro helps the segmentation of neurons and nuclei images.
	it asks parameter for the minimal size of a binarized neurons to remove debris.
	Asks for an average nuclei diameter. The specific character in the name of Neuron and nuclei images
	And the folder name were are the images.
	It saves :
	the original neuron images
	the binarized image 
	the binarized nuclei 
	in a new subfolder "resultats"
	*/
	

	tubName="Alexa488";
	Taille=0.3256;
  // Original image pixel size (in micro meter)
	minNeuron_part1=155; // Minimal area for a neuron (in pixels)
	nucleiName="DAPI";
 // Nucleus image name must contain
	NucleusDiameter=30; // Nucleus diameter (in pixels)

	minDoG=1;
	maxDoG=NucleusDiameter*3;

	////////////////////////////////////////////Save the new parameters used/////////////////////////
	filesaver=File.exists(ParameterFile+"/AutoneuriteJ_settings.txt");
	if (filesaver==1){
		File.delete(ParameterFile+"/AutoneuriteJ_settings");
	}
	
	print("Log");
	selectWindow("Log");
	run("Close");
	////Part1settings////
	print(Taille); /// (1)
	print(minNeuron_part1); /// (2)
	print(NucleusDiameter); ///(3)
	////Part2_settings////
	print(minNeuriticTree); // (4) 
	print(minNeuron_part2);  // (5)
	print(minLengthSkelet); // (6) 
	////Part3 settings////
	print(minAxon); 	///(7)			
	print(minNeurite); 	///(8)			
	print(ratio); 		///(9)	
	
	selectWindow("Log");
	saveAs("Text",ParameterFile+"/AutoneuriteJ_settings");
	run("Close");
	////////////////////////////////////////////////////////////////////////////////////////////////////////////

	NucleusSurface=NucleusDiameter/2*NucleusDiameter/2*PI;
	minNucleusSurface=NucleusSurface/3;
	maxNucleusSurface=NucleusSurface*3;

	
	rep=mainDir + "\\" + mainList[fileIndex];
	nomrep=File.getName(rep);
	liste=getFileList(rep);
	File.makeDirectory(rep+"\\resultats_"+nomrep+"\\");
	newRep=rep+"\\resultats_"+nomrep+"\\";
	
	for (i=0;i<liste.length;i++) 
		{
		setBatchMode(true);	
		
		if (indexOf(liste[i], nucleiName)!=-1)
			{
	  			open(rep+liste[i]);
			getPixelSize(unite, pixelWidth, pixelHeight);
			title=getTitle();
			
			unite2=unite;
			pixelWidth2=pixelWidth;

			if(Taille!=pixelWidth){
				//waitForUser("Original image pixel size do not match with metadata value. \n Please reset original pixel size in properties.");run("Properties...", "unit="+unite+" pixel_width="+pixelWidth+" pixel_height="+pixelHeight);
				run("Properties...");
				getPixelSize(unite2, pixelWidth2, pixelHeight2);
				print("Original pixel size manually reset from "+pixelWidth+" "+unite+" to "+pixelWidth2+" "+unite2);
			}
			run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");	
		
			getDimensions(width, height, channels, slices, frames);
			xsize=width*Taille;
			ysize=height*Taille;
	
	
			filter (title, "Gaussian Blur", "Gaussian Blur", NucleusDiameter/4, NucleusDiameter*4);  
	
			setAutoThreshold("Default dark");
	
			setBatchMode(false);
			run("Threshold...");
			waitForUser("Set the threshold for nuclei : \n You may do nothing !!!\n Zoom in to see better !!!");
			setBatchMode(true);
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Watershed");
			run("Analyze Particles...", "size=&minNucleusSurface-&maxNucleusSurface circularity=0.5-1.00 show=Masks exclude in_situ");
			title=File.nameWithoutExtension;
			run("Scale...", "x=Taille y=Taille width="+xsize+" height="+ysize+"  interpolation=Bilinear create");
			run("Multiply...", "value=256.000");
			saveAs("tiff",newRep+"Nucleus_Bin_"+title); close();close();
	
		}
	
		if (indexOf(liste[i], tubName)!=-1)
			{
			open(rep+liste[i]);
			
			
			title=File.nameWithoutExtension;
			getPixelSize(unite, pixelWidth, pixelHeight);
			getDimensions(width, height, channels, slices, frames);
			
			if(Taille!=pixelWidth){
				waitForUser("Original pixel size do not match with metadata value. \n Please reset original pixel size in properties.");run("Properties...", "unit="+unite+" pixel_width="+pixelWidth+" pixel_height="+pixelHeight);
				run("Properties...");
				getPixelSize(unite2, pixelWidth2, pixelHeight2);
			}
			else{
				unite2=unite;
				pixelWidth2=pixelWidth;
			}
			run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");		
			xsize=width*Taille;
			ysize=height*Taille;
		 
	
			run("Scale...", "x=Taille y=Taille width="+xsize+" height="+ysize+"  interpolation=Bilinear create");
			saveAs("tiff",newRep+"Neuron_"+title);
			close();
			title=getTitle();
		 
			filter (title,"Median","Gaussian Blur",minDoG,maxDoG);
			setAutoThreshold("Triangle dark");	
	
			setBatchMode(false);
			run("Threshold...");
			waitForUser("Set the threshold for Neurons");
			setBatchMode(true);
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Analyze Particles...", "size=&minNeuron_part1-1000000 circularity=0-0.5 show=Masks exclude in_situ");
			getDimensions(width, height, channels, slices, frames);
			
			xsize=width*Taille;
			ysize=height*Taille;
			run("Scale...", "x=Taille y=Taille width="+xsize+" height="+ysize+"  interpolation=Bilinear create");
			run("Multiply...", "value=2500.000");
			saveAs("tiff",newRep+"NeuronBin_"+nomrep); close(); close();
	
		}
	}
	print("Original pixel size :"+pixelWidth2+" "+unite2);
	print("Image scaling factor =" + Taille);
	print("Quantification pixel size =" + pixelWidth2*(1/Taille) +" "+unite2);
	print("Minimal area for a neuron (in pixels) : "  +minNeuron_part1);
	print("Nucleus diameter (in pixels) : " +NucleusDiameter);			
	print("Filter size for neuron segmentation  : Median blur (pxl)="+minDoG+" and Gaussian blur (pxl)="+maxDoG);
	selectWindow("Log"); saveAs("Text",newRep+"Part I-settings_of_"+nomrep); run("Close");	
//}

//macro "AutoNeuriteJ Part II [F1]" {
/////////////////////////////// Some parameters to be tuned.

minNeuron_part2=155;
 // Minimal skeleton length of a neuritic tree (in pixels)
minNeuriticTree=30;
  // Minimal skeleton length of a neuritic tree (in pixels)
minLengthSkelet=30;
  // Minimal total skeleton length to consider a neuron (in pixels)

////////////////////////////////////////////Save the new parameters used/////////////////////////
filesaver=File.exists(ParameterFile+"/AutoneuriteJ_settings.txt");
if (filesaver==1){
	File.delete(ParameterFile+"/AutoneuriteJ_settings");
		////Part1settings////
}
print("Log");
selectWindow("Log"); run("Close");
print(Taille); /// (1)
print(minNeuron_part1); /// (2)
print(NucleusDiameter); ///(3)
////Part2_settings////
print(minNeuriticTree); // (4) 
print(minNeuron_part2);  // (5)
print(minLengthSkelet); // (6) 
////Part3 settings////
print(minAxon); 	///(7)			
print(minNeurite); 	///(8)			
print(ratio); 		///(9)	

selectWindow("Log"); saveAs("Text",ParameterFile+"/AutoneuriteJ_settings"); run("Close");

//////////////////////////////////////////////////////////////////////////////////////////////////////////// 
 
///////////////////////// Records the time at start of the macro 
 getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour0, minute0, second, msec);
 setBatchMode(true);	
 
//////////////////////////stack opening 
nombre_condition=1;
 // Ask for the number of stack to be analysed
path=newArray(nombre_condition);
list=newArray(20);


	

	
for (e=0; e<nombre_condition; e++) {                   // Ask for the directory of each stack to be analysed.
	path[e] = newRep;
}
	
for (e=0; e<nombre_condition; e++) {                                          // Files opening

	list = getFileList(path[e]); titre_culture=File.getName(path[e]);

////////////////////////// Sets information about the cells that will not be considered
	number_Neurons=0;
	connected_neurons=0;  // Sets the number of connected neurons that will be removed
	SkelettooShort=0; // Sets the number of cells with too short skelet that will be removed

		/////////// Opens the original neurons image called Neuron_XXX
		for (fileNumber=0; fileNumber<list.length; fileNumber++) {	
			
			if (startsWith(list[fileNumber], "Neuron_")) {
				open(path[e] + list[fileNumber]);     run("Set Scale...", "distance=1"); rename("Originale"); 
				title2=File.nameWithoutExtension;   											
				run("8-bit"); run("Set Scale...", "distance=1");				
				sauvegarde=File.directory();
				File.makeDirectory(sauvegarde+"/r_"+title2); 
				}

		/////////// Opens the binary neurons image Called Neuron_Bin_XXX and removes on edges and less than minNeuron add to manager
			if (startsWith(list[fileNumber], "NeuronBin_")) {
				open(path[e] + list[fileNumber]); run("Set Scale...", "distance=1"); rename("Binneurons"); run("Select None");
				run("Analyze Particles...", "size="+minNeuron_part2+"-Infinity show=Masks exclude add in_situ");
				}

		/////////// Opens the binary nuclei image Called Nucleus_Bin_XXX
			if (startsWith(list[fileNumber], "Nucleus_Bin_")) {
				open(path[e] + list[fileNumber]); run("Set Scale...", "distance=1");rename("Nuclei");
				}
		}

////////////// Removes Neurons and nuclei when more or less than one nucleus per neuron
	nROI=roiManager("Count");
	
	for (i=0;i<nROI;i++){
		selectWindow("Nuclei");
		roiManager("Select", i); // selection of neurons in ROImanager
		run("Analyze Particles...", "size=0-Infinity summarize"); // counts number of nuclei in the neuron
	}
		
	selectWindow("Summary");
	IJ.renameResults("Results");
	selectWindow("Results");
	
	for (i=0;i<nResults;i++){
		count=getResult("Count",i);
	
		if (count!=1) { // Erases neurons and nuclei when 0 or more than 1 nucleus
			connected_neurons=connected_neurons+count;
			setForegroundColor(0, 0, 0);
			selectWindow("Nuclei");roiManager("Select", i);run("Fill", "slice");run("Select None");
			selectWindow("Binneurons");roiManager("Select", i);run("Fill", "slice");run("Select None");
		}
	}
	
	selectWindow("Results"); run("Close");
	roiManager("reset");

///////////////////and removes nuclei not in a neuron
	imageCalculator("AND", "Nuclei","Binneurons"); 

/////////////// Creates Image of cell bodies by dilating and opening the nuclei in neurons
	run("BinaryConditionalDilate ", "mask=Binneurons seed=Nuclei  iterations=10 create white");
	run("Options...", "iterations=2 count=1 black do=Open");
	run("BinaryConditionalDilate ", "mask=Dilated seed=Nuclei iterations=-1 white"); //removes small bodies after Opening
	saveAs("tiff",sauvegarde+"/body_"+title2); rename("Bodies");


////////////////////// Add in ROImanager neurons with a single nucleus

	selectWindow("Binneurons"); run("Analyze Particles...", "add");
	number_Neurons=roiManager("count");
	
//////////////////////////////////////// Create images of Neurons  (Body-Skelet-BodySkelet-Original-Binarized-NoBodySkelet)//////////////////

		newRoiSet=newArray();
		
		for(j=0;j<number_Neurons;j++){
			position=getPositions("Originale",j); //record neuron position 
			cutROI ("Originale",j);
			cutROI ("Bodies",j);
			cutROI("Binneurons",j);
			
			////////////////////"Neuron skeleton" images creation from the binarized image////////////////////
			run("Duplicate...", "title=BodSkele_"+j  );
			run("Skeletonize");
			
		
			
			////////////////////"Body and skeleton" and "Skeleton without body" images creation from the binarized image////////////////////
						
			imageCalculator("Add", "BodSkele_"+j ,"Bodies_"+j);
			imageCalculator("Subtract create stack", "BodSkele_"+j,"Bodies_"+j);rename("NoBodySkelet_"+j);

			//////////////////Test if skelet is large enough in NoBodySkelet image //////////////////	
			
			run("Set Measurements...", "area shape limit redirect=None decimal=3");			
			setAutoThreshold("Default dark");
			run("Measure");
			
			lengthSkelet=getResult("Area",0);		
			run("Clear Results");
			
				if (lengthSkelet<= minLengthSkelet) {   //// If length skelet is too short
					selectWindow("Originale_"+j); close();
					selectWindow("Bodies_"+j); close();
					selectWindow("BodSkele_"+j); close();
					selectWindow("Binneurons_"+j);close();	
					newRoiSet=push(newRoiSet,j);
					SkelettooShort=SkelettooShort+1;
				}

					
////////////////////////////// Removes loops in the neuron's skeleton /////////////////////////////////////////
//// ///////////////////////// We repeat the Skeleton Analysis if a loop is found
				else {   //// If length skelet is long enough
					mean=1;
					selectWindow("Bodies_"+j); rename("Bodies_"+j+"_"+position[0]+"_"+position[1]); // record neuron coordinates in image name
					while (mean!=0) { mean=analyzeSkeleton("BodSkele_"+j,1);} // prunes the lowest Intensity branch until no more loops
								

// Detection of neurites extremities and substraction to the skeleton to increase distances between extremities 

						selectWindow("BodSkele_"+j); run("Duplicate...", "title=pointes2");	
						run("BinaryConnectivity ", "white");
						setThreshold(2, 2); run("Convert to Mask");	
						imageCalculator("Subtract", "BodSkele_"+j,"pointes2");
 
						selectWindow("pointes2"); close();

			////////////////////////////////////
						mean=1;

						while (mean!=0) { mean=analyzeSkeleton("BodSkele_"+j,2);}	}  // Prunes the shortest branch if a loop is created
					
		
					
					selectWindow("NoBodySkelet_"+j);close();
					// End else if lengthSkelet long enough
		call("java.lang.System.gc");    //////Cleans the memory

		} // End of neuron number

//////////////////////// Correction and Saving of the ROIset		
	run("Select None");	
	if (newRoiSet.length!=0){	
		roiManager("select", newRoiSet); //// Selects the neurons that have been removed because of a too short skelet (lines 190)	
		roiManager("delete");	
	}

	roiManager("Deselect");
	roiManager("Save", sauvegarde+"/r_"+title2+"/RoiSet.zip"); 
	selectWindow("Results"); run("Close"); roiManager("reset");


////////////////////////  Stack creation (Body-Skelet-BodySkelet-NoBodySkelet-Original-Binarized) /////////////////////////////////////////////////////
	run("Images to Stack", "method=[Copy (center)] name=Stack_Neuron_Original title=Originale_ use");
	run("Images to Stack", "method=[Copy (center)] name=Stack_Neuron title=Binneurons_ use");
	run("Images to Stack", "method=[Copy (center)] name=Stack_Body title=Bodies_ use");
	run("Images to Stack", "method=[Copy (center)] name=Stack_BodySkelet title=BodSkele_ use");
	imageCalculator("Subtract create stack", "Stack_BodySkelet","Stack_Body"); rename("Stack_NoBodySkelet");


// Additional Cleaning of short primary neurite < minNeuriticTree
	selectWindow("Stack_NoBodySkelet");
	nbSlice=nSlices;
				
				for (slice=1;slice<=nbSlice;slice++){
					selectWindow("Stack_NoBodySkelet");
					setSlice(slice);
					run("Analyze Particles...", "add");				
					nROI=roiManager("Count");
					run("Set Measurements...", "area redirect=None decimal=3");
					
					for (i=0;i<nROI;i++){
						selectWindow("Stack_NoBodySkelet");setSlice(slice);
						roiManager("Select", i);
						run("Measure");
						areaNeurite=getResult("Area");
						run("Clear Results");	
						
							if (areaNeurite<=minNeuriticTree){
								setForegroundColor(0, 0, 0);							
								selectWindow("Stack_NoBodySkelet");setSlice(slice);roiManager("Select", i);run("Fill", "slice");														
							}
							
						run("Select None");
					}
				}
				
	selectWindow("Stack_BodySkelet"); close();
	imageCalculator("Add create stack", "Stack_Body","Stack_NoBodySkelet"); rename ("Stack_BodySkelet");
				
				


		
////////////////// Saving and closure of stacks and ROI selections in a file named "resultat" created in the original image path////////////////

	print("min Primary Neurite Tree size (in pixels) :  "+minNeuriticTree);
	print("min Neurons area (in pixels) :  " + minNeuron_part2);
	print("min Total Skeleton size (in pixels) :  "+minLengthSkelet);	
	print("Isolated neurons:   "+number_Neurons+"   Number of connected Neurons :     " + connected_neurons+"   Number of Skeleton too short :  "+SkelettooShort);	
	print ("Number of isolated neurons considered:   "+number_Neurons-SkelettooShort);		
	selectWindow("Log"); saveAs("Text", sauvegarde+"/Part II-settings and neurons_count"); run("Close");			

	
	part2ResultFolder=sauvegarde+"/r_"+title2;
	selectWindow("Stack_BodySkelet");run("Remove Overlay");
	saveAs("tiff",part2ResultFolder+"/Stack_BodySkelet"); close();

	selectWindow("Stack_Body");
	saveAs("tiff",part2ResultFolder+"/Stack_Body"); close();

	selectWindow("Stack_Neuron");run("Remove Overlay");
	saveAs("tiff",part2ResultFolder+"/Stack_Neuron_Bin"); close();

	selectWindow("Stack_Neuron_Original");run("Remove Overlay");
	saveAs("tiff",part2ResultFolder+"/Stack_Neuron_Original"); close();

	selectWindow("Stack_NoBodySkelet");run("Remove Overlay");
	saveAs("tiff",part2ResultFolder+"/Stack_NoBodySkelet"); close();

	call("java.lang.System.gc");    //////Cleans the memory
								

	selectWindow("Binneurons"); close();
	selectWindow("Originale"); close();
	selectWindow("Bodies"); close();
	selectWindow("Nuclei"); close();
	selectWindow("Results"); run("Close");

	if (isOpen("Summary")){		selectWindow("Summary");close();}
	run("Close All");
	roiManager("reset");
}    //// End of number of conditions
 
 

 //////// Records time at the end of macro and prints the running time
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour1, minute1, second, msec);

hourSpent=hour1-hour0;
minSpent=(minute1-minute0)+60*hourSpent;
hourTotal=floor(minSpent/60);
minTotal=minSpent-(hourTotal*60);

print ("program ran for : "+hourTotal+"h"+minTotal+"min");
 
//} // End of macro part II


//macro "AutoNeuriteJ_partIII [F1]" {
//////////////////////// Different measures : neurone cell body expansion /////////////////////////////////////////////////////
//////////////////////////////////Parameters/////////////////////////////////////////

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour0, minute0, second0, msec);

//////////////////////////stack opening 
nombre_condition=1;
path=newArray(nombre_condition);
list=newArray(20);

minNeurite=30;  // Minimal size for a Neurite (in pixels)  
minAxon=100
;    // Minimal size for an Axon (in pixels)
ratio=2.;
       // Ratio (Axon Length)/(Longest Primary Neurites length) to be an Axon


////////////////////////////////////////////Save the new parameters used/////////////////////////
filesaver=File.exists(ParameterFile+"/AutoneuriteJ_settings.txt");
if (filesaver==1){
	File.delete(ParameterFile+"/AutoneuriteJ_settings");
}
	print("Log");
	selectWindow("Log"); run("Close");
		////Part1settings////
	print(Taille); /// (1)
	print(minNeuron_part1); /// (2)
	print(NucleusDiameter); ///(3)
	////Part2_settings////
	print(minNeuriticTree); // (4) 
	print(minNeuron_part2);  // (5)
	print(minLengthSkelet); // (6) 
	////Part3 settings////
	print(minAxon); 	///(7)			
	print(minNeurite); 	///(8)			
	print(ratio); 		///(9)	
	
	selectWindow("Log"); saveAs("Text",ParameterFile+"/AutoneuriteJ_settings"); run("Close");

////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
for (e=0; e<nombre_condition; e++) {                   // Ask for the directory of each stack to be analysed.
	path[e] = part2ResultFolder;
}
	
for (e=0; e<nombre_condition; e++) {                                          // Files opening

////////////////////////// Sets information about the cells that will not be considered
number_Neurons=0;
connected_neurons=0;  // Sets the number of connected neurons that will be removed
SkelettooShort=0; // Sets the number of cells with too short skelet that will be removed


//////////////////////////////// Set Parameters to define Neurites and Axon


setBatchMode(true);



//////////NB: the file selected must contain any other folders than those who will be analysed (presence of other files isn't important)////


		
		open(path[e] + "/Stack_Body.tif");rename("Stack_Body");
		open(path[e] +  "/Stack_BodySkelet.tif");   rename("Stack_BodySkelet");  
		open(path[e] +  "/Stack_NoBodySkelet.tif");rename("Stack_NoBodySkelet");
		open(path[e] + "/Stack_Neuron_Original.tif");run("Enhance Contrast...", "saturated=0.3 normalize process_all use");rename("Stack_Neuron_Originale");


		setBackgroundColor(0, 0, 0);
		setForegroundColor(255, 255, 255);
		
		long_neurite=newArray(1000); type_neurite=newArray(1000);
	

//////////////////////////////// Prints Results Header ////////////////////////////////////////////////////////////////
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour1, minute1, second, msec);
		print (hour1+"h:"+minute1);
		print(path[e]);
		print("\n AutoNeuriteJ_Part III_settings : \n minimal size of Axons (in pixels)="+minAxon);
		print("minimal size of Neurites (in pixels)="+minNeurite);
		print("Axonal size ratio="+ratio);
		print("Neurite Order : 1=axon / 2=primary neurite / 3=secondary neurite / 4=tertiary neurite ...");
		print("\n Measures : ");
		print("Neuron# \t Primary Neurites # \t Neurite Order  \t Primary Neurites mean Length \t Neurite Length \t Longest Neurite Length \t Axonal Tree length \t Axonal Tree Branches #");
		
		
	run("Options...", "iterations=1 count=1 black do=Dilate stack");
	
				
		////////////////////////////////  Loop for each neuron to create trees of neurite ///////////////////////////////////////////////
		
		nb_neurones=nSlices;
		q=1;
		endNbNeuron=0; meanPrimaryLength=newArray(); meanPrimaryNumber=newArray();
		nbAxon=0;
		
		for(j=1;j<=nb_neurones;j++){

//////////////////Search for potential absence of Body in the Stack_Body			
selectWindow("Stack_Body");	setSlice(j);
getStatistics(area, mean);Body=mean;
if(Body==0){selectWindow("Stack_NoBodySkelet"); setSlice(j); run("Delete Slice");
			selectWindow("Stack_BodySkelet"); setSlice(j); run("Delete Slice");
			selectWindow("Stack_Body"); setSlice(j); run("Delete Slice");
			selectWindow("Stack_Neuron_Originale"); setSlice(j); run("Delete Slice");
			j=j-1;
			nb_neurones=nb_neurones-1;}
else{
////////////////////////////////////////////////////////////////////////////////////				
			selectWindow("Stack_NoBodySkelet");	setSlice(j); run("Duplicate...", "title=masque_arbres");	 // Neurites skeleton									
			selectWindow("Stack_BodySkelet"); setSlice(j); 	run("Duplicate...", "title=pointes"); run("Duplicate...", "title=S_et_S"); // used to detect neurites extremities
			selectWindow("Stack_Body");	setSlice(j);	run("Duplicate...", "title=CBS");			// Cell body of neuron number j									
			selectWindow("pointes"); 
			run("BinaryConnectivity ", "white");
			setThreshold(2, 2); run("Convert to Mask");												// Connectivity value correspond to ends of neurites
			run("Set Measurements...", "  bounding redirect=None decimal=3");
			run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing display clear"); // Gives X and Y of each neurites end
			selectWindow("Results"); coordinates=getInfo();
			
			Nb_pointes =nResults;
			run("Clear Results");
		
/////////////// Search for each tree the longest branch without the ROI manager (too slow) ///////////////////////////////
		if(Nb_pointes==0){selectWindow("Stack_NoBodySkelet"); setSlice(j); run("Delete Slice");
						selectWindow("Stack_BodySkelet"); setSlice(j); run("Delete Slice");
						selectWindow("Stack_Body"); setSlice(j); run("Delete Slice");
						selectWindow("Stack_Neuron_Originale"); setSlice(j); run("Delete Slice");
						j=j-1;
						nb_neurones=nb_neurones-1;
						selectWindow("masque_arbres");close();
						selectWindow("S_et_S");close();					
						selectWindow("pointes");close();
						selectWindow("CBS");close();
						}
		else{
	
			grand_neurite = 0; neurite_majeur = 0;
			for(i=0;i<Nb_pointes;i++) {																// for each ends	
				type_neurite[i]=2; 																	// Neurite type: 1=axon, 2=neurite (Default), 3...=secondary branch (or more) 
				selectWindow("S_et_S"); 
				nom="Neurone_"+j+"_Neurite"+i+1;	run("Duplicate...", "title="+nom); 				// Create one image by neurite
				x=getCoordinate("BX", i); y=getCoordinate("BY", i);											// Coordinate of the ieme neurite end

				run ("Specify...", "width=2 height=2 x=" + x + " y=" + y + " centered"); 			// Trace a pruning protection around the neurite end
				setForegroundColor(255, 255, 255);                                      
				run("Fill", "slice"); 																// Filling of the selected area, paved on the end
				run("BinaryThin ", "kernel_a=[0 2 2 0 1 0 0 0 0 ] rotations=[rotate 45] iterations=-1 white"); 	// pruning
				imageCalculator("AND", nom,"masque_arbres");										// Image of Neurone_j_Neurite_i	
				doWand(x, y,0.0,"8-connected");run("Clear Outside");	run("Fill", "slice");	run("Skeletonize");		// Potential cleaning of other neurons
				
				
				/////////////////// Measure of the length of the neurite using Analyze Skeleton plugins
				selectWindow(nom);
				rename("geo");
				run("Geodesic Distance Map", "marker=pointes mask=geo distances=[Quasi-Euclidean (1,1.41)] output=[32 bits] normalize");
				selectWindow("geo-geoddist");
				getMinAndMax(min, max);close();
				long_neurite[i]=max; 						// Length between the nucleus and the end
				selectWindow("geo");
				rename(nom);
									
				if(long_neurite[i]>=neurite_majeur) {neurite_majeur=long_neurite[i]; grand_neurite=i;}				// Record the longest neurite
			}  

				
//********************************  Overlapping neurites Search*****************************************************************

//////////////// Comparison between Neurite i and i+1
			Neurite_by_size = Array.rankPositions(long_neurite);							// return the value i of the Neurites by ascending size order
			Neurite_by_size = Array.invert(Neurite_by_size);									// return the value i of the Neurites by descending size order
				
			for(i=0;i<Nb_pointes;i++) {											// for each neurite i
								
				x=getCoordinate("BX", Neurite_by_size[i]); y=getCoordinate("BY", Neurite_by_size[i]); 						// Gets coordinates  
				nom="Neurone_"+j+"_Neurite"+Neurite_by_size[i]+1;									// Gets name		
				for(k=0;k<Nb_pointes;k++) {										// for each other neurite k
					if(k!=Neurite_by_size[i]){	
						nom2="Neurone_"+j+"_Neurite"+k+1; 								// Gets name
						selectWindow(nom2); run("Select None");												// 
						selectWindow(nom);run("Select None");doWand(x, y, 0.0, "8-connected");				// Selects Neurite i
						selectWindow(nom2);	run("Restore Selection");					// overlay of selected neurite i in the image neurite k 
						getStatistics(area, mean);overlap=mean;							//  measures overlap between the two neurites
						
						if(overlap!=0) {												// If overlap exists
							if(long_neurite[Neurite_by_size[i]]>long_neurite[k]) {						//  if i length>k  
								type_neurite[k]=type_neurite[k]+1;						// Increase k type of neurite 
								imageCalculator("Subtract ", nom2, nom);				// reDraws k without overlap 
							}
													
							else {														//  if k length>i
								type_neurite[Neurite_by_size[i]]=type_neurite[Neurite_by_size[i]]+1;						// Increase i type of neurite reDraws i without overlap
								imageCalculator("Subtract ", nom, nom2);				// reDraws i without overlap				
								} // end else																								
						} // end if	overlap!=0					
					}
				} // end for(k=i+1;k<Nb_pointes;k++)
			} // End neurites apparies
			long_neurite = newArray(1000);												// Reset of arrays for next neuron
			Neurite_by_size = newArray(1000);
	/////////////////////////////  measure of neurite's length, and rank  //////////////////////////////////////////////////////////////
			grand=newArray(1000);	MoyPrim=0	; NbrPrim=0	;	NbrNeurite=0;	LongPrim=0;													// For mean length computation of primary
			pointesSuprime=0;
			for(i=0;i<Nb_pointes;i++){ 													            // for each neurite i
				nom="Neurone_"+j+"_Neurite"+i+1;selectWindow(nom);
				
				run("Select None");getStatistics(area, mean, min, max, std, histogram);
						if (mean==0){
				grand[i]=0;
				area=0;
				selectWindow(nom);close();}
			
			else{
				
				
				x=getCoordinate("BX", i); y=getCoordinate("BY", i);
				//selectWindow("Results");	IJ.renameResults("Results2");

				run("Analyze Skeleton (2D/3D)", "prune=none");
				area=getResult("Maximum Branch Length", 0);
				grand[i]=getResult("Maximum Branch Length", 0);
				
				close();
				close("Tagged Skeleton");

				//selectWindow("Results2");	IJ.renameResults("Results");

				if(i!= grand_neurite && area > minNeurite && type_neurite[i]==2){      
					NbrPrim=NbrPrim+1;
					LongPrim=LongPrim+area; 					  // Sum of primary segments, without the longest
					MoyPrim=LongPrim/(NbrPrim);                   // Mean of primary segments, without the longest
				}
			}
		}	

/////////////////////////////////////////Axon determination : potential axon vs major primary dendrite /////////////////////////////////////////////////////////////////////////////////////				
								
			if(neurite_majeur> minAxon) type_neurite[grand_neurite]=1;                             // If the longest primary exceeds the minimal length of axon, it is classed as axon.
				grand_primaire=1;
				for(i=0;i<Nb_pointes;i++){ 													       // For each neurite i
					if(grand_primaire <= grand[i] && grand[i]>minNeurite && type_neurite[i]==2) {  // If the primary dendrite is longer than the former  
						grand_primaire=grand[i];     						        	           // it becomes the longest repertory													   
						if(neurite_majeur< ratio*grand_primaire){ 								   // If the longest primary dendrite is  smaller than the primary longest neurite*ratio, it is declassified from axon to dendrite
							type_neurite[grand_neurite]=2;										   
						}
					}
				}
				if(type_neurite[grand_neurite]<=2){													// If an axon is detected, added to primary neurites stats (number, total length, mean length) 
					NbrPrim=NbrPrim+1;																
					LongPrim=LongPrim+neurite_majeur;
					MoyPrim=LongPrim /(NbrPrim); 
				}
////////////////////////////////////////////Results writing//////////////////////////////////////////////////////	
			
				for(i=0;i<Nb_pointes;i++){ 															// for each neurite i
					if(i != grand_neurite && grand[i]>minNeurite)
						print(j,"\t",NbrPrim, " \t ",type_neurite[i], "\t ",MoyPrim, "\t ", grand[i]);
	
					if(i == grand_neurite && grand[i]>minNeurite)
						print(j,"\t",NbrPrim, " \t ",type_neurite[i], "\t ",MoyPrim, "\t ", grand[i], "\t ", grand[i]); // Add of a column for the longuer primary neurite
					
				}
										
					
//**************************************Image Stack creation corresponding to neurite skeleton, quantified by color in function of their connections
				
				selectWindow("masque_arbres");close();
				selectWindow("S_et_S");close();					
				selectWindow("pointes");close();
				selectWindow("CBS");close();
				
				for(i=0;i<Nb_pointes;i++){ // // For each end, we obtain the type of neurite (type_neurite), in a specific color 
				
					if (grand[i]<=minNeurite){									// If  neurite too small, it is deleted of the stack Neurone_use
						
					if(isOpen("Neurone_"+j+"_Neurite"+i+1)){	
					selectWindow("Neurone_"+j+"_Neurite"+i+1); close();}		
					} 
					
					else {
					if(isOpen("Neurone_"+j+"_Neurite"+i+1)){	
					selectWindow("Neurone_"+j+"_Neurite"+i+1);
					run("Select None");getStatistics(area, mean, min, max, std, histogram);
						if (mean!=0){
							setThreshold(255, 255);
							run("Create Selection");
							setForegroundColor(type_neurite[i], type_neurite[i], type_neurite[i]);
							run("Fill", "slice");
						} 
					run("Select None");
					}}
				}
	
/////////////////////////////////////////Test if their is several neurite to make a stack	//////////////////////////

				numberExtermitiesAfterCleaning=0;
				for(i=0;i<Nb_pointes;i++){
					if(isOpen("Neurone_"+j+"_Neurite"+i+1)){numberExtermitiesAfterCleaning++;}
				}
				

///////////////  Axonal Tree length ////////////////////////////////////////////////////
	if(numberExtermitiesAfterCleaning==0){  									// The number of neurite can be reduced to 0 line 781
	selectWindow("Stack_Neuron_Originale"); setSlice(q); run("Delete Slice");
	selectWindow("Stack_Body"); setSlice(q); run("Delete Slice");
		selectWindow("Stack_NoBodySkelet"); setSlice(q); run("Delete Slice");
	selectWindow("Stack_BodySkelet"); setSlice(q); run("Delete Slice");
		
		
	//print ("la macro est passee par la");
	//setBatchMode("exit and display");
	q=q-1;
	nb_neurones=nb_neurones-1;					
	j=j-1;
	}
	
	if(numberExtermitiesAfterCleaning>=1){
		if(numberExtermitiesAfterCleaning==1){// If  one neurite
		for(i=0;i<Nb_pointes;i++){
			if(isOpen("Neurone_"+j+"_Neurite"+i+1)){	
				selectWindow("Neurone_"+j+"_Neurite"+i+1);
				rename("MAX_Neuron_"+j);run("Duplicate...", "title=Axon_total");
				}	}}
				
		if(numberExtermitiesAfterCleaning>=2){ 									// If more than one neurite on the neuron j >> make a stack
		run("Images to Stack", "name=Neuron_"+j+" title=Neurone_ use");								// Neurite stacks of one neuron
		run("Z Project...", "projection=[Max Intensity]"); run("Duplicate...", "title=Axon_total");	// z projection of neurites on an unique image, and duplication
		selectWindow("Neuron_"+j);close();
		}
		
		selectWindow("Axon_total");
		run("8-bit");
		run("Multiply...", "value=255");
		x=getCoordinate("BX", grand_neurite); y=getCoordinate("BY", grand_neurite);doWand(x, y, 0.0, "8-connected"); // Selection of the longest main tree (axon and connection)
		run("Clear Outside");
		//selectWindow("Results");		IJ.renameResults("Results2");
				
		run("Analyze Skeleton (2D/3D)", "prune=none");
		selectWindow("Results");
		moy=getResult("Average Branch Length", 0);
		n=getResult("# Branches", 0);
		full_axon=moy*n;
		
		close();
		close("Tagged Skeleton");
		//selectWindow("Results2");		IJ.renameResults("Results");

		selectWindow("Axon_total");							
		run("BinaryConnectivity ", "white");
		setThreshold(2, 2); run("Convert to Mask");			
		run("Set Measurements...", "  bounding redirect=None decimal=3");
		run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing display clear");
		Nb_branchement =nResults-2;																	// Compute number of branch in this tree 
					
		if(type_neurite[grand_neurite]==1){
			print(j+"\t\t\t\t\t\t\t\t  "+full_axon+"\t   "+Nb_branchement);             // Writing results
			nbAxon=nbAxon+1;
		}

		selectWindow("Axon_total");close();	
		selectWindow("MAX_Neuron_"+j);				
		run("neurons"); 																		// Color type for the neurites
		
	}	
		
	q++;		
	endNbNeuron=endNbNeuron+1;
	meanPrimaryLength=push(meanPrimaryLength,MoyPrim);
	meanPrimaryNumber=push(meanPrimaryNumber,NbrPrim);
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
		}}}   // Next Neuron

		
run("Images to Stack", "name=Stack_of_Neurones title=MAX use");

selectWindow("Stack_BodySkelet");close();
selectWindow("Stack_NoBodySkelet");close();
	
					
File.makeDirectory(path[e]+"/Measures");


Array.getStatistics(meanPrimaryLength, min, max, meanPL, stdDevPL);
Array.getStatistics(meanPrimaryNumber, min, max, meanPN, stdDevPN);

print ("\t\t\t\t\t\t\t\t------------ Summary ------------");
print ("\t\t\t\t\t\t\t\t Number of mesured neurons :  \t"+endNbNeuron);
print ("\t\t\t\t\t\t\t\t Percentage of neuron with axon :  \t"+nbAxon/endNbNeuron*100+"\t%");
print ("\t\t\t\t\t\t\t\t Mean primary neurite length and stedDev:  \t"+meanPL+"   \t   "+stdDevPL);
print ("\t\t\t\t\t\t\t\t Mean primary neurite number and stedDev:  \t"+meanPN+"   \t   "+stdDevPN);

selectWindow("Log");
saveAs("Text", path[e] +"/Measures/Results");
run("Close");
	
selectWindow("Stack_Body");run("neurons");
run("RGB Color");	
selectWindow("Stack_of_Neurones");
run("RGB Color");
selectWindow("Stack_Neuron_Originale");
run("RGB Color");
imageCalculator("Transparent-zero create stack", "Stack_Neuron_Originale","Stack_of_Neurones");
selectWindow("Result of Stack_Neuron_Originale"); rename("Overlay");

imageCalculator("Transparent-zero stack", "Overlay","Stack_Body");
saveAs("tiff", path[e] +"/Measures/Overlay");close();
selectWindow("Stack_of_Neurones");
saveAs("tiff", path[e] +"/Measures/Stack_of_Neurites");

run("Clear Results");
run("Close All");
roiManager("reset");
if (isOpen("Summary")){		selectWindow("Summary");close();}
} // End of condition
	
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour1, minute1, second1, msec);


hourSpent=hour1-hour0;
minSpent=(minute1-minute0)+60*hourSpent;
secSpent=(second1-second0)+60*minSpent;
hourTotal=floor(minSpent/60);
minTotal=minSpent-(hourTotal*60);
secTotal=secSpent-(minTotal*60);
print ("program ran for : "+hourTotal+"h"+minTotal+"min"+secTotal+"sec");
	
//} // End of Macro part 3


} // end for all files

}

/////////////////////////////////////////Functions//////////////////////////////////////////////////////////////////////////////

function filter (image,filter1,filter2,size1,size2) {
	selectWindow(image);
	run("Duplicate...", "title=1");
	run("Duplicate...", "title=2"); 
	if (filter1=="Median"){
		selectWindow("1");run(filter1+"...","radius="+size1);}
	if (filter1=="Gaussian Blur"){
		selectWindow("1");run(filter1+"...","sigma="+size1);} 

	if (filter2=="Median"){
		selectWindow("2");run(filter2+"...","radius="+size2);}
	if (filter2=="Gaussian Blur"){
	selectWindow("2");run(filter2+"...","sigma="+size2);} 

	imageCalculator("Subtract","1","2");
	selectWindow("2"); close();
	selectWindow(image);close();
	selectWindow("1"); rename (image);
}
function cutROI (image,z) {
	selectWindow(image);
	roiManager("Select", z);
	run("Duplicate...", "title="+image+"_"+z);getDimensions(width, height, channels, slices, frames);
	setBackgroundColor(0, 0, 0); run("Clear Outside");run("Canvas Size...", "width="+width+2+" height="+height+2+" position=Center");

}
function analyzeSkeleton (image,parameter)	{
				
	selectWindow(image);
	run("Duplicate...", "title=[duplicata]"); 
	selectWindow(image);
					
	if (parameter==1)	run("Analyze Skeleton (2D/3D)", "prune=[lowest intensity branch] original_image=Originale_"+j);
	if (parameter==2)	run("Analyze Skeleton (2D/3D)", "prune=[shortest branch]");
						
	imageCalculator("Subtract create", "duplicata",image);
	selectWindow("Result of duplicata");
	getStatistics(area, moy, min, max, std, histogram);	
	selectWindow("Result of duplicata");	close();
	selectWindow("duplicata");	close();
	if (isOpen("Tagged skeleton")){		selectWindow("Tagged skeleton");close();}
		return moy;
						
}
function getCoordinate(column,row) {

	lines = split(coordinates, "\n");
	values = split(lines[row+1], "\t"); /// +1 because the first line is the Title of columns

	if(column== "BX"){return values[1];}//BX
	if(column== "BY"){return values[2];}//BY
}
function push(array,value) {
  a = newArray(array.length+1);
  for(i=0; i<array.length; i++) a[i]= array[i];
  a[a.length-1] = value;
  return a;
}	
function getPositions(image,z){
	selectWindow(image);
	roiManager("Select", z);
	centerROI=newArray(2);
	getSelectionBounds(Xpos, Ypos, width, height);
	centerROI[0]=(Xpos+width/2); centerROI[1]=(Ypos+height/2);
	return centerROI;
}
//////////////////////////////END of macro AutoneurJ (all in one)	

setBatchMode(false); //End batch mode
