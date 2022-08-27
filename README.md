# Ramping Oven for Clarity CDS

A simple ruby script for Clarity CDS for virtual ramping oven for GC

## Description
A ruby script for a virtual ramping oven that runs with Clarity CDS (without hardware commands), here you can gradient temperature using gradient table

## Getting Started

### Download the script

### Download Clarity CDS (Demo Version)

* Go to DataApex link to register [here](https://www.dataapex.com/product/clarity-demo?language_content_entity=en)

### Installing Clarity CDS

* No further action needed while installing, keep the default settings

### Installing the script

* Open the Clarity demo version
* Click on (Configuration) icon, then press (OK) on pop-up window
![1](https://user-images.githubusercontent.com/25401184/178685655-fe603d0f-bad5-4717-a142-2a81399523aa.jpg)

* Click (Add) button to add the script), from the opened window, choose (UNI Ruby) under (Auxiliary)
![2](https://user-images.githubusercontent.com/25401184/178685789-5d7ce540-6b5f-4cb6-9cb4-81fd6c22fcff.jpg)

* Load the script, change the thermostat name if you want, then press (OK)
![3](https://user-images.githubusercontent.com/25401184/187024944-d22cd067-4736-46ce-adce-ae3313ac2096.png)

* Load a script for a detector (ex: DetectorExample.rb) found in Clarity_Demo/Bin/UTILS/Uni_Drivers/EXAMPLES
* Choose each module, press (Add selected sub-device) to add them to the device used (GC, HPLC,.....)


* Press (OK) to close

### Using the virtual oven
* Open (My GC+AS), press (OK) to pop-up window
* Open (Method setup) button, go to (Thermostat) tab, set the (Allowed temperature tolerance) to a suitable value (0.5), this value represents the accepted difference between (Set) temperature and (Current) temperature, set also the (Equilibration time) in minutes (this indicates the time to wait after temperature tolerance is accepted then give the device the ready state)
* Go to temperature gradient tab, write the temperature (ranges from -5 to 250 in case cryogenic system is used but any value can be written in this example), hold time in minutes (it indicates the time the temperature will be fixed before going to next temperature in the next table row), and finally the (Rate) of heating/cooling when going to the next row after hold time finishs
* Go to (Advanced) tab, check on (Store) for (Temperature ramping oven) in the (Auxiliary Signal) table
* Press (Save) to send method with current data, and then press (OK)
* Click on (Device Monitor) button, notice that (Set temperature) is updated with the value of first row of gradient table, (Current temperature) is updating by increasing/decreasing till reachs the (Allowed temperature tolerance) indicated before
* Notice also (Total time) is updated by taking the data from (Gradient table)
* Now when the state is ready, press (Run), then click on (Data Acquisition) button to open the signal window, see the detector and oven signals (Note: Sometimes the oven doesn't show up, click on (Common for all signals) to refresh the window)

## Version History

* 0.1
    * Initial Release
