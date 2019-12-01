function [lickFlag relLickTime] = detectLickOnRightOrLeft (lickSenseDuration, niCardSession)


%This function detects a lick on the right or left spout by monitoring two spouts through the output of the Janelia lick
%sensor board that is connected to a "Static"** ni-card digital inputs. 
%INPUTS. lickSenseDuration: period during which the lick sensor is checked.
%niCardSession: the NI-card session that is created bofore the function
%call and indicate the NI-card channel that the sensor is connected to.

%OUTPUTS. lickFlag: 1 if the first lick is detected on the right spout during lickSenseDuration, 2 if the first lick goes to the left, and 0 if no lick is detected  

%**Static digital input chnnel means that the channel can't be monitored continously
%through the background and forground commands and should be monitored with
%SingleScan commands.


startFlag = 0;
lickFlag = 0;

while (1)

    digitalInput = inputSingleScan(niCardSession);
    inputTime = GetSecs();
    port1 = digitalInput(1);
    port2 = digitalInput(2);
    

    if ~startFlag
        startTime = inputTime;
        startFlag = 1;
    end

    if (inputTime>(startTime+lickSenseDuration))
        break;
    end

    if port1 | port2

        if port1
            lickFlag = 1;
        else
            lickFlag = 2;
        end
        relLickTime = inputTime - startTime;
        return


    end


end
relLickTime = inputTime - startTime;

end



