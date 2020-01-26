clear all

%rough estimation for the time of a 360 deg rotation: 0.5 s

niDevName = 'Dev1';
niPortLine1 = 'port0/line0';
% niPortLine2 = 'port0/line3';

rewardStepMotorCtl1 = daq.createSession('ni');
rewardStepMotorCtl1.addDigitalChannel(niDevName,niPortLine1,'OutputOnly');
% 
% rewardStepMotorCtl2 = daq.createSession('ni');
% rewardStepMotorCtl2.addDigitalChannel(niDevName,niPortLine2,'OutputOnly');

rewardVol = 4; 
deliverReward(rewardVol,5,rewardStepMotorCtl1);
% deliverReward(rewardVol,5,rewardStepMotorCtl2);
% 
% for i=1:20
%     pause(2)
%     deliverReward(5,5,rewardStepMotorCtl1);
% end
% 
% 
% 
% 
% 
%                 
% 
% 
%   % for i=1:300
% % pause(0.5);
% [step,exactvalue] = deliverReward(3,5,rewardStepMotorCtl1);
% 
% 
% [step,exactvalue] = deliverReward(3,5,rewardStepMotorCtl2);

% end

rewardStepMotorCtl1.release();