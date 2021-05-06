#!../../bin/linux-x86_64/FastCCDApp
< /usr/local/epics/R7.0.1.1/support/areadetector/3-2/ADFastCCD/iocs/FastCCDIOC/iocBoot/iocFastCCD/envPaths

epicsEnvSet("ADCORE", "$(AREA_DETECTOR)/ADCore")

errlogInit(20000)
#iocLogDisable(0)
#iocLogInit()

epicsEnvSet("EPICS_CA_AUTO_ADDR_LIST" , "NO")
epicsEnvSet("EPICS_CA_ADDR_LIST"      , "131.243.73.184")
epicsEnvSet("EPICS_CAS_BEACON_LIST", "131.243.73.184")
epicsEnvSet("EPICS_CAS_IGNORE_ADDR_LIST", "10.0.5.42 192.168.1.42")
#epicsEnvSet("EPICS_CA_ADDR_LIST"      , "")
epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES", "10000000")

dbLoadDatabase("$(TOP)/dbd/FastCCDApp.dbd")
FastCCDApp_registerRecordDeviceDriver(pdbbase) 

epicsEnvSet("PREFIX", "ES7011:FastCCD:")
epicsEnvSet("PORT",   "FASTCCD")
epicsEnvSet("QSIZE",  "20")
epicsEnvSet("XSIZE",  "2048")
epicsEnvSet("YSIZE",  "2048")
epicsEnvSet("NCHANS", "2048")
epicsEnvSet("CBUFFS", "500")
epicsEnvSet("EPICS_DB_INCLUDE_PATH", "$(ADCORE)/db")

# FastCCDConfig(const char *portName, int maxBuffers, size_t maxMemory, 
#               int priority, int stackSize, int packetBuffer, int imageBuffer,
#				const char *baseIP, const char *fabricIP, const char *fabricMAC))

FastCCDConfig("$(PORT)", 0, 0, 0, 100000, 2000, 200, "192.168.1.207", "10.0.5.207", "")
FastCCDDebug(1, 1)

# Load Records

dbLoadRecords("$(ADFASTCCD)/db/FastCCD.template",   "P=$(PREFIX),R=cam1:,PORT=$(PORT),ADDR=0,TIMEOUT=1")

# Setup FastCCD Processing Plugin (GAIN)
NDFastCCDConfigure("FastCCDProc1", $(QSIZE), 0, "$(PORT)", 0, 0)
dbLoadRecords("$(ADFASTCCD)/db/NDFastCCD.template", "P=$(PREFIX),R=FastCCD1:,PORT=FastCCDProc1,NDARRAY_PORT=$(PORT),ADDR=0,TIMEOUT=1")

# Create a standard arrays plugin
NDStdArraysConfigure("Image1", $(QSIZE), 0, "FastCCDProc2", 0, 0)
dbLoadRecords("NDStdArrays.template", "P=$(PREFIX),R=image1:,PORT=Image1,NDARRAY_PORT=FastCCDProc1,ADDR=0,TIMEOUT=1,TYPE=Float32,FTVL=FLOAT,NELEMENTS=2361600")

# Load all other plugins using commonPlugins.cmd
< $(ADCORE)/iocBoot/commonPlugins.cmd

set_requestfile_path("$(ADFASTCCD)/FastCCDApp/Db")
set_requestfile_path("$(ADFASTCCD)/FastCCDPlugin/Db")
set_requestfile_path("$(ADCORE)","ADApp/Db")

iocInit()

# save things every thirty seconds
create_monitor_set("auto_settings.req", 30,"P=$(PREFIX),D=cam1:")
dbl > $(TOP)/records.dbl
dbl > ioc.dbl

dbpf $(PREFIX)cam1:NDAttributesFile FastCCDDetectorAttributes.xml
dbpf $(PREFIX)Stats1:NDAttributesFile StatsAttributes.xml
dbpf $(PREFIX)ROIStat1:NDAttributesFile ROIStatAttributes.xml


