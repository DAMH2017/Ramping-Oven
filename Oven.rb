include UNI

#########################################################################
# User written helper global variables.
#########################################################################
# Timer period [ms]
$timerPeriod = 400


#########################################################################
# User written helper function.
#
# Returns true if the given character is a number character.
#########################################################################
def isNumber(ch)
	if (ch >= ?0.ord && ch <= ?9.ord)
		return true
	end
	return false
end



#########################################################################
# Sub-device class expected by framework.
#
# Sub-device represents functional part of the chromatography hardware.
# Thermostat implementation.
#########################################################################
class Thermostat < ThermostatSubDeviceWrapper
	# Constructor. Call base and do nothing. Make your initialization in the Init function instead.
	def initialize
		super
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# Initialize thermostat sub-device. 
	# Set sub-device name, specify method items, specify monitor items, ...
	# Returns nothing.
	#########################################################################	
	def Init
	end
	
end # class Thermostat



#########################################################################
# Device class expected by framework.
#
# Basic class for access to the chromatography hardware.
# Maintains a set of sub-devices.
# Device represents whole box while sub-device represents particular 
# functional part of chromatography hardware.
# The class name has to be set to "Device" because the device instance
# is created from the C++ code and the "Device" name is expected.
#########################################################################
class Device < DeviceWrapper
	# Constructor. Call base and do nothing. Make your initialization in the Init function instead.
	def initialize
		super
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# Initialize configuration data object of the device and nothing else
	# (set device name, add all sub-devices, setup configuration, set pipe
	# configurations for communication, #  ...).
	# Returns nothing.
	#########################################################################	
	def InitConfiguration
     	# Setup configuration.
    	Configuration().AddString("ThermName", "Oven name", "Ramping oven", "VerifyThermostatName")
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# Initialize device. Configuration object is already initialized and filled with previously stored values.
	# (set device name, add all sub-devices, setup configuration, set pipe
	# configurations for communication, #  ...).
	# Returns nothing.
	#########################################################################	
	def Init
		@timeEq=0.0 #this variable will record the current time once the (current) temperature reach the (set) temperature within accepted tolerance
		@flagEq=true #this flag will switch to false once @timeEq record the current time to make this action once
		@timeOfHold=0.0 #this variable will be equal to the current acquisition time (GetAcquisitionTime)+the hold time in the gradient table once the (current) temperature reachs the (set) temperaturefrom gradient table within tolerance
		@rateOfHeating=0.0 #will be equal to the rate in the gradient table,0 on stop acquisition
		@flagOfHoldTime=false #a flag to switch on or off after @timeOfHold variable record the acquisition time + hold time
		
		@aryTemp=nil
		@aryTime=nil
		@aryRate=nil
		
		
		Method().AddTable("TemperatureGradient", "Temperature Gradient")
	    Method().AddTableColumnDouble("TemperatureGradient", "Temp", "Temperature", 1, EMeaningTemperature, "")
	    Method().AddTableColumnDouble("TemperatureGradient", "Time", "Hold Time[min]", 1, EMeaningUnknown, "")
	    Method().AddTableColumnDouble("TemperatureGradient", "Rate", "Rate C/min", 1, EMeaningUnknown, "")
		
		Method().AddDouble("TempTolerance", "Allowed temperature tolerance",0.5, 1, EMeaningTemperatureDifference, "",false)
		Method().AddDouble("EqTime", "Equilibration time[min]",0.2, 1, EMeaningUnknown, "",false)
		
		Monitor().AddDouble("SetTemp", "Set temperature",ConvertTemperature(30.0,ETU_C,ETU_K),1, EMeaningTemperature, "", true)
		Monitor().AddDouble("CurrTemp", "Current temperature",ConvertTemperature(30.0,ETU_C,ETU_K),1, EMeaningTemperature, "", true)
		Monitor().AddDouble("TotalTime", "Total time[min]",0.0, 1, EMeaningUnknown, "",true)
		
		AuxSignal().AddSignal("Temperature", "Temperature", EMeaningTemperature)
		
		SetName("My oven")
		@m_Thermostat=Thermostat.new
		AddSubDevice(@m_Thermostat)
		@m_Thermostat.SetName(Configuration().GetString("ThermName"))
		
		SetHideLoadMethod(true)
		SetTimerPeriod($timerPeriod)
	end
 	
	#########################################################################
	# Method expected by framework.
	#
	# Sets communication parameters.
	# Returns nothing.
	#########################################################################	
	def InitCommunication()
		Communication().SetPipeConfigCount(1)
		Communication().GetPipeConfig(0).SetType(EPT_SERIAL)
		Communication().GetPipeConfig(0).SetBaudRate(2400)
		Communication().GetPipeConfig(0).SetParity(NOPARITY)
		Communication().GetPipeConfig(0).SetDataBits(DATABITS_8)
		Communication().GetPipeConfig(0).SetStopBits(ONESTOPBIT)
	end
	
	#########################################################################
	# Method expected by framework
	#
	# Here you should check leading and ending sequence of characters, 
	# check sum, etc. If any error occurred, use ReportError function.
	#	dataArraySent - sent buffer (can be nil, so it has to be checked 
	#						before use if it isn't nil), array of bytes 
	#						(values are in the range <0, 255>).
	#	dataArrayReceived - received buffer, array of bytes 
	#						(values are in the range <0, 255>).
	# Returns true if frame is found otherwise false.		
	#########################################################################	
	def FindFrame(dataArraySent, dataArrayReceived)
		return true
	end
	
	#########################################################################
	# Method expected by framework
	#
	# Return true if received frame (dataArrayReceived) is answer to command
	# sent previously in dataArraySent.
	#	dataArraySent - sent buffer, array of bytes 
	#						(values are in the range <0, 255>).
	#	dataArrayReceived - received buffer, array of bytes 
	#						(values are in the range <0, 255>).
	# Return true if in the received buffer is answer to the command 
	#   from the sent buffer. 
	# Found frames, for which IsItAnswer returns false are processed 
	#  in ParseReceivedFrame
	#########################################################################		
	def IsItAnswer(dataArraySent, dataArrayReceived)
		return true
	end
	
	#########################################################################
	# Method expected by framework
	#
	# Returns serial number string from HW (to comply with CFR21) when 
	# succeessful otherwise false or nil. If not supported return false or nil.
	#########################################################################	
	def CmdGetSN 
		#Send a command to get the serial number
		return false
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# gets called when instrument opens
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdOpenInstrument
		# Nothing to send.
		
		return true
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# gets called when sequence starts
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdStartSequence
		# Nothing to send.
		return true
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# gets called when sequence resumes
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdResumeSequence
		# Nothing to send.
		return true
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# gets called when run starts
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdStartRun
		# Nothing to send.
		return true
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# gets called when injection performed
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdPerformInjection
		# Nothing to send.
		return true
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# gets called when injection bypassed
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdByPassInjection
		# Nothing to send.
		return true
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# Starts method in HW.
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdStartAcquisition
		@aryTemp=Array.new(Method().GetTableColumnValues("TemperatureGradient","Temp"))
		@aryTime=Array.new(Method().GetTableColumnValues("TemperatureGradient","Time"))
		@aryRate=Array.new(Method().GetTableColumnValues("TemperatureGradient","Rate"))
		@timeOfHold=GetAcquisitionTime()+@aryTime[0]
		Trace("Start acquisition, @timeOfHold="+@timeOfHold.to_s)
		Monitor().SetRunning(true)
		Monitor().Synchronize()
		return true
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# gets called when acquisition restarts
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdRestartAcquisition
		# Nothing to send.
		return true
	end	

	#########################################################################
	# Method expected by framework.
	#
	# Stops running method in hardware. 
	# Returns true when successful otherwise false.	
	#########################################################################
	def CmdStopAcquisition
		@aryTemp=nil
		@aryTime=nil
		@aryRate=nil
		@timeOfHold=0.0
		@rateOfHeating=0.0
		Monitor().SetRunning(false)
		SetTemperatureToHW(Method().GetTableColumnValues("TemperatureGradient","Temp")[0])
		Monitor().Synchronize()
		Trace("Acquisition Stopped")
		return true
	end	
	
	#########################################################################
	# Method expected by framework.
	#
	# Aborts running method or current operation. Sets initial state.
	# Returns true when successful otherwise false.	
	#########################################################################
	def CmdAbortRunError
		return CmdStopAcquisition()
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# Aborts running method or current operation (request from user). Sets initial state.
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdAbortRunUser
		return CmdStopAcquisition()
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# Aborts running method or current operation (shutdown). Sets initial state.
	# Returns true when successful otherwise false.	
	#########################################################################
	def CmdShutDown
		CmdAbortRunError()
		return true
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# gets called when run stops
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdStopRun
		# Nothing to send.
		return true
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# gets called when sequence stops
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdStopSequence
		# Nothing to send.
		return true
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# gets called when closing instrument
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdCloseInstrument
		# Nothing to send.
		return true
	end	

	#########################################################################
	# Method expected by framework.
	#
	# Tests whether hardware device is present on the other end of the communication line.
	# Send some simple command with fast response and check, whether it has made it
	# through pipe and back successfully.
	# Returns true when successful otherwise false.
	#########################################################################
	def CmdTestConnect
		#if(GetCurrentTempFromHW==false)
		#	return false
		#end
		#May also use CmdGetSN method
		return true
	end
	
		
	#########################################################################
	# Method expected by framework.
	#
	# Send method to hardware.
	# Returns true when successful otherwise false.	
	#########################################################################
	def CmdSendMethod()
		Monitor().SetDouble("TotalTime",CalculateTotalTime(Method().GetTableColumnValues("TemperatureGradient","Temp"),
			Method().GetTableColumnValues("TemperatureGradient","Time"),
			Method().GetTableColumnValues("TemperatureGradient","Rate")))
		SetTemperatureToHW(Method().GetTableColumnValues("TemperatureGradient","Temp")[0])
		Monitor().SetReady(false)
		Monitor().Synchronize()
		return true
	
	end
	
	#########################################################################
	# Method expected by framework.
	#
	# Loads method from hardware.
	# Returns true when successful otherwise false.	
	#########################################################################
	def CmdLoadMethod(method)
		return true		
	end
		
	#########################################################################
	# Method expected by framework.
	#
	# Duration of thermostat method.
	# Returns complete (from start of acquisition) length (in minutes) 
	# 	of the current method in sub-device (can use GetRunLengthTime()).
	# Returns METHOD_FINISHED when hardware instrument is not to be waited for or 
	# 	method is not implemented.
	# Returns METHOD_IN_PROCESS when hardware instrument currently processes 
	# 	the method and sub-device cannot tell how long it will take.
	#########################################################################
	def GetMethodLength
		return METHOD_FINISHED
	end	
	
	#########################################################################
	# Method expected by framework.
	#
	# Periodically called function which should update state 
	# of the sub-device and monitor.
	# Returns true when successful otherwise false.	
	#########################################################################
	def CmdTimer
		setTemp=Monitor().GetDouble("SetTemp")
		currTemp=Monitor().GetDouble("CurrTemp") #This line will be replaced with currTemp=GetTemperatureFromHW() in case we use real oven
		if(setTemp-currTemp.abs>Method().GetDouble("TempTolerance"))
			if(Monitor().IsRunning()==false) 
				currTemp>setTemp ? currTemp-=rand(0.2..0.5) : currTemp+=rand(0.2..0.5)
			else
				temp_per_min=$timerPeriod/((60/@rateOfHeating)*1000)
				currTemp>setTemp ? currTemp-=temp_per_min : currTemp+=temp_per_min
			end
			Monitor().SetDouble("CurrTemp",currTemp)
			Monitor().SetReady(false)
			@flagEq=true
		else
			if(@flagEq==true)
				@timeEq=Process.clock_gettime(Process::CLOCK_MONOTONIC)
				@flagEq=false
			end
			timeNow=Process.clock_gettime(Process::CLOCK_MONOTONIC)
			if(timeNow-@timeEq)>=Method().GetDouble("EqTime")*60
				Monitor().SetReady(true)
			end
		end
		
		if(Monitor().IsRunning())
			SetTemperatureFromGradientTable()
		end
		AuxSignal().WriteSignal("Temperature",currTemp)
		Monitor().Synchronize()
		return true
	end
	
	
	#########################################################################
	# Method expected by framework
	#
	# gets called when user presses autodetect button in configuration dialog box
	# return true or  false
	#########################################################################
	def CmdAutoDetect
		return CmdTestConnect()
	end
	
	#########################################################################
	# Method expected by framework
	#
	# Processes unrequested data sent by hardware. 
	#	dataArrayReceived - received buffer, array of bytes 
	#						(values are in the range <0, 255>).
	# Returns true if frame was processed otherwise false.
	# The frame found by FindFrame can be processed here if 
	#  IsItAnswer returns false for it.
	#########################################################################
	def ParseReceivedFrame(dataArrayReceived)
		# Passes received frame to appropriate sub-device's ParseReceivedFrame function.
	end
	
		#########################################################################
	# Required by Framework
	#
	# Validates whole method. Use method parameter and NOT object returned by Method(). 
	# There is no need to validate again attributes validated somewhere else.
	# Validation function returns true when validation is successful otherwise
	# it returns message which will be shown in the Message box.	
	#########################################################################
	def CheckMethod(situation,method)
		return true
	end
	
	#########################################################################
	# Required by Framework
	#
	# Gets called when chromatogram is acquired, chromatogram might not exist at the time.
	#########################################################################
	def NotifyChromatogramFileName(chromatogramFileName)
	end
	
	def SetTemperatureFromGradientTable
		if(@aryTemp.length()<1)
			return false
		end

		if (Monitor().GetDouble("CurrTemp")-Monitor().GetDouble("SetTemp")).abs<=Method().GetDouble("TempTolerance") && @flagOfHoldTime==false
			@timeOfHold=GetAcquisitionTime()+@aryTime[0]
			Trace("Temperature reached, next temperature will be at "+@timeOfHold.to_s)
			@flagOfHoldTime=true
		end
		if GetAcquisitionTime()>=@timeOfHold && @flagOfHoldTime==true
			@rateOfHeating=@aryRate[0]
			@aryTemp.delete_at(0)
			@aryTime.delete_at(0)
			@aryRate.delete_at(0)
			if(@aryTemp.length()>0)
				SetTemperatureToHW(@aryTemp[0])
				Trace("Time exceeded, next temperature to reach: "+@aryTemp[0].to_s)
				@flagOfHoldTime=false
			else
				CmdStopAcquisition()
			end
		end
		return true
	end
	
	#Set temperature to HW
	def SetTemperatureToHW(temp)
		#send command wrapper to set the temperature in HW to temp value
		'''
		cmd=CommandWrapper.new(self)
		cmd.AppendANSIString("ST:"+temp.to_s)
		
		if(cmd.SendCommand($timeOut)==false)
			ReportError(EsCommunication, "Error in sending command to set temperature")
			return false
		end
		
		if(cmd.ParseANSIString("OK"))
			ReportError(EsCommunication, "Error in receiving response to set temperature")
			return false
		end
		'''
		Monitor().SetDouble("SetTemp",temp)
	end
	
	#Get current temperature from HW,return double or false
	def GetTemperatureFromHW
	'''
		cmd=CommandWrapper.new(self)
		cmd.AppendANSIString("GT")
		if(cmd.SendCommand($timeOut)==false)
			ReportError(EsCommunication, "Error in sending command to get current temperature")
			return false
		end
		
		if(cmd.ParseANSIString("OK,")==false)
			ReportError(EsCommunication, "Error in receiving response of current temperature")
			return false
		end
		
		if((currTemp=cmd.ParseANSIDouble())==false)
			ReportError(EsCommunication,"Error in receiving required temperature")
			return false
		end
'''
		currTemp=30.0
		Monitor().SetDouble("CurrTemp",currTemp)
		return currTemp
	end
	
	
	#calulate total time, return double, or 0.0
	def CalculateTotalTime(aryTemp,aryTime,aryRate)
		if(aryTime.length()==0 || aryTemp.length()==0 || aryRate.length()==0)
			return 0.0
		end
		processTemp=0.0
		for i in 0...aryTemp.length()-1
			processTemp+=((aryTemp[i+1].to_f-aryTemp[i].to_f).abs/aryRate[i].to_f)
		end
		return ("%.2f" % (processTemp+aryTime.sum)).to_f
	end
		
	def VerifyTemperature(uiitemcollection,value)
		if (value < ConvertTemperature(-5.0,ETU_C,ETU_K) || value > ConvertTemperature(250.0,ETU_C,ETU_K)) #some ovens use crygenic features
			tempMin = ConvertTemperature(-5.0, ETU_C, GetTemperatureUIUnits())
			tempMax = ConvertTemperature(250.0, ETU_C, GetTemperatureUIUnits())
			return "Value must be between "+tempMin.to_s+" and "+tempMax.to_s
		end
		return true
	end
end

def VerifyThermostatName(uiitemcollection,value)
	if(value.length>32)
		return "Name you entered is too long"
	end
end

'''
#Oven ramping temperature
aryTemp=[40,175,200,200]
aryTime=[3,8,10,50]
aryRate=[5,3,8,0]

totalTime=0.0

processTemp=0.0
for i in 0...aryTemp.length()-1
    processTemp+=((aryTemp[i+1].to_f-aryTemp[i].to_f).abs/aryRate[i].to_f)
end
puts "%.2f" % (processTemp+aryTime.sum)
'''