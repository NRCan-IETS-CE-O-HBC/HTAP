import re
import xml.etree.ElementTree as ET
from os import listdir
from os.path import isfile, join

# INPUTS
mypath = "C:\\HTAP-archetypes\\NRCan-EGH-NewHousing"
fFrostDepth = 4.3


onlyfiles = [f for f in listdir(mypath) if isfile(join(mypath, f))]

# Initialize Outputs
AG_wall_m2=0.0
Attic_m2=0.0
Flat_Roof_m2 = 0.0
Exp_Floor_m2 = 0.0
Window_m2 = 0.0
Skylight_m2 = 0.0
BG_wall_m2 = 0.0
Slab_OG_m2 = 0.0
Bsmt_Slab_Below_Frost = 0.0
Bsmt_Slab_Above_Frost = 0.0
FloorHeaders = 0.0

fhd = open("NetArchGeomEach.csv", "w")
fhd.write("Frost Depth Used,"+str(fFrostDepth)+"\n")
fhd.write("Arch,Volume_m3,Net_AG_wall_m2,Gross_Floor_Header_m2,Net_Attic_m2,Net_Flat_Roof_m2,Exp_Floor_m2,Exp_Floor_Above_Unheated_Crawl_m2,Window_m2,Skylight_m2,Door_m2,Net_BG_wall_m2,Slab_OG_m2,Bsmt_Slab_Below_Frost,Bsmt_Slab_Above_Frost,Gross_AG_Wall_m2,FDWR,Total_Ext_Area_m2\n")

# Loop through the files
for h2k in onlyfiles:
    if not re.match('H2K$',h2k):
        next
    fullpath=mypath+'\\'+h2k
    tree = ET.parse(fullpath)
    root = tree.getroot()
    
    # Get the heated volume
    fVolume=float(root.find("./House/NaturalAirInfiltration/Specifications/House").attrib["volume"])
    
    # Start with the AG Walls
    fAreaAGWall = 0.0 # Net
    fAreaAGWallGross = 0.0
    fWinArea = 0.0
    fDoorArea = 0.0
    fHeader = 0.0
    for wall in root.findall("./House/Components/Wall"):
        for meas in wall.findall("Measurements"):
            fHeight = meas.attrib["height"]
            fPerim = meas.attrib["perimeter"]
            fAreaAGWall += (float(fHeight)*float(fPerim))
            fAreaAGWallGross += (float(fHeight)*float(fPerim))

        # Delete out window and door areas
        for wind in wall.findall("Components/Window"):
            height = float(wind.find("Measurements").attrib["height"])/1000.0
            width = float(wind.find("Measurements").attrib["width"])/1000.0
            fWinArea += (height*width)
        for door in wall.findall("Components/Door"):
            height = float(door.find("Measurements").attrib["height"])
            width = float(door.find("Measurements").attrib["width"])
            fDoorArea += (height*width)
        
        # Check for floor headers
        for header in wall.findall("Components/FloorHeader"):
            height = float(header.find("Measurements").attrib["height"])
            perimeter = float(header.find("Measurements").attrib["perimeter"])
            fHeader += (height*perimeter)
        
    fAreaAGWall = fAreaAGWall-fWinArea-fDoorArea
    
    # Check the ceilings
    fThisAttic = 0.0
    fThisFlat = 0.0
    fSkylight = 0.0
    for ceil in root.findall("./House/Components/Ceiling"):
        fArea = float(ceil.find("Measurements").attrib["area"])
        iType = int(ceil.find("Construction/Type").attrib["code"])
        
        # Delete out the skylight area
        for sky in ceil.findall("Components/Window"):
            height = float(sky.find("Measurements").attrib["height"])/1000.0
            width = float(sky.find("Measurements").attrib["width"])/1000.0
            fSkylight += (height*width)
        fArea -= fSkylight
        
        if iType == 2 or iType == 3 or iType == 6:
            fThisAttic += fArea
        else:
            fThisFlat += fArea
    
    fThisExpFlr = 0.0
    fThisOGSlab = 0.0
    fThisExpFlrAboveCrawl = 0.0
    fFdnWallArea = 0.0
    # Get the exposed floors
    for floor in root.findall("./House/Components/Floor"):
        fThisExpFlr += float(floor.find("Measurements").attrib["area"])
    # If crawlspace is unheated add to exposed floor count
    for crawl in root.findall("./House/Components/Crawlspace"):
        bIsCrawlHeated = root.find("./House/Temperatures/Crawlspace").attrib["heated"]
        if re.match('false',bIsCrawlHeated):
            fThisExpFlrAboveCrawl += float(crawl.find("Floor/Measurements").attrib["area"])
        else:
            # Crawlspace wall are a part of below-grade walls (per HTAP assumptions)
            fFdnWallArea += float(crawl.find("Floor/Measurements").attrib["perimeter"])*float(crawl.find("Wall/Measurements").attrib["height"])
            # Slab is part of total OG slab area
            fThisOGSlab += float(crawl.find("Floor/Measurements").attrib["area"])
            fAreaAGWallGross += float(crawl.find("Floor/Measurements").attrib["perimeter"])*float(crawl.find("Wall/Measurements").attrib["height"])
    
    # Get the slab area
    for slab in root.findall("./House/Components/Slab"):
        bIsRect = slab.find("Floor/Measurements").attrib["isRectangular"]
        if re.match('false',bIsRect):
            fThisOGSlab += float(slab.find("Floor/Measurements").attrib["area"])
        else:
            fThisOGSlab += (float(slab.find("Floor/Measurements").attrib["length"])*float(slab.find("Floor/Measurements").attrib["width"]))
    
    # Get the basement dimensions
    fBsmtSlabAFrost = 0.0
    fBsmtSlabBFrost = 0.0
    for bsmt in root.findall("./House/Components/Basement"):
        fFdnWallArea += float(bsmt.attrib["exposedSurfacePerimeter"])*float(bsmt.find("Wall/Measurements").attrib["height"])
        fHeightAboveGrade = float(bsmt.find("Wall/Measurements").attrib["height"])-float(bsmt.find("Wall/Measurements").attrib["depth"])
        fAreaAGWallGross += (float(bsmt.attrib["exposedSurfacePerimeter"])*fHeightAboveGrade) # Update the gross above-grade
        # Check for windows in basement
        fBsmtWind = 0.0
        fBsmtDoor = 0.0
        for wind in bsmt.findall("Components/Window"):
            height = float(wind.find("Measurements").attrib["height"])/1000.0
            width = float(wind.find("Measurements").attrib["width"])/1000.0
            fBsmtWind += (height*width)
            fWinArea += (height*width)
        for door in bsmt.findall("Components/Door"):
            height = float(door.find("Measurements").attrib["height"])
            width = float(door.find("Measurements").attrib["width"])
            fDoorArea += (height*width)
            fBsmtDoor += (height*width)
        
        # Check for floor headers
        for header in bsmt.findall("Components/FloorHeader"):
            height = float(header.find("Measurements").attrib["height"])
            perimeter = float(header.find("Measurements").attrib["perimeter"])
            fHeader += (height*perimeter)
        
        fFdnWallArea = fFdnWallArea-fBsmtWind-fBsmtDoor

        # Figure out where to log the slab area
        bIsRect = bsmt.find("Floor/Measurements").attrib["isRectangular"]
        fThisSlab = 0.0
        if re.match('true',bIsRect):
            fThisSlab = float(bsmt.find("Floor/Measurements").attrib["width"])*float(bsmt.find("Floor/Measurements").attrib["length"])
        else:
            fThisSlab = float(bsmt.find("Floor/Measurements").attrib["area"])
        
        fThisDepth = float(bsmt.find("Wall/Measurements").attrib["height"])
        if fThisDepth > fFrostDepth:
            fBsmtSlabBFrost += fThisSlab
        else:
            fBsmtSlabAFrost += fThisSlab
        
    
    # Now the walkout dimensions
    for walk in root.findall("./House/Components/Walkout"):
        fL1 = float(walk.find("Measurements").attrib["l1"])
        fL2 = float(walk.find("Measurements").attrib["l2"])
        fL3 = float(walk.find("Measurements").attrib["l3"])
        fL4 = float(walk.find("Measurements").attrib["l4"])
        fD1 = float(walk.find("Measurements").attrib["d1"])
        fD2 = float(walk.find("Measurements").attrib["d2"])
        fD3 = float(walk.find("Measurements").attrib["d3"])
        fD4 = float(walk.find("Measurements").attrib["d4"])
        fD5 = float(walk.find("Measurements").attrib["d4"])

        fPerim = 2*(fL1+fL2)
        fThisHeight = float(walk.find("Measurements").attrib["height"])
        fFdnWallArea += (fPerim*fThisHeight)
        # Get the configuration
        bWithSlab = walk.find("Measurements").attrib["withSlab"]
        bHasPony = walk.find("Wall").attrib["hasPonyWall"]
        
        # Calculate the above-grade wall areas
        fAreaSide = 0.0
        fAreaFront = 0.0
        fAreaBack = 0.0
        if bWithSlab == "true" and bHasPony == "true":
            fAreaSide = ((((2.0*fThisHeight)-fD1)/2.0)*(fL1-fL3-fL4))+(fL4*fThisHeight)+((fThisHeight-fD1)*fL3)
            fAreaSide = fAreaSide*2.0
            fAreaFront = fL2*(fThisHeight-fD1)
            fAreaBack = fL2*fThisHeight
        elif bWithSlab == "false" and bHasPony == "true":
            fAreaSide = (fL3*(fThisHeight-fD1))+((((2*fThisHeight)-fD1-fD2)/2)*(fL1-fL3))
            fAreaSide = fAreaSide*2.0
            fAreaFront = (fThisHeight-fD1)*fL2
            fAreaBack = (fThisHeight-fD2)*fL2
        elif bWithSlab == "false" and bHasPony == "false":
            fAreaFront = (((2*fThisHeight)-fD1-fD4)/2)*fL2
            fAreaBack = (((2*fThisHeight)-fD2-fD3)/2)*fL2
            fAreaSide = (fL3*(fThisHeight-fD1))+((((2*fThisHeight)-fD1-fD2)/2)*(fL1-fL3))
            fAreaSide += ((fL3*(fThisHeight-fD4))+((((2*fThisHeight)-fD3-fD4)/2)*(fL1-fL3)))
        elif bWithSlab == "true" and bHasPony == "false":
            fAreaFront = (((2*fThisHeight)-fD1-fD4)/2)*fL2
            fAreaBack = fThisHeight*fL2
            fAreaSide = (fL3*(fThisHeight-fD1))+((((2*fThisHeight)-fD1)/2)*(fL1-fL3-fL4))+(fL4*fThisHeight)
            fAreaSide += ((fL3*(fThisHeight-fD4))+((((2*fThisHeight)-fD4)/2)*(fL1-fL3-fL4))+(fL4*fThisHeight))
        
        fAreaAGWallGross += (fAreaSide+fAreaFront+fAreaBack)
        
        fBsmtSlabAFrost += (float(walk.find("Measurements").attrib["l1"])*float(walk.find("Measurements").attrib["l2"]))
        fBsmtWind = 0.0
        fBsmtDoor = 0.0
        for wind in walk.findall("Components/Window"):
            height = float(wind.find("Measurements").attrib["height"])/1000.0
            width = float(wind.find("Measurements").attrib["width"])/1000.0
            fBsmtWind += (height*width)
            fWinArea += (height*width)
        for door in walk.findall("Components/Door"):
            height = float(door.find("Measurements").attrib["height"])
            width = float(door.find("Measurements").attrib["width"])
            fDoorArea += (height*width)
            fBsmtDoor += (height*width)

        # Check for floor headers
        for header in walk.findall("Components/FloorHeader"):
            height = float(header.find("Measurements").attrib["height"])
            perimeter = float(header.find("Measurements").attrib["perimeter"])
            fHeader += (height*perimeter)

        fFdnWallArea = fFdnWallArea-fBsmtWind-fBsmtDoor
    
    # Add the header area to the gross above-grade
    fAreaAGWallGross += fHeader
    
    # Update the totals
    AG_wall_m2 += fAreaAGWall
    Attic_m2 += fThisAttic
    Flat_Roof_m2 += fThisFlat
    Exp_Floor_m2 += (fThisExpFlr+fThisExpFlrAboveCrawl)
    Window_m2 += fWinArea
    Skylight_m2 += fSkylight
    BG_wall_m2 += fFdnWallArea
    Slab_OG_m2 += fThisOGSlab
    Bsmt_Slab_Below_Frost += fBsmtSlabBFrost
    Bsmt_Slab_Above_Frost += fBsmtSlabAFrost
    FloorHeaders += fHeader

    # Determine the FDWR
    fFDWR=(fWinArea+fDoorArea)/fAreaAGWallGross
    
    # Determine total exterior, ground, and unconditioned space-facing surface area
    fTotalExtArea=fAreaAGWall+fHeader+fThisAttic+fThisFlat+fThisExpFlr+fThisExpFlrAboveCrawl+fWinArea+fSkylight+fDoorArea+fFdnWallArea+fThisOGSlab+fBsmtSlabBFrost+fBsmtSlabAFrost
    
    # Print to each file
    fhd.write(str(h2k)+","+str(fVolume)+","+str(fAreaAGWall)+","+str(fHeader)+","+str(fThisAttic)+","+str(fThisFlat)+","+str(fThisExpFlr)+","+str(fThisExpFlrAboveCrawl)+","+str(fWinArea)+","+str(fSkylight)+","+str(fDoorArea)+","+ str(fFdnWallArea)+","+str(fThisOGSlab)+","+str(fBsmtSlabBFrost)+","+str(fBsmtSlabAFrost)+","+str(fAreaAGWallGross)+","+str(fFDWR)+","+str(fTotalExtArea)+"\n")

fhd.close()

f = open("ArchGeom.csv", "w")
f.write("Frost Depth Used,"+str(fFrostDepth)+"\n")
f.write("AG_wall_m2,"+str(AG_wall_m2)+"\n")
f.write("Attic_m2,"+str(Attic_m2)+"\n")
f.write("Flat_Roof_m2,"+str(Flat_Roof_m2)+"\n")
f.write("Exp_Floor_m2,"+str(Exp_Floor_m2)+"\n")
f.write("Window_m2,"+str(Window_m2)+"\n")
f.write("Skylight_m2,"+str(Skylight_m2)+"\n")
f.write("BG_wall_m2,"+str(BG_wall_m2)+"\n")
f.write("Slab_OG_m2,"+str(Slab_OG_m2)+"\n")
f.write("Bsmt_Slab_Below_Frost,"+str(Bsmt_Slab_Below_Frost)+"\n")
f.write("Bsmt_Slab_Above_Frost,"+str(Bsmt_Slab_Above_Frost)+"\n")
f.write("Floor_Headers_m2,"+str(FloorHeaders)+"\n")
f.close()
