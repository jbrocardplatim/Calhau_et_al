//Macro_pollen used to classify pollen grain meiosis
//Starts with an open hyperstack of z & time images
//@2026 J. Brocard (PLATIM) for A. Calhau & T. Widiez (RDP)

if (nImages == 0) exit("!!! NO IMAGE  !!!");
//--- INITIALIZATION ---
interval=8.333; //interval between two time points in sec
pix_res=0.1625; //pixel resolution in µm, from a 40x objective used with CQ1
roiManager("reset");
t=getImageName(getTitle());
rename(t);
version="_v8";

//---Ask the user for the directory with the present macro
//---Note = stacks to analyze must be present in the same directory as the macro
dirmac=getDirectory("Macro Directory?");
//dirmac="C:/DATA JAC/Users/Andrea Calhau/Macro pollen";
dirim=getDirectory("image");
dirmac = replace(dirmac, "\\", "/");
dirim = replace(dirim, "\\", "/");

//---Recompose the arborescence of the stacks to be analyzed...
//print("dirim",dirim, dirim.length);
//print("dirmac",dirmac, dirmac.length);
deb=dirmac.length;
fin=deb+1; mac="";
while(mac!="/"){
	fin++;
	mac=substring(dirim,fin,fin+1);
}
dirim=dirmac+ substring(dirim,deb,fin)+"/";
//... and initialize the Results file
print(dirim);
print("Interval = "+interval+" min");

//---Collect the genotype of studies pollens
tot=substring(dirim,lengthOf(dirmac));
date=substring(tot,0,7);
vs=1;
while (substring(tot,vs,vs+2)!="vs") vs++;
dir1=String.trim(substring(tot,9,vs));
dir2=String.trim(substring(tot,vs+2, lengthOf(tot)-1));

//---Choose the genotype to analyse = cat
if (File.exists(dirim+dir1)) a=File.delete(dirim+dir1);
File.makeDirectory(dirim+dir1);
if (File.exists(dirim+dir2)) a=File.delete(dirim+dir2);
File.makeDirectory(dirim+dir2);
bool1=true; bool2=true;
while (bool1==bool2){
	Dialog.create(tot);
	Dialog.addCheckbox(dir1,true);
	Dialog.addCheckbox(dir2,false);
	Dialog.show();
	bool1=Dialog.getCheckbox();
	bool2=Dialog.getCheckbox();
}
if (bool1) cat=dir1+"/";
if (bool2) cat=dir2+"/";
//print(dirim+cat);

//---Check for or create a directory for each category of meiosis 
if (!File.exists(dirim+cat+"lagging"+version)) File.makeDirectory(dirim+cat+"lagging"+version);
if (!File.exists(dirim+cat+"normal"+version)) File.makeDirectory(dirim+cat+"normal"+version);
if (!File.exists(dirim+cat+"autres"+version)) File.makeDirectory(dirim+cat+"autres"+version);
if (!File.exists(dirim+cat+"unfinished"+version)) File.makeDirectory(dirim+cat+"unfinished"+version);

//--- MANUAL ANALYSIS ---
//---Setup the manual analysis
run("Brightness/Contrast...");
Stack.setFrameInterval(interval);
setMinAndMax(100, 250);
setTool("rectangle");
waitForUser("Draw Square ROIs and click OK when finished");

//---From each drawn ROI...
nROIs=roiManager("Count");
if (nROIs>0) {
	print("Type\t Name\t z-proj\t t-proj\t duration (min)");
	nbl=0; nbu=0; nbn=0; nbo=0;
	for (r=0;r<nROIs;r++){
		roiManager("Select",r);
		//...determine the category...
		group=getMeiosisCategory();
		//...and set the corresponding Roi group
		Roi.setGroup(group); luno="";
		if (group==0){ //catégorie = lagging
			nbl++;
			tit=t+"_l"+nbl+".tif";
			run("Duplicate...", "title="+tit+" duplicate");
			luno="lagging";
			pos=newArray(4);
			pos=getMeiosisTime(tit);
			print("Lagging\t"+tit+"\t"+pos[2]+"->"+pos[3]+"\t"+pos[0]+"->"+pos[1]+"\t"+(pos[1]-pos[0])*interval);
		}
		if (group==1){ //catégorie = autres
			nbo++;
			tit=t+"_o"+nbo+".tif";
			run("Duplicate...", "title="+tit+" duplicate");
			luno="autres";
			print("Autres\t "+tit);
		}
		if (group==2){ //catégorie = unfinished
			nbu++;
			tit=t+"_u"+nbu+".tif";
			run("Duplicate...", "title="+tit+" duplicate");
			luno="unfinished";
			print("Unfinished\t "+tit);
		}
		if (group==3){ //catégorie = normal
			nbn++;
			tit=t+"_n"+nbn+".tif";
			run("Duplicate...", "title="+tit+" duplicate");
			luno="normal";
			pos=newArray(4);
			pos=getMeiosisTime(tit);
			print("Normal\t"+tit+"\t"+pos[2]+"->"+pos[3]+"\t"+pos[0]+"->"+pos[1]+"\t"+(pos[1]-pos[0])*interval);
		}
		run("Properties...", "pixel_width="+pix_res+" pixel_height="+pix_res+"  voxel_depth=1 unit=micron");
		saveAs("Tiff",dirim+cat+luno+version+"/"+tit);
		close(); 
	}
	close(); 
}
selectWindow("Log");
saveAs("Text",dirim+substring(cat,0, lengthOf(cat)-1)+"_"+substring(t,0,lengthOf(t)-0)+version+".txt");
run("Close");
roiManager("reset");

function getMeiosisTime(t){
	selectWindow(t);
	setSlice(1);
	setTool("hand");
	end=0;
	while (end==0){
		getCursorLoc(x,y,z,mod);
		if (mod==16) end=z;
	}
	Dialog.create("Z-projection");
	Dialog.addNumber("Begin",1);
	Dialog.addNumber("End",end+1);
	Dialog.show();
	begz=Dialog.getNumber();
	endz=Dialog.getNumber();
	run("Z Project...", "start="+begz+" stop="+endz+" projection=[Max Intensity] all");
	setMinAndMax(100, 250);
	end=0;
	while (end==0){
		getCursorLoc(x,y,z,mod);
		if (mod==16) end=z;
	}
	Dialog.create("Duration");
	Dialog.addNumber("Begin",1);
	Dialog.addNumber("End",end+1);
	Dialog.show();
	beg=Dialog.getNumber();
	end=Dialog.getNumber();
	run("Z Project...", "start="+beg+" stop="+end+" projection=[Max Intensity] all");
	close(); close();
	return newArray(beg,end,begz,endz);
}

function getMeiosisCategory(){
	mixup=0;
	while (mixup==0 || mixup>1){
		Dialog.create("Meiosis Category");
		Dialog.addCheckbox("lagging",true);
		Dialog.addCheckbox("normal",false);
		Dialog.addCheckbox("autre",false);
		Dialog.addCheckbox("unfinished",false);
		Dialog.show();
		booll=Dialog.getCheckbox();
		booln=Dialog.getCheckbox();
		boolo=Dialog.getCheckbox();
		boolu=Dialog.getCheckbox();
		mixup=booll+booln+boolo+boolu;
	}
	if (booll) g=0;
	if (boolo) g=1;
	if (boolu) g=2;
	if (booln) g=3;
	return g;
}

function getImageName(t){
	car=""; c=0;
	while (car!="W") {
		car=substring(t,c,c+1);
		c++;
	}
	w=substring(t,c-1);
	return w;
}
