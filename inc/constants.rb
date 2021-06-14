


# Constants in Ruby start with upper case letters and, by convention, all upper case
R_PER_RSI = 5.678263
KWH_PER_GJ = 277.778
W_PER_KW = 1000.0
SF_PER_SM = 10.7639

# Setting Heating Degree Days
$HDDHash =  {
             "WHITEHORSE" => 6580 ,
            "TORONTO" => 3520 ,
            "OTTAWA" => 4500 ,
            "EDMONTON" => 5120 ,
            "CALGARY" => 5000 ,
            "MONTREAL" => 4200 ,
            "QUEBEC" => 5080 ,
            "HALIFAX" => 4000 ,
            "FREDERICTON" => 4670 ,
            "WINNIPEG" => 5670 ,
            "REGINA" => 5600 ,
            "VANCOUVER" => 2825 ,
            "PRINCEGEORGE" => 4720 ,
            "KAMLOOPS" => 3450 ,
            "YELLOWKNIFE" => 8170 ,
            "INUVIK" => 9600 ,
            "ABBOTSFORD" => 2860 ,
            "CASTLEGAR" => 3580 ,
            "FORTNELSON" => 6710 ,
            "FORTSTJOHN" => 5750 ,
            "PORTHARDY" => 3440 ,
            "PRINCERUPERT" => 3900 ,
            "SMITHERS" => 5040 ,
            "SUMMERLAND" => 3350 ,
            "VICTORIA" => 2650 ,
            "WILLIAMSLAKE" => 4400 ,
            "COMOX" => 3100 ,
            "CRANBROOK" => 4400 ,
            "QUESNEL" => 4650 ,
            "SANDSPIT" => 3450 ,
            "TERRACE" => 4150 ,
            "TOFINO" => 3150 ,
            "WHISTLER" => 4180 ,
            "FORTMCMURRAY" => 6250 ,
            "LETHBRIDGE" => 4500 ,
            "ROCKYMOUNTAINHOUSE" => 5640 ,
            "SUFFIELD" => 4770 ,
            "COLDLAKE" => 5860 ,
            "CORONATION" => 5640 ,
            "GRANDEPRAIRIE" => 5790 ,
            "MEDICINEHAT" => 4540 ,
            "PEACERIVER" => 6050 ,
            "REDDEER" => 5550 ,
            "ESTEVAN" => 5340 ,
            "PRINCEALBERT" => 6100 ,
            "SASKATOON" => 5700 ,
            "SWIFTCURRENT" => 5150 ,
            "URANIUMCITY" => 7500 ,
            "BROADVIEW" => 5760 ,
            "MOOSEJAW" => 5270 ,
            "NORTHBATTLEFORD" => 5900 ,
            "YORKTON" => 6000 ,
            "BRANDON" => 5760 ,
            "CHURCHILL" => 8950 ,
            "THEPAS" => 6480 ,
            "THOMPSON" => 7600 ,
            "DAUPHIN" => 5900 ,
            "PORTAGELAPRAIRIE" => 5600 ,
            "BIGTROUTLAKE" => 7650 ,
            "KINGSTON" => 4000 ,
            "LONDON" => 3900 ,
            "MUSKOKA" => 4760 ,
            "NORTHBAY" => 5150 ,
            "SAULTSTEMARIE" => 4960 ,
            "SIMCOE" => 3700 ,
            "SUDBURY" => 5180 ,
            "THUNDERBAY" => 5650 ,
            "TIMMINS" => 5940 ,
            "WINDSOR" => 3400 ,
            "GOREBAY" => 4700 ,
            "KAPUSKASING" => 6250 ,
            "KENORA" => 5630 ,
            "SIOUXLOOKOUT" => 5950 ,
            "TORONTOMETRESSTN" => 3890 ,
            "TRENTON" => 4110 ,
            "WIARTON" => 4300 ,
            "BAGOTVILLE" => 5700 ,
            "KUUJJUAQ" => 8550 ,
            "KUUJJUARAPIK" => 9150 ,
            "SCHEFFERVILLE" => 8550 ,
            "SEPTILES" => 6200 ,
            "SHERBROOKE" => 4700 ,
            "VALD'OR" => 6180 ,
            "BAIE-COMEAU" => 6020 ,
            "LAGRANDERIVIERE" => 8100 ,
            "MONT-JOLI" => 5370 ,
            "MONTREALMIRABEL" => 4500   ,
            "ST-HUBERT" => 4490    ,
            "STE-AGATHE-DES-MONTS" => 5390 ,
            "CHATHAM" => 4950 ,
            "MONCTON" => 4680 ,
            "SAINTJOHN" => 4570 ,
            "CHARLO" => 5500 ,
            "GREENWOOD" => 4140 ,
            "SYDNEY" => 4530 ,
            "TRURO" => 4500 ,
            "YARMOUTH" => 3990 ,
            "CHARLOTTETOWN" => 4460    ,
            "SUMMERSIDE" => 4600 ,
            "BONAVISTA" => 5000 ,
            "GANDER" => 5110 ,
            "GOOSEBAY" => 6670 ,
            "SAINTJOHNS" => 4800 ,
            "STEPHENVILLE" => 4850 ,
            "CARTWRIGHT" => 6440 ,
            "DANIELSHARBOUR" => 4760 ,
            "DEERLAKE" => 4760 ,
            "WABUSHLAKE" => 7710 ,
            "DAWSONCITY" => 8120 ,
            "FORTSMITH" => 7300 ,
            "NORMANWELLS" => 8510 ,
            "BAKERLAKE" => 10700 ,
            "IQALUIT" => 9980 ,
            "RESOLUTE" => 12360 ,
            "CORALHARBOUR" => 10720 ,
            "HALLBEACH" => 10720 ,
            "XXXXX" => 1
            }

# Setting hash for permafrost locations
$PermafrostHash =  {
            "YELLOWKNIFE"  => "discontinuous" ,
            "INUVIK"       => "continuous",
            "CHURCHILL"    => "continuous",
            "KUUJJUAQ"     => "continuous" ,
            "DAWSONCITY"   => "discontinuous" ,
            "NORMANWELLS"  => "discontinuous" ,
            "BAKERLAKE"    => "continuous",
            "IQALUIT"      => "continuous",
            "RESOLUTE"     => "continuous" ,
            "CORALHARBOUR" => "continuous",
            "HALLBEACH"    => "continuous"
            }

            

#Index of provinces, used by HOT2000 for region
$ProvArr = [ "BRITISH COLUMBIA",
             "ALBERTA",
             "SASKATCHEWAN",
             "MANITOBA",
             "ONTARIO",
             "QUEBEC",
             "NEW BRUNSWICK",
             "NOVA SCOTIA",
             "PRINCE EDWARD ISLAND",
             "NEWFOUNDLAND AND LABRADOR",
             "YUKON",
             "NORTHWEST TERRITORIES",
             "NUNAVUT",
             "OTHER" ]




$LegacyOptionsToIgnore = Set.new [
  "Opt-RoofPitch",
  "Opt-StandoffPV",
  "Opt-DHWLoadScale",
  "Opt-HRVduct",
  "Opt-FloorAboveCrawl",
  "Opt-FloorHeader",
  "Opt-MainWall"
]


AliasesForAttributes = {
  "Opt-GenericWall_1Layer_definitions" => "Opt-AboveGradeWall",
  "Opt-FloorAboveCrawl" => "Opt-ExposedFloor",
  "Opt-HRVonly" => "Opt-VentSystem",
  "Opt-CasementWindows" => "Opt-Windows", 
  "Opt-HVACSystem" => "Opt-Heating-Cooling",
  "Opt-DWHRSystem" => "Opt-DWHR"
}

$DoNotValidateOptions = Set.new [  "upgrade-package-list", "Opt-Archetype" ]




CostingSupport = Set.new [ "Opt-Ceilings",
              "Opt-AtticCeilings",
						  "Opt-FlatCeilings",
						  "Opt-CathCeilings",
              "Opt-ACH",
              "Opt-Windows",
              "Opt-DWHR",
              "Opt-AboveGradeWall",
              "Opt-Heating-Cooling",
              "Opt-VentSystem",
              "Opt-DHWSystem",
              "Opt-FoundationWallExtIns",
              "Opt-FoundationWallIntIns",
              "Opt-FoundationSlabBelowGrade",
              "Opt-FoundationSlabOnGrade",
              "Opt-FloorHeaderIntIns",
					    "Opt-ExposedFloor"
          ]

AttribThatAreNotUpgrades = Set.new [ "Opt-Baseloads",
                                     "Opt-FuelCost",
                                     "Opt-ResultHouseCode",
                                     "Opt-Specifications",
                                     "Opt-Location",
                                     "Opt-Ruleset",
                                     "Opt-Temperatures",
                                     "upgrade-package-list" ]




$epwRemoteServer = "https://energyplus.net/weather-download/north_and_central_america_wmo_region_4/CAN/"

$epwLocaleHash =  {
    "WHITEHORSE" => "YT/CAN_YT_Whitehorse.719640_CWEC/CAN_YT_Whitehorse.719640_CWEC.epw" ,
    "TORONTO" => "ON/CAN_ON_Toronto.716240_CWEC/CAN_ON_Toronto.716240_CWEC.epw" ,
    "OTTAWA" => "ON/CAN_ON_Ottawa.716280_CWEC/CAN_ON_Ottawa.716280_CWEC.epw" ,
    "EDMONTON" => "AB/CAN_AB_Edmonton.711230_CWEC/CAN_AB_Edmonton.711230_CWEC.epw",
    "CALGARY" => "AB/CAN_AB_Calgary.718770_CWEC/CAN_AB_Calgary.718770_CWEC.epw",
    "MONTREAL" => "PQ/CAN_PQ_Montreal.Intl.AP.716270_CWEC/CAN_PQ_Montreal.Intl.AP.716270_CWEC.epw" ,
    "QUEBEC" => "PQ/CAN_PQ_Quebec.717140_CWEC/CAN_PQ_Quebec.717140_CWEC.epw" ,
    "HALIFAX" => "NS/CAN_NS_Shearwater.716010_CWEC/CAN_NS_Shearwater.716010_CWEC.epw" ,
    "FREDERICTON" => "NB/CAN_NB_Fredericton.717000_CWEC/CAN_NB_Fredericton.717000_CWEC.epw" ,
    "WINNIPEG" => "MB/CAN_MB_Winnipeg.718520_CWEC/CAN_MB_Winnipeg.718520_CWEC.epw" ,
    "REGINA" => "SK/CAN_SK_Regina.718630_CWEC/CAN_SK_Regina.718630_CWEC.epw" ,
    "VANCOUVER" => "BC/CAN_BC_Vancouver.718920_CWEC/CAN_BC_Vancouver.718920_CWEC.epw" ,
    "PRINCEGEORGE" => "BC/CAN_BC_Prince.George.718960_CWEC/CAN_BC_Prince.George.718960_CWEC.epw" ,
    "KAMLOOPS" => "BC/CAN_BC_Kamloops.718870_CWEC/CAN_BC_Kamloops.718870_CWEC.epw" ,
    "YELLOWKNIFE" => "NT/CAN_NT_Yellowknife.719360_CWEC/CAN_NT_Yellowknife.719360_CWEC.epw" ,
    "INUVIK" => "NT/CAN_NT_Inuvik.719570_CWEC/CAN_NT_Inuvik.719570_CWEC.epw" ,
    "ABBOTSFORD" => "BC/CAN_BC_Abbotsford.711080_CWEC/CAN_BC_Abbotsford.711080_CWEC.epw" ,
    "CASTLEGAR" => "" ,
    "FORTNELSON" => "" ,
    "FORTSTJOHN" => "BC/CAN_BC_Fort.St.John.719430_CWEC/CAN_BC_Fort.St.John.719430_CWEC.epw" ,
    "PORTHARDY" =>  "BC/CAN_BC_Port.Hardy.711090_CWEC/CAN_BC_Port.Hardy.711090_CWEC.epw" ,
    "PRINCERUPERT" => "BC/CAN_BC_Prince.Rupert.718980_CWEC/CAN_BC_Prince.Rupert.718980_CWEC.epw" ,
    "SMITHERS" => "BC/CAN_BC_Smithers.719500_CWEC/CAN_BC_Smithers.719500_CWEC.epw" ,
    "SUMMERLAND" => "BC/CAN_BC_Summerland.717680_CWEC/CAN_BC_Summerland.717680_CWEC.epw" ,
    "VICTORIA" => "BC/CAN_BC_Victoria.717990_CWEC/CAN_BC_Victoria.717990_CWEC.epw" ,
    "WILLIAMSLAKE" => "" ,
    "COMOX" => "BC/CAN_BC_Comox.718930_CWEC/CAN_BC_Comox.718930_CWEC.epw" ,
    "CRANBROOK" => "BC/CAN_BC_Cranbrook.718800_CWEC/CAN_BC_Cranbrook.718800_CWEC.epw" ,
    "QUESNEL" => "" ,
    "SANDSPIT" =>  "BC/CAN_BC_Sandspit.711010_CWEC/CAN_BC_Sandspit.711010_CWEC.epw",
    "TERRACE" =>  "",
    "TOFINO" =>  "",
    "WHISTLER" =>  "",
    "FORTMCMURRAY" => "AB/CAN_AB_Fort.McMurray.719320_CWEC/CAN_AB_Fort.McMurray.719320_CWEC.epw" ,
    "LETHBRIDGE" => "AB/CAN_AB_Lethbridge.712430_CWEC/CAN_AB_Lethbridge.712430_CWEC.epw" ,
    "ROCKYMOUNTAINHOUSE" =>  "",
    "SUFFIELD" =>  "",
    "COLDLAKE" =>  "",
    "CORONATION" =>  "",
    "GRANDEPRAIRIE" =>  "AB/CAN_AB_Grande.Prairie.719400_CWEC/CAN_AB_Grande.Prairie.719400_CWEC.epw",
    "MEDICINEHAT" =>  "AB/CAN_AB_Medicine.Hat.718720_CWEC/CAN_AB_Medicine.Hat.718720_CWEC.epw",
    "PEACERIVER" =>  "",
    "REDDEER" =>  "",
    "ESTEVAN" =>  "SK/CAN_SK_Estevan.718620_CWEC/CAN_SK_Estevan.718620_CWEC.epw",
    "PRINCEALBERT" => "" ,
    "SASKATOON" =>  "SK/CAN_SK_Saskatoon.718660_CWEC/CAN_SK_Saskatoon.718660_CWEC.epw",
    "SWIFTCURRENT" => "SK/CAN_SK_Swift.Current.718700_CWEC/CAN_SK_Swift.Current.718700_CWEC.epw" ,
    "URANIUMCITY" =>  "",
    "BROADVIEW" =>  "",
    "MOOSEJAW" =>  "",
    "NORTHBATTLEFORD" =>  "SK/CAN_SK_North.Battleford.718760_CWEC/CAN_SK_North.Battleford.718760_CWEC.epw",
    "YORKTON" =>  "",
    "BRANDON" =>  "MB/CAN_MB_Brandon.711400_CWEC/CAN_MB_Brandon.711400_CWEC.epw",
    "CHURCHILL" =>  "MB/CAN_MB_Churchill.719130_CWEC/CAN_MB_Churchill.719130_CWEC.epw",
    "THEPAS" =>  "MB/CAN_MB_The.Pas.718670_CWEC/CAN_MB_The.Pas.718670_CWEC.epw",
    "THOMPSON" =>  "",
    "DAUPHIN" =>  "",
    "PORTAGELAPRAIRIE" =>  "",
    "BIGTROUTLAKE" =>  "",
    "KINGSTON" =>  "ON/CAN_ON_Kingston.716200_CWEC/CAN_ON_Kingston.716200_CWEC.epw",
    "LONDON" =>  "ON/CAN_ON_London.716230_CWEC/CAN_ON_London.716230_CWEC.epw",
    "MUSKOKA" =>  "ON/CAN_ON_Muskoka.716300_CWEC/CAN_ON_Muskoka.716300_CWEC.epw",
    "NORTHBAY" =>  "ON/CAN_ON_North.Bay.717310_CWEC/CAN_ON_North.Bay.717310_CWEC.epw",
    "SAULTSTEMARIE" =>  "ON/CAN_ON_Sault.Ste.Marie.712600_CWEC/CAN_ON_Sault.Ste.Marie.712600_CWEC.epw",
    "SIMCOE" =>  "ON/CAN_ON_Simcoe.715270_CWEC/CAN_ON_Simcoe.715270_CWEC.epw",
    "SUDBURY" =>  "",
    "THUNDERBAY" =>  "ON/CAN_ON_Thunder.Bay.717490_CWEC/CAN_ON_Thunder.Bay.717490_CWEC.epw",
    "TIMMINS" =>  "ON/CAN_ON_Timmins.717390_CWEC/CAN_ON_Timmins.717390_CWEC.epw",
    "WINDSOR" =>  "ON/CAN_ON_Windsor.715380_CWEC/CAN_ON_Windsor.715380_CWEC.epw",
    "GOREBAY" =>  "",
    "KAPUSKASING" =>  "",
    "KENORA" =>  "",
    "SIOUXLOOKOUT" =>  "",
    "TORONTOMETRESSTN" =>  "ON/CAN_ON_Toronto.716240_CWEC/CAN_ON_Toronto.716240_CWEC.epw",
    "TRENTON" =>  "ON/CAN_ON_Trenton.716210_CWEC/CAN_ON_Trenton.716210_CWEC.epw",
    "WIARTON" =>  "",
    "BAGOTVILLE" =>  "PQ/CAN_PQ_Bagotville.717270_CWEC/CAN_PQ_Bagotville.717270_CWEC.epw",
    "KUUJJUAQ" =>  "PQ/CAN_PQ_Kuujuaq.719060_CWEC/CAN_PQ_Kuujuaq.719060_CWEC.epw",
    "KUUJJUARAPIK" =>  "PQ/CAN_PQ_Kuujjuarapik.719050_CWEC/CAN_PQ_Kuujjuarapik.719050_CWEC.epw",
    "SCHEFFERVILLE" =>  "PQ/CAN_PQ_Schefferville.718280_CWEC/CAN_PQ_Schefferville.718280_CWEC.epw",
    "SEPTILES" =>  "PQ/CAN_PQ_Sept-Iles.718110_CWEC/CAN_PQ_Sept-Iles.718110_CWEC.epw",
    "SHERBROOKE" =>  "PQ/CAN_PQ_Sherbrooke.716100_CWEC/CAN_PQ_Sherbrooke.716100_CWEC.epw",
    "VALDOR" =>  "PQ/CAN_PQ_Val.d.Or.717250_CWEC/CAN_PQ_Val.d.Or.717250_CWEC.epw",
    "BAIECOMEAU" =>  "PQ/CAN_PQ_Baie.Comeau.711870_CWEC/CAN_PQ_Baie.Comeau.711870_CWEC.epw",
    "LAGRANDERIVIERE" =>  "PQ/CAN_PQ_La.Grande.Riviere.718270_CWEC/CAN_PQ_La.Grande.Riviere.718270_CWEC.epw",
    "MONTJOLI" =>  "PQ/CAN_PQ_Mont.Joli.717180_CWEC/CAN_PQ_Mont.Joli.717180_CWEC.epw",
    "MONTREALMIRABEL" =>   "PQ/CAN_PQ_Montreal.Mirabel.716278_CWEC/CAN_PQ_Montreal.Mirabel.716278_CWEC.epw" ,
    "STHUBERT" =>     "PQ/CAN_PQ_St.Hubert.713710_CWEC/CAN_PQ_St.Hubert.713710_CWEC.epw",
    "STEAGATHEDESMONTS" =>  "PQ/CAN_PQ_Ste.Agathe.des.Monts.717200_CWEC/CAN_PQ_Ste.Agathe.des.Monts.717200_CWEC.epw",
    "CHATHAM" =>  "",
    "MONCTON" =>  "",
    "SAINTJOHN" => "NB/CAN_NB_Saint.John.716090_CWEC/CAN_NB_Saint.John.716090_CWEC.epw" ,
    "CHARLO" =>  "",
    "GREENWOOD" => "NS/CAN_NS_Greenwood.713970_CWEC/CAN_NS_Greenwood.713970_CWEC.epw" ,
    "SYDNEY" => "NS/CAN_NS_Sydney.717070_CWEC/CAN_NS_Sydney.717070_CWEC.epw" ,
    "TRURO" => "NS/CAN_NS_Truro.713980_CWEC/CAN_NS_Truro.713980_CWEC.epw" ,
    "YARMOUTH" =>  "",
    "CHARLOTTETOWN" =>   "PE/CAN_PE_Charlottetown.717060_CWEC/CAN_PE_Charlottetown.717060_CWEC.epw"  ,
    "SUMMERSIDE" =>  "",
    "BONAVISTA" =>  "",
    "GANDER" =>  "NF/CAN_NF_Gander.718030_CWEC/CAN_NF_Gander.718030_CWEC.epw",
    "GOOSEBAY" =>  "",
    "SAINTJOHNS" =>  "NF/CAN_NF_St.Johns.718010_CWEC/CAN_NF_St.Johns.718010_CWEC.epw",
    "STEPHENVILLE" =>  "NF/CAN_NF_Stephenville.718150_CWEC/CAN_NF_Stephenville.718150_CWEC.epw",
    "CARTWRIGHT" =>  "",
    "DANIELSHARBOUR" =>  "",
    "DEERLAKE" =>  "",
    "WABUSHLAKE" =>  "",
    "DAWSONCITY" =>  "",
    "FORTSMITH" =>  "",
    "NORMANWELLS" =>  "",
    "BAKERLAKE" =>  "",
    "IQALUIT" =>  "",
    "RESOLUTE" =>  "NU/CAN_NU_Resolute.719240_CWEC/CAN_NU_Resolute.719240_CWEC.epw",
    "CORALHARBOUR" =>  "",
    "HALLBEACH" =>  ""
}
                                      
MonthArrListAbbr = Set.new ["jan",
                            "feb",
                            "mar",
                            "apr",
                            "may",
                            "jun",
                            "jul",
                            "aug",
                            "sep",
                            "oct",
                            "nov",
                            "dec"]


MonthArrList     = Set.new ["january",
                            "february",
                            "march",
                            "april",
                            "may",
                            "june",
                            "july",
                            "august",
                            "september",
                            "october",
                            "november",
                            "december"]









$gErrors = Array.new
$gWarnings = Array.new
$gInfoMsgs = Array.new
$gStatus = Hash.new

$scriptLocation = ""

$gHelp = false

$lDebug = false

$localDebug = Hash.new
$lastDbgMsg = "\n"

$gTest_params = Hash.new
$gTest_params["logfile"] = false
$termWidth = nil
$caller_stack

$formatter = REXML::Formatters::Pretty.new(2)
$formatter.compact = true # This is the magic line that does what you need!

$ruleSetSpecs = Hash.new

$gChoicesChangedbyProgram = false

$foundationConfiguration = ""

CostingAuditReportName = 'HTAP-costing-audit-report.txt'
ConfigDataFile = "htap.config"
$gConfigData = Hash.new
$newLine = true
$logBufferCount = 0

$branch_name = ""
$revision_number = ""

$gMasterPath = ""


# GLOBAL OPTIONS defintion - to replace local ones 
$gHTAPOptionsFile   = nil 
$gHTAPOptionsParsed = false 
$gHTAPOptions       = Hash.new 

# LEEP PARAMETER DATA
$LEEParchetypeData = Array.new
$LEEPrunData       = Array.new 
$LEEPecmData       = Array.new
$LEEPlocData       = Array.new

