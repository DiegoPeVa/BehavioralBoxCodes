clear all
close all 

niDevName = 'Dev1';

samplingFreq = 5e3;



cueSoundDur = 0.5;
% cueSoundDurFrames = round(cueSoundDur/ifi);
% samplingFreq = 100e3;
cueSoundFreq = 3400;
cueSoundAmp = 1;
      
tCue = 0:1/samplingFreq:cueSoundDur;
cueSoundToNICard = cueSoundAmp*sin(2*pi*cueSoundFreq*tCue);

% niDevName = 'Dev2';
soundOutputSession = daq.createSession('ni');  

addAnalogOutputChannel(soundOutputSession,niDevName,0,'Voltage');
soundOutputSession.Rate = samplingFreq;

queueOutputData(soundOutputSession,cueSoundToNICard');
        
soundOutputSession.startBackground;

wait(soundOutputSession);