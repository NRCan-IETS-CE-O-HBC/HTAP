


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
            "VALDOR" => 6180 ,
            "BAIECOMEAU" => 6020 ,
            "LAGRANDERIVIERE" => 8100 ,
            "MONTJOLI" => 5370 ,
            "MONTREALMIRABEL" => 4500   ,
            "STHUBERT" => 4490    ,
            "STEAGATHEDESMONTS" => 5390 ,
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
             "NORTHWEST TERRITORY",
             "NUNAVUT",
             "OTHER" ]




$LegacyOptionsToIgnore = Set.new [
  "Opt-RoofPitch",
  "Opt-StandoffPV",
  "Opt-DHWLoadScale",
  "Opt-HRVduct",
  "Opt-FloorAboveCrawl",
  "Opt-FloorHeader"
]

$DoNotValidateOptions = Set.new [  "upgrade-package-list" ]




CostingSupport = Set.new [ "Opt-Ceilings",
                           "Opt-AtticCeilings",
                           "Opt-ACH",
                           "Opt-CasementWindows",
                           "Opt-DWHRSystem",
                           "Opt-GenericWall_1Layer_definitions",
                           "Opt-HVACSystem",
                           "Opt-HRVonly",
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
