clear all
close all 

niDevName = 'Dev1';

% Digital input session for monitoring the spout
spoutSession = daq.createSession('ni');

%right spout sensor
sensorCopyPortLine1 = 'port0/line1';
addDigitalChannel(spoutSession,niDevName,sensorCopyPortLine1,'InputOnly');

%Digital Output session for right reward control
rewardStepMotorCtl1 = daq.createSession('ni');
rewardPortLine1 = 'port0/line0';
%1 - output to step motor to control the reward
rewardStepMotorCtl1.addDigitalChannel(niDevName,rewardPortLine1,'OutputOnly');

% %Digital Output session for left reward control
% rewardStepMotorCtl2 = daq.createSession('ni');
% rewardPortLine2 = 'port0/line3';
% %1 - output to step motor to control the reward
% rewardStepMotorCtl2.addDigitalChannel(niDevName,rewardPortLine2,'OutputOnly');
    
% Reward Volume:
earnedRewardVol = 4; %in microL
freeRewardVol = 4;
syringeVol = 5;

deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl1);

afterRewardDelay = 2;
lickSensorCheckTime = 2;

earnedRewardVolTotal = 0;

while(1)
    
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
    if (find(keyCode) == 27)  %Press escape to manually finish the loop
        break;
    end
    
    if (find(keyCode) == 82)  %Press r to manually give a reward and force a go trial
        rewardDeliveryTime = GetSecs;
        deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl1);
        earnedRewardVolTotal = earnedRewardVolTotal + earnedRewardVol;
        while (GetSecs - rewardDeliveryTime) < afterRewardDelay
            ;
        end
    end
    
    
    [lickFlag, relDetectionTime] = detectLickOnRight(lickSensorCheckTime, spoutSession);
    if lickFlag
        rewardDeliveryTime = GetSecs;
        deliverReward(earnedRewardVol,syringeVol,rewardStepMotorCtl1);
        earnedRewardVolTotal = earnedRewardVolTotal + earnedRewardVol;
        while (GetSecs - rewardDeliveryTime) < afterRewardDelay
            ;
        end
    end
end

disp(' ');
disp(['Total Reward: ', num2str(earnedRewardVolTotal)]);
        